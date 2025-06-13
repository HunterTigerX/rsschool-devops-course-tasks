const { Stack } = require("aws-cdk-lib");
const {
  S3Client,
  CreateBucketCommand,
  PutBucketVersioningCommand,
  PutBucketEncryptionCommand,
  PutPublicAccessBlockCommand,
  PutBucketPolicyCommand
} = require("@aws-sdk/client-s3");
const { DynamoDBClient, CreateTableCommand } = require("@aws-sdk/client-dynamodb");
const { HeadBucketCommand } = require("@aws-sdk/client-s3");
const { DescribeTableCommand } = require("@aws-sdk/client-dynamodb");

const region = "eu-west-1";

const s3Client = new S3Client({ region });
const dynamoDBClient = new DynamoDBClient({ region });

class TerraformStack extends Stack {
  constructor(scope, id, props) {
    super(scope, id, props);

    console.log("Hello, TerraformStack")

    async function createTerraformStateBucket() {
      const bucketName = 'huntertigerx3-terraform-state-bucket';


      try {
        // Check if bucket exists first
        try {
          await s3Client.send(new HeadBucketCommand({ Bucket: bucketName }));
          console.log(`Bucket ${bucketName} already exists. Skipping creation.`);
        } catch (error) {
          if (error.name === 'NotFound') {
            // Create S3 bucket if it doesn't exist
            await s3Client.send(new CreateBucketCommand({
              Bucket: bucketName,
              CreateBucketConfiguration: {
                LocationConstraint: region,
              },
            }));
            console.log(`Bucket ${bucketName} created successfully.`);
          } else {
            throw error;
          }
        }

        // Enable versioning
        await s3Client.send(new PutBucketVersioningCommand({
          Bucket: bucketName,
          VersioningConfiguration: {
            Status: 'Enabled'
          }
        }));
        console.log('Versioning enabled.');

        // Enable encryption
        await s3Client.send(new PutBucketEncryptionCommand({
          Bucket: bucketName,
          ServerSideEncryptionConfiguration: {
            Rules: [
              {
                ApplyServerSideEncryptionByDefault: {
                  SSEAlgorithm: 'AES256', // SSE-S3
                }
              }
            ]
          }
        }));
        console.log('Encryption enabled.');

        // Block public access
        await s3Client.send(new PutPublicAccessBlockCommand({
          Bucket: bucketName,
          PublicAccessBlockConfiguration: {
            BlockPublicAcls: true,
            IgnorePublicAcls: true,
            BlockPublicPolicy: true,
            RestrictPublicBuckets: true,
          },
        }));
        console.log('Public access blocked.');


        // Set bucket policy (example - adjust permissions as needed)
        const bucketPolicy = {
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Principal: {
                AWS: 'arn:aws:iam::218585377303:root', // Replace with your account ID
              },
              Action: [
                's3:ListBucket',
                's3:GetObject',
                's3:PutObject',
                's3:DeleteObject',
              ],
              Resource: [
                `arn:aws:s3:::${bucketName}`,
                `arn:aws:s3:::${bucketName}/*`,
              ],
            },
          ],
        };

        await s3Client.send(new PutBucketPolicyCommand({
          Bucket: bucketName,
          Policy: JSON.stringify(bucketPolicy),
        }));
        console.log('Bucket policy set.');

        console.log('Terraform state bucket setup complete!');

      } catch (error) {
        console.error('Error creating Terraform state resources:', error);
      }
    }


    const createLockTable = async () => {
      const tableName = 'terraform-state-locks';
      const dynamoDBClient = new DynamoDBClient({ region });

      try {
        // Check if table exists first
        try {
          await dynamoDBClient.send(new DescribeTableCommand({ TableName: tableName }));
          console.log(`DynamoDB table ${tableName} already exists. Skipping creation.`);
        } catch (error) {
          if (error.name === 'ResourceNotFoundException') {
            // Create table if it doesn't exist
            await dynamoDBClient.send(new CreateTableCommand({
              TableName: tableName,
              AttributeDefinitions: [
                {
                  AttributeName: 'LockID',
                  AttributeType: 'S',
                },
              ],
              KeySchema: [
                {
                  AttributeName: 'LockID',
                  KeyType: 'HASH',
                },
              ],
              // BillingMode: 'PAY_PER_REQUEST', // Or 'PROVISIONED' with ProvisionedThroughput
            }));
            console.log(`DynamoDB table ${tableName} created successfully for Terraform state locking.`);
          } else {
            throw error;
          }
        }
      } catch (error) {
        console.error('Error configuring DynamoDB table:', error);
      }

    };

    createTerraformStateBucket();
    createLockTable();

  }
}

module.exports = { TerraformStack };
