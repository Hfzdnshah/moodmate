# Cloud Functions Deployment Guide

This guide will walk you through setting up and deploying the AI mood analysis Cloud Functions for MoodMate.

## Prerequisites

Before you begin, make sure you have:

1. **Node.js 18 or higher** installed

   - Check version: `node --version`
   - Download: https://nodejs.org/

2. **Firebase CLI** installed

   ```bash
   npm install -g firebase-tools
   ```

3. **OpenAI API Key**

   - Sign up at: https://platform.openai.com/
   - Create an API key in your account settings
   - Note: You'll need billing enabled for API access

4. **Firebase Project** set up
   - Make sure you've already configured Firebase in your Flutter app
   - Your project should be linked to Firebase (check `firebase_options.dart`)

## Step 1: Login to Firebase

```bash
firebase login
```

This will open a browser window for you to authenticate with your Google account.

## Step 2: Select Your Firebase Project

```bash
firebase use --add
```

Select your project (mindmate-6b273) from the list and give it an alias (e.g., "default").

Or if you already know your project ID:

```bash
firebase use mindmate-6b273
```

## Step 3: Install Dependencies

Navigate to the functions directory and install dependencies:

```bash
cd functions
npm install
```

This will install:

- `firebase-admin`: Firebase Admin SDK for server-side operations
- `firebase-functions`: Cloud Functions SDK
- `openai`: OpenAI API client

## Step 4: Configure OpenAI API Key

### For Production Deployment

Set your OpenAI API key in Firebase Functions config:

```bash
firebase functions:config:set openai.key="sk-your-actual-openai-api-key-here"
```

**Important:** Replace `sk-your-actual-openai-api-key-here` with your actual OpenAI API key.

Verify the configuration:

```bash
firebase functions:config:get
```

You should see:

```json
{
	"openai": {
		"key": "sk-your-actual-key..."
	}
}
```

### For Local Development (Optional)

If you want to test locally:

1. Copy the example env file:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=sk-your-actual-openai-api-key-here
   ```

## Step 5: Build TypeScript

Compile the TypeScript code to JavaScript:

```bash
npm run build
```

This creates the `lib/` directory with compiled JavaScript files.

## Step 6: Test Locally (Optional but Recommended)

Before deploying to production, test your functions locally:

```bash
npm run serve
```

This starts the Firebase Emulator Suite. You can:

- Test functions without incurring costs
- Debug issues before deployment
- Verify OpenAI integration works

The emulator will show URLs like:

```
✔  functions[us-central1-analyzeMoodEntry]: firestore function initialized.
✔  functions[us-central1-retryMoodAnalysis]: http function initialized (http://localhost:5001/...).
```

## Step 7: Deploy to Firebase

Deploy your functions to Firebase:

```bash
npm run deploy
```

Or using Firebase CLI directly:

```bash
firebase deploy --only functions
```

The deployment will:

1. Upload your function code
2. Configure triggers
3. Set up the runtime environment
4. Make functions available

You'll see output like:

```
✔  functions[analyzeMoodEntry(us-central1)]: Successful create operation.
✔  functions[retryMoodAnalysis(us-central1)]: Successful create operation.

✔  Deploy complete!
```

## Step 8: Verify Deployment

### Check Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Functions** in the left menu
4. You should see:
   - `analyzeMoodEntry` - Firestore trigger
   - `retryMoodAnalysis` - HTTP callable

### Test the Function

Create a mood entry in your Flutter app and check:

1. **Firestore Console**: The mood entry should update with:

   - `emotion`: detected emotion
   - `confidenceScore`: confidence level
   - `analyzedAt`: timestamp
   - `analysisStatus`: "completed"

2. **Functions Logs**: View logs to see the analysis happening:
   ```bash
   firebase functions:log
   ```

## Step 9: Monitor Function Performance

### View Real-time Logs

```bash
firebase functions:log --follow
```

### Check Metrics in Console

In the Firebase Console → Functions, you can see:

- **Invocations**: How many times functions are called
- **Execution time**: How long functions take
- **Error rate**: If functions are failing
- **Memory usage**: Resource consumption

## Troubleshooting

### "Missing OpenAI API key" Error

**Solution:** Make sure you set the config correctly:

```bash
firebase functions:config:set openai.key="your-key"
firebase deploy --only functions
```

### "Billing account not configured" Error

**Solution:**

1. Go to Firebase Console → Settings → Usage and Billing
2. Enable the Blaze (pay-as-you-go) plan
3. Cloud Functions require a billing account

### "Function execution timed out"

**Solution:** Increase timeout in `index.ts`:

```typescript
export const analyzeMoodEntry = functions
	.runWith({ timeoutSeconds: 120 })
	.firestore.document("mood_entries/{entryId}")
	.onCreate(async (snap, context) => {
		// ...
	});
```

### OpenAI Rate Limit Errors

**Solution:**

1. Check your OpenAI usage limits
2. Upgrade your OpenAI plan if needed
3. Consider implementing request queuing

### Function not triggering

**Solution:**

1. Check Firestore Security Rules allow writing
2. Verify the document path is exactly `mood_entries/{entryId}`
3. Check Firebase Functions logs for errors

## Cost Considerations

### Firebase Functions Pricing

- **Free tier**: 2M invocations/month, 400,000 GB-seconds, 200,000 GHz-seconds
- After free tier: ~$0.40 per million invocations

### OpenAI API Pricing (as of 2024)

- **GPT-3.5-turbo**: ~$0.002 per 1K tokens
- Average mood entry analysis: ~150-200 tokens = ~$0.0004 per analysis
- 1000 analyses = ~$0.40

**Total estimated cost for 1000 mood entries:** ~$0.80

## Security Best Practices

1. **Never commit API keys** - Use Firebase config or environment variables
2. **Use Firestore Security Rules** - Ensure only authenticated users can write mood entries
3. **Validate user permissions** - The retry function checks user ownership
4. **Monitor for abuse** - Set up alerts for unusual activity

## Updating Functions

When you make changes to the function code:

1. Edit files in `functions/src/`
2. Build: `npm run build`
3. Test locally: `npm run serve` (optional)
4. Deploy: `npm run deploy`

## Rolling Back

If something goes wrong, you can roll back:

```bash
firebase functions:delete analyzeMoodEntry
firebase functions:delete retryMoodAnalysis
```

Then redeploy an earlier version.

## Next Steps

1. **Test thoroughly** - Create several mood entries and verify analysis
2. **Monitor logs** - Watch for errors or unexpected behavior
3. **Set up alerts** - Configure error notifications in Firebase
4. **Optimize prompts** - Refine the OpenAI prompt for better results
5. **Add retry UI** - Update Flutter app to show retry button for failed analyses

## Support

If you encounter issues:

1. Check Firebase Functions logs: `firebase functions:log`
2. Review Firebase Console for error details
3. Verify OpenAI API key is valid
4. Ensure billing is enabled on both Firebase and OpenAI

## Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Cloud Functions Best Practices](https://firebase.google.com/docs/functions/best-practices)
