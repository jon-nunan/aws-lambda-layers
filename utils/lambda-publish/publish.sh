#!/bin/bash

# This file publishes a new AWS Lambda layer on AWS using the AWS CLI.
# We rely on AWS CLI because it is installed by default on AWS CodeBuild.
#
# Environment variables:
# - `LAYER_NAME`: **required**
# - `REGION`: **required** Region to publish to.
# - `ONLY_REGION`: If provided, only this region will be published

# Fail on error
set -e

if [ -z "$LAYER_NAME" ]; then
    echo "\$LAYER_NAME must be set"
    exit 1
fi
if [ -z "$REGION" ]; then
    echo "\$REGION must be set"
    exit 1
fi
# If $ONLY_REGION is set, check if $REGION is part of the only allowed regions
if [ -n "$ONLY_REGION" ]; then
    # Split $ONLY_REGION into an array using IFS (Internal Field Separator)
    IFS=',' read -ra ALLOWED_REGIONS <<< "$ONLY_REGION"

    # Assume the region is not allowed unless found in the array
    is_allowed=false
    for allowed_region in "${ALLOWED_REGIONS[@]}"; do
        if [ "$REGION" == "$allowed_region" ]; then
            is_allowed=true
            break
        fi
    done

    # Skip the region if it is not allowed
    if [ "$is_allowed" == false ]; then
        echo "Skipping $REGION"
        exit 0
    fi
fi


echo "[Publish] Publishing layer $LAYER_NAME to $REGION..."

VERSION=$(aws lambda publish-layer-version \
   --region $REGION \
   --layer-name $LAYER_NAME \
   --description "Bref PHP Runtime" \
   --license-info MIT \
   --zip-file fileb://../../output/$LAYER_NAME.zip \
   --compatible-runtimes provided.al2023 \
   --output text \
   --query Version)

echo "[Publish] Layer $LAYER_NAME uploaded, adding permissions..."

aws lambda add-layer-version-permission \
    --region $REGION \
    --layer-name $LAYER_NAME \
    --version-number $VERSION \
    --statement-id public \
    --action lambda:GetLayerVersion \
    --principal "*"

echo "[Publish] Layer $LAYER_NAME published to $REGION"
