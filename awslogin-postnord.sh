# Using SSO credentials
# Reference: https://postnord.slack.com/archives/C020LC6R0HK/p1631700986064900

function _getSessionTokenFile() {
  # Find the file name that contains the accessToken under ~/.aws/sso/cache
  local accessTokenFileName=undefined

  for fileName in `ls ~/.aws/sso/cache`; do
    # Read the accessToken from the sso cache file.
    local hasAccessToken=$(cat ~/.aws/sso/cache/$fileName | python3 -c 'import sys, json; print(json.load(sys.stdin)["accessToken"])')
  
    if [[ -n $hasAccessToken ]]; then
      accessTokenFileName=$fileName
      break
    fi
  done

  echo $accessTokenFileName
}

function _setSessionToken() {
  local accessTokenFileName=$(_getSessionTokenFile)
  
  if [[ $accessTokenFileName == undefined ]]; then
    echo "$(tput setaf 3)Unable to find the accessToken file under ~/.aws/sso/cache."
    echo "Logging in to AWS SSO...$(tput sgr0)"
    echo "------------------------------------------------------"
    aws sso login --profile $profile
    echo "------------------------------------------------------"

  else
    echo "Found a file with accessToken: $accessTokenFileName"
    # Refresh token if needed
    local expiryTime=$(cat ~/.aws/sso/cache/$accessTokenFileName | python3 -c 'import sys, json; print(json.load(sys.stdin)["expiresAt"])')
    local expiryDateTimeInSec=$(date -d $expiryTime +%s)
    local nowDateTimeInSec=$(date +%s)

    if [[ $nowDateTimeInSec > $expiryDateTimeInSec ]]; then
      echo "$(tput setaf 6)Session Token has expired at $(date -d $expiryTime). Refreshing token...$(tput sgr0)"
      echo "------------------------------------------------------"
      aws sso login --profile $profile
      echo "------------------------------------------------------"
    fi
  fi
}

function _awsSSOLoginToCredentials() {
  local profile=$1 # Get named profile from command line argument

  echo "profile argument:"
  echo $profile

  # Prerequisite install: python3
  local hasPython=$(which python3)
  if [[ -z $hasPython  ]]; then
    echo "$(tput setaf 1)Check that you have python3 correctly installed."
    return
  fi

  _setSessionToken
  local accessTokenFileName=$(_getSessionTokenFile)

  if [[ $accessTokenFileName == undefined ]]; then
    echo "$(tput setaf 1)Still unable to find the accessToken file under ~/.aws/sso/cache. Did you forget to do 'aws configure sso' for profile $profile?"
    echo "See https://pncorp.atlassian.net/wiki/spaces/CCOE/pages/2936406206/AWS+SSO+Login+Guide"
  else
    # Read the accessToken from the sso cache file.
    local accessToken=$(cat ~/.aws/sso/cache/$accessTokenFileName | python3 -c 'import sys, json; print(json.load(sys.stdin)["accessToken"])')

    if [[ -z $accessToken ]]; then
      echo "$(tput setaf 1)Failed to read access token from ~/.aws/sso/cache/$accessTokenFileName!"
    else
      # Get the credentials based on the sso accessToken
      local roleName=$(aws configure get sso_role_name --profile ${profile})
      local accountId=$(aws configure get sso_account_id --profile ${profile})
      local region=$(aws configure get sso_region --profile ${profile})
      echo "Fetching role credentials for AccountId: $accountId and Role: $roleName ..."

      local credentialsResponse=$(aws sso get-role-credentials --role-name $roleName --account-id $accountId --access-token $accessToken --region eu-west-1 --output text)

      if [[ -z $credentialsResponse ]]; then
        echo "roleName:"
        echo $roleName
        echo "accountId:"
        echo $accountId
        echo "accessToken:"
        echo $accessToken
        echo "$(tput setaf 1)Failed to fetch role credentials"
        echo "Error at line 82"
      else
        read propertyName accessKeyId expiration secretAccessKey sessionToken <<<${credentialsResponse}
        echo "Setting role credentials..."

        # Set the credentials as the default profile in the credentials file
        aws configure set aws_access_key_id "$accessKeyId" --profile "default"
        aws configure set aws_secret_access_key "$secretAccessKey"  --profile "default"
        aws configure set aws_session_token "$sessionToken"  --profile "default"

        # Set the region for default profile in the config file
        aws configure set region "$region"  --profile "default"

        # Set the credentials for the named profile in the credentials file
        aws configure set aws_access_key_id "$accessKeyId" --profile "$profile"
        aws configure set aws_secret_access_key "$secretAccessKey"  --profile "$profile"
        aws configure set aws_session_token "$sessionToken"  --profile "$profile"

        local expiryTime=$(cat ~/.aws/sso/cache/$accessTokenFileName | python3 -c 'import sys, json; print(json.load(sys.stdin)["expiresAt"])')
        echo "$(tput setaf 2)Successfully fetched and set role credentials - valid until $(date -d $expiryTime)"
      fi
    fi
  fi
}

_awsSSOLoginToCredentials $1;

# Authenticate to codeartifact to be able to download private NPM packages
aws codeartifact login --tool npm --repository analytics-automation --domain postnord --domain-owner 572447298935 --namespace @pn
aws codeartifact login --tool npm --repository analytics-automation --domain postnord --domain-owner 572447298935 --namespace @dad-monorepo-playground
aws codeartifact login --tool npm --repository custer --domain postnord --domain-owner 572447298935 --namespace @custer
