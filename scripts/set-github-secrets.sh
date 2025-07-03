#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 [prefix] [env_file]"
  echo "  prefix: Environment prefix (e.g., STAGING, PROD) - optional"
  echo "  env_file: Environment file to read from (optional, defaults to .env.<prefix_lowercase> or .env if no prefix)"
  echo ""
  echo "Examples:"
  echo "  $0 STAGING"
  echo "  $0 PROD"
  echo "  $0 STAGING .env.staging"
  echo "  $0 PROD .env.production"
  echo "  $0 .env.local"
  echo "  $0"
  exit 1
}

PREFIX="$1"

# Determine the environment file
if [[ -n "$2" ]]; then
  # Second argument provided, use it as env file
  ENV_FILE="$2"
elif [[ -n "$PREFIX" && "$PREFIX" =~ ^\. ]]; then
  # First argument starts with a dot, treat it as an env file
  ENV_FILE="$PREFIX"
  PREFIX=""
elif [[ -n "$PREFIX" ]]; then
  # Only prefix provided, derive env file from prefix
  ENV_FILE=".env.$(echo "$PREFIX" | tr '[:upper:]' '[:lower:]')"
else
  # No arguments provided, use default .env file
  ENV_FILE=".env"
fi

# Check if file exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Environment file '$ENV_FILE' not found!"
  echo "💡 Available .env files:"
  ls -la .env* 2>/dev/null || echo "   No .env files found"
  exit 1
fi

if [[ -n "$PREFIX" ]]; then
  echo "🚀 Setting GitHub secrets with prefix '$PREFIX' from file '$ENV_FILE'"
else
  echo "🚀 Setting GitHub secrets from file '$ENV_FILE'"
fi
echo ""

# Loop through each line of the .env file
while IFS='=' read -r key value || [[ -n "$key" ]]; do
  # Skip empty lines and comments
  if [[ -z "$key" || "$key" =~ ^# ]]; then
    continue
  fi

  # Remove surrounding quotes from value if present
  value="${value%\"}"
  value="${value#\"}"

  # Add prefix to the secret name if prefix is provided
  if [[ -n "$PREFIX" ]]; then
    prefixed_key="${PREFIX}_${key}"
  else
    prefixed_key="$key"
  fi

  echo "🔐 Setting secret: $prefixed_key"
  gh secret set "$prefixed_key" --body "$value"

done < "$ENV_FILE"

echo ""
if [[ -n "$PREFIX" ]]; then
  echo "✅ All secrets from $ENV_FILE have been set with prefix '$PREFIX'."
else
  echo "✅ All secrets from $ENV_FILE have been set."
fi
