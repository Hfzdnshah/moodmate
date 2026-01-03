import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import OpenAI from "openai";

// Initialize Firebase Admin
admin.initializeApp();

// Lazy initialization of OpenAI client
let openaiClient: OpenAI | null = null;

function getOpenAIClient(): OpenAI {
	if (!openaiClient) {
		openaiClient = new OpenAI({
			apiKey: functions.config().openai?.key || process.env.OPENAI_API_KEY,
		});
	}
	return openaiClient;
}

// Emotion categories we'll use
const EMOTIONS = [
	"joy",
	"sadness",
	"anxiety",
	"anger",
	"fear",
	"contentment",
	"excitement",
	"frustration",
	"loneliness",
	"hope",
	"overwhelmed",
	"peaceful",
	"confused",
	"grateful",
	"stressed",
];

/**
 * Analyzes mood entry using OpenAI API
 * Triggered when a new mood entry is created in Firestore
 */
export const analyzeMoodEntry = functions.firestore
	.document("mood_entries/{entryId}")
	.onCreate(async (snap, context) => {
		const entryId = context.params.entryId;
		const entryData = snap.data();

		try {
			functions.logger.info(`Analyzing mood entry: ${entryId}`);

			// Check if entry has text
			if (!entryData.text) {
				throw new Error("Mood entry has no text to analyze");
			}

			// Call OpenAI API for emotion analysis
			const analysis = await analyzeMoodWithOpenAI(entryData.text);

			// Update the mood entry with analysis results
			await admin.firestore().collection("mood_entries").doc(entryId).update({
				emotion: analysis.emotion,
				confidenceScore: analysis.confidenceScore,
				analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
				analysisStatus: "completed",
			});

			functions.logger.info(
				`Successfully analyzed mood entry ${entryId}: ` +
					`${analysis.emotion} (${analysis.confidenceScore})`
			);

			return { success: true, analysis };
		} catch (error) {
			functions.logger.error(`Error analyzing mood entry ${entryId}:`, error);

			// Mark the entry as failed
			try {
				await admin.firestore().collection("mood_entries").doc(entryId).update({
					analysisStatus: "failed",
					analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
				});
			} catch (updateError) {
				functions.logger.error(
					`Failed to update entry status for ${entryId}:`,
					updateError
				);
			}

			// Re-throw to trigger retry mechanism
			throw error;
		}
	});

/**
 * Analyzes mood text using OpenAI API
 */
async function analyzeMoodWithOpenAI(
	text: string
): Promise<{ emotion: string; confidenceScore: number }> {
	try {
		const prompt = `Analyze the following mood journal entry and determine the primary emotion. Choose only ONE emotion from this list: ${EMOTIONS.join(
			", "
		)}.

Journal Entry:
"${text}"

Respond in JSON format with:
{
  "emotion": "the primary emotion from the list",
  "confidence": a number between 0 and 1 indicating confidence,
  "reasoning": "brief explanation of why this emotion was chosen"
}

Be empathetic and consider the overall tone and context.`;

		const openai = getOpenAIClient();
		const response = await openai.chat.completions.create({
			model: "gpt-3.5-turbo",
			messages: [
				{
					role: "system",
					content:
						"You are an empathetic mental health assistant that " +
						"analyzes mood journal entries to identify emotions. " +
						"Always respond in valid JSON format.",
				},
				{
					role: "user",
					content: prompt,
				},
			],
			temperature: 0.3,
			max_tokens: 200,
			response_format: { type: "json_object" },
		});

		const content = response.choices[0].message.content;
		if (!content) {
			throw new Error("No response from OpenAI");
		}

		const result = JSON.parse(content);

		// Validate the emotion is in our list
		const emotion = result.emotion.toLowerCase();
		if (!EMOTIONS.includes(emotion)) {
			functions.logger.warn(
				`OpenAI returned unexpected emotion: ${emotion}, ` +
					'defaulting to "confused"'
			);
			return {
				emotion: "confused",
				confidenceScore: 0.5,
			};
		}

		// Ensure confidence score is between 0 and 1
		const confidenceScore = Math.max(0, Math.min(1, result.confidence || 0.5));

		functions.logger.info(
			`OpenAI analysis: ${emotion} (${confidenceScore}), ` +
				`reasoning: ${result.reasoning}`
		);

		return {
			emotion,
			confidenceScore,
		};
	} catch (error) {
		functions.logger.error("OpenAI API error:", error);
		throw new Error(`Failed to analyze mood with OpenAI: ${error}`);
	}
}

/**
 * Manual retry function for failed analyses
 * Can be called via HTTP to retry analysis for a specific entry
 */
export const retryMoodAnalysis = functions.https.onCall(
	async (data, context) => {
		// Verify the user is authenticated
		if (!context.auth) {
			throw new functions.https.HttpsError(
				"unauthenticated",
				"User must be authenticated"
			);
		}

		const { entryId } = data;

		if (!entryId) {
			throw new functions.https.HttpsError(
				"invalid-argument",
				"Entry ID is required"
			);
		}

		try {
			const entryRef = admin
				.firestore()
				.collection("mood_entries")
				.doc(entryId);
			const entrySnap = await entryRef.get();

			if (!entrySnap.exists) {
				throw new functions.https.HttpsError(
					"not-found",
					"Mood entry not found"
				);
			}

			const entryData = entrySnap.data();

			// Verify the user owns this entry
			if (entryData?.userId !== context.auth.uid) {
				throw new functions.https.HttpsError(
					"permission-denied",
					"You do not have permission to retry this analysis"
				);
			}

			// Check if entry has text
			if (!entryData.text) {
				throw new functions.https.HttpsError(
					"invalid-argument",
					"Mood entry has no text to analyze"
				);
			}

			// Perform analysis
			const analysis = await analyzeMoodWithOpenAI(entryData.text);

			// Update the entry
			await entryRef.update({
				emotion: analysis.emotion,
				confidenceScore: analysis.confidenceScore,
				analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
				analysisStatus: "completed",
			});

			return {
				success: true,
				emotion: analysis.emotion,
				confidenceScore: analysis.confidenceScore,
			};
		} catch (error) {
			functions.logger.error(`Error retrying analysis for ${entryId}:`, error);

			// If it's already an HttpsError, re-throw it
			if (error instanceof functions.https.HttpsError) {
				throw error;
			}

			// Otherwise wrap it
			throw new functions.https.HttpsError(
				"internal",
				`Failed to retry analysis: ${error}`
			);
		}
	}
);
