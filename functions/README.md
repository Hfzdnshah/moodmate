# Firebase Cloud Functions Setup

This directory contains Firebase Cloud Functions for the MoodMate application.

## Prerequisites

- Node.js 18 or higher
- Firebase CLI (`npm install -g firebase-tools`)
- OpenAI API key

## Installation

1. Navigate to the functions directory:

```bash
cd functions
```

2. Install dependencies:

```bash
npm install
```

## Configuration

### OpenAI API Key

You need to configure your OpenAI API key. You have two options:

#### Option 1: Using Firebase Functions Config (Recommended for production)

```bash
firebase functions:config:set openai.key="your-openai-api-key-here"
```

To view your current config:

```bash
firebase functions:config:get
```

#### Option 2: Using Environment Variables (For local development)

Create a `.env` file in the functions directory:

```bash
OPENAI_API_KEY=your-openai-api-key-here
```

**Note:** Never commit the `.env` file to version control.

## Development

### Build TypeScript

```bash
npm run build
```

### Watch mode (auto-rebuild on changes)

```bash
npm run build:watch
```

### Test locally with Firebase Emulator

```bash
npm run serve
```

This will start the Firebase Emulator Suite. You can test your functions locally before deploying.

## Deployment

### Deploy all functions

```bash
npm run deploy
```

### Deploy a specific function

```bash
firebase deploy --only functions:analyzeMoodEntry
```

or

```bash
firebase deploy --only functions:retryMoodAnalysis
```

## Functions

### analyzeMoodEntry

**Trigger:** Firestore onCreate  
**Path:** `mood_entries/{entryId}`

Automatically triggered when a new mood entry is created. Analyzes the mood entry text using OpenAI and updates the document with:

- `emotion`: Primary detected emotion
- `confidenceScore`: Confidence level (0-1)
- `analyzedAt`: Timestamp of analysis
- `analysisStatus`: "completed" or "failed"

**Error Handling:**

- Automatically retries on failure (Firebase default retry mechanism)
- Marks entry as "failed" if analysis fails
- Logs errors to Firebase Functions logs

### retryMoodAnalysis

**Trigger:** HTTPS Callable  
**Authentication:** Required

Allows users to manually retry analysis for a failed mood entry.

**Request:**

```javascript
{
	entryId: "the-mood-entry-id";
}
```

**Response:**

```javascript
{
  success: true,
  emotion: "joy",
  confidenceScore: 0.85
}
```

## Emotions

The system recognizes the following emotions:

- joy
- sadness
- anxiety
- anger
- fear
- contentment
- excitement
- frustration
- loneliness
- hope
- overwhelmed
- peaceful
- confused
- grateful
- stressed

## Monitoring

### View logs

```bash
npm run logs
```

or for real-time logs:

```bash
firebase functions:log --follow
```

### Check function health

Go to the [Firebase Console](https://console.firebase.google.com/) → Functions to view:

- Invocation count
- Execution time
- Error rate
- Memory usage

## Cost Optimization

- The function uses `gpt-3.5-turbo` which is cost-effective
- `max_tokens` is limited to 200 to minimize costs
- Consider implementing rate limiting for high-traffic scenarios

## Security

- Firebase Authentication is enforced for the callable function
- Firestore Security Rules should prevent unauthorized access to mood entries
- OpenAI API key is stored securely in Firebase Functions config
- User can only retry analysis for their own entries

## Troubleshooting

### "Missing OpenAI API key" error

Make sure you've set the API key using one of the methods above.

### Function times out

Increase the timeout in the function configuration:

```typescript
export const analyzeMoodEntry = functions
	.runWith({ timeoutSeconds: 120 })
	.firestore.document("mood_entries/{entryId}")
	.onCreate(async (snap, context) => {
		// ...
	});
```

### OpenAI rate limit errors

If you hit rate limits:

1. Upgrade your OpenAI plan
2. Implement exponential backoff
3. Add request queuing

## Testing

### Unit Tests (TODO)

```bash
npm test
```

### Integration Tests

Use the Firebase Emulator Suite to test functions locally before deployment.

## License

Private - MoodMate Project
