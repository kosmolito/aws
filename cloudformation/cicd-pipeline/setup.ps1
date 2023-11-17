$CLOUDFORMATION_STACK_BUCKET = "cloudformation-stack-bucket-campus"
$WEB_CONTENT_BUCKET = "static-website-content-bucket-campus"
$REGION = "eu-west-1"

# Create a s3 bucket to store cloudformation stack
aws s3api create-bucket --bucket $CLOUDFORMATION_STACK_BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# Create a s3 bucket to store html folder (static website)
aws s3api create-bucket --bucket $WEB_CONTENT_BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# Upload cloudformation stack to s3 bucket
aws s3 cp ./cloudformation-stacks s3://$CLOUDFORMATION_STACK_BUCKET --recursive

# Upload html folder to s3 bucket, this will be copied when building our custom Docker image
aws s3 cp ./html s3://$WEB_CONTENT_BUCKET/html --recursive


###################### Create VPC Infrastructure and ECS Cluster ######################
# There are 2 parameters for the vpc-infra-setup.yml cloudformation template:
# 1. Environment: dev or prod (Default: dev)
# 2. EcsClusterName: The name of the ECS cluster (Default: ecs-cluster).
# It will be named as dev-ecs-cluster or prod-ecs-cluster depending on the environment parameter
aws cloudformation create-stack `
--stack-name prodnet `
--template-url https://$CLOUDFORMATION_STACK_BUCKET.s3.$REGION.amazonaws.com/vpc-infra-setup.yml `
--parameters ParameterKey=Environment,ParameterValue=prod --region $REGION

# Wait for the stack to be created

###################### Create a new CodeCommit Project ######################
# There are 2 parameters for the new-prject.yml cloudformation template:
# 1. CodeCommitRepositoryName: The name of the CodeCommit repository
# 2. EcrRepositoryName: The name of the ECR repository (Must be all lowercase)
# We need to use --capabilities CAPABILITY_NAMED_IAM because we are creating a IAM role in the cloudformation template
aws cloudformation create-stack `
--stack-name my-docker-app `
--template-url https://$CLOUDFORMATION_STACK_BUCKET.s3.$REGION.amazonaws.com/new-project.yml `
--parameters ParameterKey=CodeCommitRepositoryName,ParameterValue=my-docker-app ParameterKey=EcrRepositoryName,ParameterValue=my-docker-app `
--region $REGION --capabilities CAPABILITY_NAMED_IAM