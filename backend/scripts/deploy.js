const { execSync } = require("child_process");
const path = require("path");

function execute(command, cwd) {
  try {
    execSync(command, {
      stdio: "inherit",
      cwd: cwd || process.cwd(),
      env: { ...process.env }, // Ensure environment variables are passed through
    });
  } catch (error) {
    console.error(`Failed to execute ${command}`);
    console.error("Error details:", error.message);
    if (error.stdout) console.error("stdout:", error.stdout.toString());
    if (error.stderr) console.error("stderr:", error.stderr.toString());
    process.exit(1);
  }
}

async function deploy() {
  try {

    // Deploy infrastructure
    console.log("Installing CDK dependencies...");
    execute("npm install --legacy-peer-deps");

    // console.log("Building CDK...");
    // execute("npm run build");

    console.log("Deploying infrastructure...");
    execute("cdk deploy --require-approval never");

    console.log("\nImport deployment completed successfully!");
  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

deploy();
