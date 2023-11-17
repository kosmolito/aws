CLOUDFORMATION_STACK_BUCKET="cloudformation-stack-bucket-campus"
WEB_CONTENT_BUCKET="static-website-content-bucket-campus"
REGION="eu-west-1"

# Create a s3 bucket to store cloudformation stack
aws s3api create-bucket --bucket $CLOUDFORMATION_STACK_BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# Create a s3 bucket to store html folder (static website)
aws s3api create-bucket --bucket $WEB_CONTENT_BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# Upload cloudformation stack to s3 bucket
aws s3 cp ./cloudformation-stacks s3://$CLOUDFORMATION_STACK_BUCKET --recursive

# Upload html folder to s3 bucket, this will be copied when building our custom Docker image
aws s3 cp ./html s3://$WEB_CONTENT_BUCKET/html --recursive

# Create vpc-infra-setup.yaml stack both in dev and prod environments
STACK_FILE="vpc-infra-setup.yml"
ENVIRONMENT=("dev" "prod")
###################### Create VPC Infrastructure and ECS Cluster ######################
# There are 2 parameters for the vpc-infra-setup.yml cloudformation template:
# 1. Environment: dev or prod (Default: dev)
# 2. EcsClusterName: The name of the ECS cluster (Default: ecs-cluster).
# It will be named as dev-ecs-cluster or prod-ecs-cluster depending on the environment parameter

# Create a stack for each environment, dev and prod
FOR env in "${ENVIRONMENT[@]}"; do
  aws cloudformation create-stack --stack-name "${ENVIRONMENT}net" \
  --template-url https://$CLOUDFORMATION_STACK_BUCKET.s3.$REGION.amazonaws.com/$STACK_FILE \
  --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT --region $REGION
done
