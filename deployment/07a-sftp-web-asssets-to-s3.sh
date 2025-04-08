#!/bin/bash
# Ensure NVM is sourced and the correct Node version is used
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
NODE_VERSION="16" # Specify Node.js v16 for Angular 12 compatibility
nvm install $NODE_VERSION || nvm use $NODE_VERSION # Install Node v16 if missing, then use it
echo "Using Node.js version: $(node -v)"
echo "Using npm version: $(npm -v)"

# Setup env vars
AWS_PROFILE=$1

# Replace with your R53 Alias pointing to your ALB
BACKEND_URL='https:\/\/sftpapi.virtualcare.telushealth.com' # NOTE: example, and make sure to use the following format `https:\/\/sftpapi.mycompanydomain.com`


# replace with s3 static website bucket created in sftp-web-client-stack
SFTP_WEB_CLIENT_BUCKET=sftp-web-ui-artifacts-6952ec00 # example sftp-web-ui-artifacts-f57a2400

# Build the image from the source directory
pushd source/frontend

aws s3 rm s3://$SFTP_WEB_CLIENT_BUCKET --recursive --profile $AWS_PROFILE

rm -rf ./dist

sed -i -e "s/REPLACE_ME/$BACKEND_URL/" src/app/service/ftp.service.ts

npm install

ng build --prod

aws s3 sync --cache-control 'max-age=604800' --exclude index.html dist/sftp-ng-webui s3://$SFTP_WEB_CLIENT_BUCKET --profile $AWS_PROFILE

# index.html is not stored with cach control headers because we want a unique index.html created on every deploy
aws s3 sync --cache-control 'no-cache' dist/sftp-ng-webui s3://$SFTP_WEB_CLIENT_BUCKET/ --profile $AWS_PROFILE

popd
