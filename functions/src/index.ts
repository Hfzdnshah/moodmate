import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Mistral from "@mistralai/mistralai";

// Initialize Firebase Admin
admin.initializeApp();

// Lazy initialization of Mistral client
let mistralClient: Mistral | null = null;

function getMistralClient(): Mistral {
	if (!mistralClient) {
		mistralClient = new Mistral(
			functions.config().mistral?.key || process.env.MISTRAL_API_KEY
		);
	}
	return mistralClient;
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

// Fallback recommendations for each emotion category
const FALLBACK_RECOMMENDATIONS: Record<string, string[]> = {
	joy: [
		"Share your happiness with someone you care about.",
		"Practice gratitude by writing down three things you're thankful for.",
		"Channel this positive energy into a creative activity.",
	],
	sadness: [
		"It's okay to feel sad. Give yourself permission to feel your emotions.",
		"Connect with a friend or loved one for support.",
		"Try gentle physical activity like a walk in nature.",
	],
	anxiety: [
		"Practice deep breathing: inhale for 4, hold for 4, exhale for 4.",
		"Ground yourself by naming 5 things you can see, 4 you can touch, 3 you can hear.",
		"Consider talking to a mental health professional if anxiety persists.",
	],
	anger: [
		"Take a few deep breaths before responding to what's making you angry.",
		"Try physical exercise to release tension in a healthy way.",
		"Write about your feelings to process them constructively.",
	],
	fear: [
		"Remember that it's normal to feel afraid sometimes.",
		"Focus on what you can control in the present moment.",
		"Reach out to someone you trust to share your concerns.",
	],
	contentment: [
		"Savor this peaceful feeling and notice what brings you contentment.",
		"Use this calm energy to reflect on your goals and values.",
		"Practice mindfulness to extend this sense of wellbeing.",
	],
	excitement: [
		"Channel your energy into something productive or creative.",
		"Share your excitement with others who will celebrate with you.",
		"Plan ahead to make the most of whatever you're excited about.",
	],
	frustration: [
		"Step away from the situation temporarily to gain perspective.",
		"Break down what's frustrating you into smaller, manageable parts.",
		"Be patient with yourself - progress takes time.",
	],
	loneliness: [
		"Reach out to someone - even a small connection can help.",
		"Join a community activity or group that interests you.",
		"Remember that feeling lonely is temporary and you're not alone in feeling this way.",
	],
	hope: [
		"Write down what you're hopeful about to reinforce these positive feelings.",
		"Take a small action toward what you're hoping for.",
		"Share your hope with others to inspire them too.",
	],
	overwhelmed: [
		"Prioritize one task at a time instead of trying to do everything at once.",
		"It's okay to say no and set boundaries.",
		"Consider breaking down larger tasks into smaller, achievable steps.",
	],
	peaceful: [
		"Take time to appreciate this moment of peace.",
		"Notice what creates peace for you so you can recreate it later.",
		"Use this calm state for reflection or meditation.",
	],
	confused: [
		"It's okay not to have all the answers right now.",
		"Try writing down your thoughts to clarify what's confusing you.",
		"Talk to someone who might offer a different perspective.",
	],
	grateful: [
		"Keep a gratitude journal to capture what you're thankful for.",
		"Express your appreciation to someone who has helped you.",
		"Reflect on how gratitude contributes to your overall wellbeing.",
	],
	stressed: [
		"Take short breaks throughout your day to reset.",
		"Practice progressive muscle relaxation to release physical tension.",
		"Identify what's causing stress and consider what you can change or accept.",
	],
};

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

			// Generate recommendations based on the detected emotion
			let recommendations: string[] = [];
			try {
				recommendations = await generateRecommendations(
					analysis.emotion,
					entryData.text
				);
			} catch (error) {
				functions.logger.warn(
					`Failed to generate AI recommendations, using fallback: ${error}`
				);
				recommendations = getFallbackRecommendations(analysis.emotion);
			}

			// Update the mood entry with analysis results and recommendations
			await admin.firestore().collection("mood_entries").doc(entryId).update({
				emotion: analysis.emotion,
				confidenceScore: analysis.confidenceScore,
				recommendations: recommendations,
				analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
				analysisStatus: "completed",
			});

			functions.logger.info(
				`Successfully analyzed mood entry ${entryId}: ` +
					`${analysis.emotion} (${analysis.confidenceScore})`
			);

			return { success: true, analysis, recommendations };
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
 * Analyzes mood text using Mistral AI API
 */
async function analyzeMoodWithOpenAI(
	text: string
): Promise<{ emotion: string; confidenceScore: number }> {
	try {
		const emotionList = EMOTIONS.join(", ");
		const prompt =
			"Analyze the following mood journal entry and " +
			"determine the primary emotion. Choose only ONE emotion from " +
			`this list: ${emotionList}.

Journal Entry:
"${text}"

Respond in JSON format with:
{
  "emotion": "the primary emotion from the list",
  "confidence": a number between 0 and 1 indicating confidence,
  "reasoning": "brief explanation of why this emotion was chosen"
}

Be empathetic and consider the overall tone and context.`;

		const mistral = getMistralClient();
		const response = await mistral.chat({
			model: "mistral-small-latest",
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
			maxTokens: 200,
			responseFormat: { type: "json_object" },
		});

		const content = response.choices?.[0]?.message?.content;
		if (!content) {
			throw new Error("No response from Mistral AI");
		}

		const result = JSON.parse(content);

		// Validate the emotion is in our list
		const emotion = result.emotion.toLowerCase();
		if (!EMOTIONS.includes(emotion)) {
			functions.logger.warn(
				`Mistral AI returned unexpected emotion: ${emotion}, ` +
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
			`Mistral AI analysis: ${emotion} (${confidenceScore}), ` +
				`reasoning: ${result.reasoning}`
		);

		return {
			emotion,
			confidenceScore,
		};
	} catch (error) {
		functions.logger.error("Mistral AI API error:", error);
		throw new Error(`Failed to analyze mood with Mistral AI: ${error}`);
	}
}

/**
 * Generate personalized recommendations based on mood using Mistral AI
 */
async function generateRecommendations(
	emotion: string,
	moodText: string
): Promise<string[]> {
	try {
		const prompt =
			"Based on the following mood journal entry where " +
			`the person is feeling "${emotion}", provide 3 helpful, ` +
			"empathetic, and actionable recommendations or tips to help " +
			`them. Make the suggestions specific, supportive, and practical.

Journal Entry:
"${moodText}"

Respond in JSON format with:
{
  "recommendations": [
    "First actionable recommendation",
    "Second actionable recommendation", 
    "Third actionable recommendation"
  ]
}

Keep each recommendation brief (1-2 sentences) and focused on immediate, helpful actions.`;

		const mistral = getMistralClient();
		const response = await mistral.chat({
			model: "mistral-small-latest",
			messages: [
				{
					role: "system",
					content:
						"You are an empathetic mental health support assistant. " +
						"Provide compassionate, practical advice to help people manage " +
						"their emotions and wellbeing. Always respond in valid JSON format.",
				},
				{
					role: "user",
					content: prompt,
				},
			],
			temperature: 0.7,
			maxTokens: 300,
			responseFormat: { type: "json_object" },
		});

		const content = response.choices?.[0]?.message?.content;
		if (!content) {
			throw new Error("No response from Mistral AI for recommendations");
		}

		const result = JSON.parse(content);

		if (
			!result.recommendations ||
			!Array.isArray(result.recommendations) ||
			result.recommendations.length === 0
		) {
			throw new Error("Invalid recommendations format from Mistral AI");
		}

		functions.logger.info(
			`Generated ${result.recommendations.length} recommendations for ${emotion}`
		);

		return result.recommendations;
	} catch (error) {
		functions.logger.error("Mistral AI recommendations error:", error);
		throw new Error(`Failed to generate recommendations: ${error}`);
	}
}

/**
 * Get fallback recommendations when AI is unavailable
 */
function getFallbackRecommendations(emotion: string): string[] {
	const recommendations = FALLBACK_RECOMMENDATIONS[emotion.toLowerCase()];
	if (!recommendations) {
		// Default fallback for unknown emotions
		return [
			"Take a few moments to breathe deeply and center yourself.",
			"Consider talking to someone you trust about how you're feeling.",
			"Be kind to yourself - all emotions are valid and temporary.",
		];
	}
	return recommendations;
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

			// Generate recommendations
			let recommendations: string[] = [];
			try {
				recommendations = await generateRecommendations(
					analysis.emotion,
					entryData.text
				);
			} catch (error) {
				functions.logger.warn(
					`Failed to generate AI recommendations, using fallback: ${error}`
				);
				recommendations = getFallbackRecommendations(analysis.emotion);
			}

			// Update the entry
			await entryRef.update({
				emotion: analysis.emotion,
				confidenceScore: analysis.confidenceScore,
				recommendations: recommendations,
				analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
				analysisStatus: "completed",
			});

			return {
				success: true,
				emotion: analysis.emotion,
				confidenceScore: analysis.confidenceScore,
				recommendations: recommendations,
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
