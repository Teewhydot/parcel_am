QUICK DEPLOYMENT GUIDE
======================

PROBLEM: First deployment fails with "Container Healthcheck failed"
SOLUTION: This is NORMAL. Just run deployment again.

OPTION 1 - Automatic Retry (Easiest):
  ./functions/deploy-retry.sh

OPTION 2 - Manual Retry:
  firebase deploy --only functions
  # If it fails, run it again immediately

OPTION 3 - Eliminate the Issue (Costs ~$5-10/month):
  Edit functions/utils/constants.js
  Change: MIN_INSTANCES: 0
  To:     MIN_INSTANCES: 1
  Then deploy as normal

WHY IT HAPPENS:
  - Cloud Run needs time to pull image and start container
  - First deployment after changes takes longer
  - Second attempt uses cached image = faster = succeeds

LOGGING ADDED:
  - All Paystack functions now have comprehensive logging
  - Check logs: firebase functions:log
  - Or view in Firebase Console: https://console.firebase.google.com/project/parcel-am/functions

API KEY ISSUE (401 Error):
  firebase functions:config:set paystack.secret_key="sk_test_YOUR_KEY_HERE"
  firebase deploy --only functions

See DEPLOYMENT_GUIDE.md for full details.
