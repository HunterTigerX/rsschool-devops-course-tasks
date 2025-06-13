const cdk = require("aws-cdk-lib");
const { TerraformStack } = require("../../lib/stack");

const app = new cdk.App();
new TerraformStack(app, "TerraformStack", {
  stackName: "TerraformStack",
  env: {
    region: "eu-west-1",
  },
});
