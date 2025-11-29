#!/bin/bash

# Firebase Functions Deployment Script with Retry Logic
# This script helps with the container startup timeout issues on first deployment

set -e

echo "🚀 Starting Firebase Functions Deployment..."
echo "============================================="

MAX_RETRIES=3
RETRY_COUNT=0
SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$SUCCESS" = false ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))

    echo ""
    echo "📦 Deployment attempt $RETRY_COUNT of $MAX_RETRIES..."
    echo "--------------------------------------------"

    if firebase deploy --only functions; then
        echo ""
        echo "✅ Deployment successful!"
        SUCCESS=true
    else
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            WAIT_TIME=$((RETRY_COUNT * 10))
            echo ""
            echo "⚠️  Deployment failed. Retrying in ${WAIT_TIME} seconds..."
            echo "   This is normal for the first deployment after changes."
            sleep $WAIT_TIME
        else
            echo ""
            echo "❌ Deployment failed after $MAX_RETRIES attempts."
            echo "   Please check the logs above for errors."
            exit 1
        fi
    fi
done

echo ""
echo "============================================="
echo "🎉 All functions deployed successfully!"
echo "============================================="
