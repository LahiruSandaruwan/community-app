# Cloud Functions Setup Guide

This guide will help you deploy Firebase Cloud Functions for push notifications and other backend features.

## Prerequisites

- Firebase CLI installed
- Firebase project created
- Billing enabled on Firebase (required for Cloud Functions, but there's a free tier)

## Free Tier Limits

Cloud Functions on Firebase has a **generous free tier**:
- **2 million invocations/month**
- **400,000 GB-seconds/month**
- **200,000 CPU-seconds/month**
- **5GB outbound networking/month**

For a small to medium educational app, this should be sufficient!

## Step 1: Install Firebase CLI

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login
```

## Step 2: Initialize Firebase in Your Project

```bash
# Navigate to project directory
cd community-app

# Initialize Firebase (if not already done)
firebase init

# Select:
# - Functions: Configure and deploy Cloud Functions
# - Firestore: Deploy rules and create indexes
# - Storage: Deploy rules
#
# Choose:
# - Use an existing project (select your EduConnect project)
# - Language: JavaScript
# - ESLint: No (or Yes if you prefer)
# - Install dependencies now: Yes
```

**Note:** The firebase.json, functions/package.json, and functions/index.js are already created for you!

## Step 3: Enable Billing (Required for Cloud Functions)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Settings** (gear icon) → **Usage and billing**
4. Click **Modify plan**
5. Select **Blaze (Pay as you go)**
6. Add payment method

**Don't worry!** You'll stay within the free tier for development and small-scale usage. Firebase will alert you if you approach the limits.

## Step 4: Install Dependencies

```bash
cd functions
npm install
cd ..
```

## Step 5: Deploy Cloud Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendMessageNotification
```

## Step 6: Deploy Firestore Rules and Indexes

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy Storage rules
firebase deploy --only storage
```

## Step 7: Verify Deployment

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Functions** section
4. You should see your deployed functions:
   - `sendMessageNotification`
   - `updateUnreadCounts`
   - `cleanupDeletedCommunity`
   - `sendWelcomeNotification`

## Functions Overview

### 1. sendMessageNotification

**Trigger:** New message created in any group chat

**What it does:**
- Sends push notifications to all group members except the sender
- Includes sender name, message preview, and group name
- Handles both regular messages and announcements
- Cleans up invalid FCM tokens

**Free tier impact:** ~1 invocation per message sent

### 2. updateUnreadCounts

**Trigger:** New message created in any group chat

**What it does:**
- Increments unread count for all group members except sender
- Updates the groupChat document

**Free tier impact:** ~1 invocation per message sent

### 3. cleanupDeletedCommunity

**Trigger:** Community document updated

**What it does:**
- When a community is marked as inactive, deletes all messages
- Helps keep database clean

**Free tier impact:** ~1 invocation per community deletion

### 4. sendWelcomeNotification

**Trigger:** Community document updated (new member added)

**What it does:**
- Sends welcome notification to new members
- Improves user onboarding experience

**Free tier impact:** ~1 invocation per new member

## Testing Cloud Functions Locally

You can test functions locally before deploying:

```bash
# Install Firebase emulator
firebase emulators:start --only functions,firestore

# The emulator will run on http://localhost:5001
```

Then test by creating messages in Firestore through your app while connected to the emulator.

## Monitoring and Logs

### View logs in terminal:
```bash
firebase functions:log
```

### View logs in Firebase Console:
1. Go to Functions → click on a function
2. View the **Logs** tab
3. See real-time execution logs

### Monitor usage:
1. Go to **Functions** in Firebase Console
2. See invocation count, execution time, and errors

## Troubleshooting

### Error: "Billing account not configured"
**Solution:** Enable Blaze plan in Firebase Console

### Error: "Functions did not deploy properly"
**Solution:**
```bash
cd functions
rm -rf node_modules
npm install
cd ..
firebase deploy --only functions
```

### Error: "CORS error" or "Permission denied"
**Solution:** Deploy Firestore rules:
```bash
firebase deploy --only firestore:rules
```

### Notifications not working
**Checklist:**
1. ✅ Functions deployed successfully
2. ✅ FCM token saved in user document
3. ✅ Device has internet connection
4. ✅ Notification permissions granted
5. ✅ Check function logs for errors

## Cost Estimation

### Example usage for 100 active users:
- **Messages sent per day:** 1,000 messages
- **Function invocations:**
  - sendMessageNotification: 1,000
  - updateUnreadCounts: 1,000
  - Other functions: ~100
  - **Total: ~2,100/day** or ~63,000/month

**Result:** Well within the **2 million free invocations** per month!

### When you might exceed free tier:
- More than 30,000 messages per day
- Hundreds of active communities
- Thousands of active users

Even then, costs are minimal (a few dollars per month).

## Security Best Practices

1. **Never expose API keys** in client code
2. **Use Firestore security rules** (already configured)
3. **Validate data** in Cloud Functions before processing
4. **Rate limit** expensive operations
5. **Monitor logs** for suspicious activity

## Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Cloud Functions Samples](https://github.com/firebase/functions-samples)

## Next Steps

After deploying Cloud Functions:
1. ✅ Test sending a message → verify notification received
2. ✅ Check function logs for any errors
3. ✅ Monitor usage in Firebase Console
4. ✅ Set up budget alerts (optional but recommended)

---

**That's it!** Your Cloud Functions are now deployed and will automatically send push notifications for new messages! 🎉
