# Firebase Functions Deployment Guide

## Understanding the Deployment Issue

When deploying Firebase Functions v2 (which uses Cloud Run), you may encounter "Container Healthcheck failed" errors on the **first deployment attempt** after making changes. This is normal and happens because:

1. **Cold Start**: Cloud Run needs to pull the container image, start it, and wait for it to listen on port 8080
2. **Initialization**: Your functions initialize Firebase Admin, services, and dependencies
3. **Health Check Timeout**: The default timeout might be too short for the first deployment

## Solutions Implemented

### 1. Increased Resources
- **Memory**: Upgraded from 256MB to 512MB for faster initialization
- **CPU**: Allocated 1 full CPU during execution to speed up processing
- **Max Instances**: Set to 100 to handle traffic spikes

### 2. Configuration Options

You can adjust these settings in `functions/utils/constants.js`:

```javascript
const FUNCTIONS_CONFIG = {
  REGION: 'us-central1',
  TIMEOUT_SECONDS: 560,
  MEMORY: '512MB',        // Increase for faster cold starts
  CPU: 1,                 // Allocate CPU resources
  MIN_INSTANCES: 0,       // Set to 1 to keep functions warm (costs money!)
  MAX_INSTANCES: 100      // Maximum concurrent instances
};
```

**To keep functions warm** (recommended for production):
- Set `MIN_INSTANCES: 1` to keep at least one instance always running
- **Note**: This increases costs but eliminates cold starts
- Estimated cost: ~$5-10/month per function

## Deployment Methods

### Method 1: Automatic Retry Script (Recommended)

Use the provided script that automatically retries deployment:

```bash
cd /Users/macbook/Projects/parcel_am
./functions/deploy-retry.sh
```

This script:
- Attempts deployment up to 3 times
- Waits progressively longer between retries
- Handles the first-deployment timeout gracefully

### Method 2: Manual Retry

Simply run the deployment command twice:

```bash
firebase deploy --only functions
# If it fails, run again:
firebase deploy --only functions
```

The second attempt almost always succeeds because the container image is already built.

### Method 3: Deploy Individual Functions

Deploy functions one at a time to reduce startup load:

```bash
firebase deploy --only functions:createPaystackTransaction
firebase deploy --only functions:verifyPaystackPayment
firebase deploy --only functions:paystackWebhook
# ... continue for other functions
```

### Method 4: Use Firebase CLI with Force Flag

```bash
firebase deploy --only functions --force
```

## Monitoring Deployments

### Check Deployment Status
```bash
firebase functions:log
```

### View Specific Function Logs
```bash
firebase functions:log --only createPaystackTransaction
```

### View Cloud Run Logs
Visit the URLs provided in the deployment output, or:
```bash
gcloud run services describe createpaystacktransaction --region=us-central1
```

## Troubleshooting

### Issue: All functions fail on first deployment
**Solution**: This is normal. Run the deployment again or use the retry script.

### Issue: Functions still failing after multiple attempts
**Possible causes**:
1. **API Key Missing**: Check that `PAYSTACK_SECRET_KEY` is set
   ```bash
   # Set Firebase config
   firebase functions:config:set paystack.secret_key="your_key_here"
   ```

2. **Syntax Error**: Check the logs for JavaScript errors
   ```bash
   firebase functions:log --only createPaystackTransaction
   ```

3. **Memory Issues**: Increase memory in `FUNCTIONS_CONFIG.MEMORY`

4. **Timeout Too Short**: The 560-second timeout should be sufficient, but you can increase it

### Issue: Deployment is slow
**Solutions**:
1. Deploy only changed functions:
   ```bash
   firebase deploy --only functions:functionName
   ```

2. Increase `MIN_INSTANCES` to 1 (keeps functions warm)

3. Use a faster internet connection (uploads ~125KB of code)

## Cost Optimization

### Free Tier (Current Setup: MIN_INSTANCES = 0)
- **Cost**: Free (within limits)
- **Drawback**: Cold starts on first request after idle period
- **Best for**: Development, low-traffic apps

### Warm Instances (MIN_INSTANCES = 1)
- **Cost**: ~$5-10/month per function
- **Benefit**: No cold starts, instant response
- **Best for**: Production apps, critical functions

### Recommended Production Setup
```javascript
// For critical functions (createPaystackTransaction, paystackWebhook)
MIN_INSTANCES: 1

// For less critical functions (checkFCMConfig)
MIN_INSTANCES: 0
```

## Quick Reference

### Common Commands
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy with retry
./functions/deploy-retry.sh

# Deploy specific function
firebase deploy --only functions:createPaystackTransaction

# View logs
firebase functions:log

# Test locally
firebase emulators:start --only functions

# Check function status
firebase functions:list
```

### Environment Variables
```bash
# Set Paystack API key
firebase functions:config:set paystack.secret_key="sk_test_xxx"

# View current config
firebase functions:config:get

# Unset a config value
firebase functions:config:unset paystack.secret_key
```

## Summary

✅ **Normal Behavior**: First deployment after changes may fail due to container startup timeout
✅ **Quick Fix**: Run deployment command again, or use the retry script
✅ **Long-term Fix**: Set `MIN_INSTANCES: 1` for critical functions (costs ~$5-10/month)
✅ **Monitoring**: Check logs with `firebase functions:log`

The enhanced logging added to your functions will now help you quickly identify where any issues occur!
