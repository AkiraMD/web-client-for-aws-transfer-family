# Setup env vars
AWS_PROFILE=$1

# Replace with your preferred domain name
DOMAIN_NAME='virtualcare.telushealth.com' # NOTE: example, 'mycompanydomain.com'

# Use existing stack
stack_name="sftp-sec-hdr-stack-27746"
echo "Using existing stack: $stack_name"

# This template needs to be deployed in US-EAST-1 as Lambda@Edge functions are currently
# required to be in US-EAST-1 region
aws cloudformation update-stack --stack-name $stack_name --template-body file://06b-security-headers-lambda-edge.template --parameters ParameterKey=DomainName,ParameterValue=$DOMAIN_NAME \
 --profile $AWS_PROFILE --region us-east-1 --capabilities CAPABILITY_IAM

# Wait for stack update to complete
echo "Waiting for stack update to complete..."
aws cloudformation wait stack-update-complete --stack-name $stack_name --profile $AWS_PROFILE --region us-east-1

# Print the value of Lambda@Edge version, which will be needed in deployment/06b-security-headers-lambda-edge.template.
echo "Stack update complete. Getting Lambda@Edge version:"
lambda_edge_version=$(aws cloudformation describe-stacks --stack-name $stack_name --query "Stacks[0].Outputs[?OutputKey=='VersionedSecurityHeadersLambda'].OutputValue" --output text --profile $AWS_PROFILE --region us-east-1)
echo "Lambda@Edge Version ARN: $lambda_edge_version"
