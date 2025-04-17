#!/bin/bash

# Load environment variables
if [ -f .env.terraform ]; then
    export $(cat .env.terraform | grep -v '^#' | xargs)
fi

# Check if AWS credentials are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS credentials not found in .env file"
    exit 1
fi

# Run terraform command
terraform "$@" 