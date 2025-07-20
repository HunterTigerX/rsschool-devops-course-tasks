#!/bin/bash

# Jenkins Auto-Setup Script
# This script automates Jenkins configuration for the CI/CD pipeline

set -e

JENKINS_URL=${1:-"http://localhost:8080"}
JENKINS_USER=${2:-"admin"}
JENKINS_PASSWORD=${3:-"admin"}
SONARQUBE_URL=${4:-"http://localhost:9000"}

echo "🚀 Starting Jenkins Auto-Setup"
echo "📍 Jenkins URL: $JENKINS_URL"
echo "🔍 SonarQube URL: $SONARQUBE_URL"

# Function to install Jenkins plugin
install_plugin() {
    local plugin_name=$1
    echo "📦 Installing plugin: $plugin_name"
    
    curl -X POST \
        -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "plugin.${plugin_name}.default=on" \
        "$JENKINS_URL/pluginManager/install"
}

# Install required plugins
echo "📦 Installing Jenkins plugins..."
install_plugin "workflow-aggregator"
install_plugin "docker-workflow"
install_plugin "sonar"
install_plugin "email-ext"
install_plugin "kubernetes-cli"
install_plugin "junit"
install_plugin "github"

# Wait for plugin installation
echo "⏳ Waiting for plugin installation..."
sleep 30

# Restart Jenkins
echo "🔄 Restarting Jenkins..."
curl -X POST \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    "$JENKINS_URL/restart"

# Wait for Jenkins to restart
echo "⏳ Waiting for Jenkins restart..."
sleep 60

# Configure Docker permissions
echo "🐳 Configuring Docker permissions..."
sudo usermod -aG docker jenkins || echo "⚠️  Manual Docker setup required"

# Create SonarQube container if not exists
echo "🔍 Setting up SonarQube..."
if ! docker ps | grep -q sonarqube; then
    docker run -d --name sonarqube \
        -p 9000:9000 \
        -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
        sonarqube:latest
    
    echo "⏳ Waiting for SonarQube startup..."
    sleep 90
fi

# Test SonarQube connection
echo "🧪 Testing SonarQube connection..."
if curl -f "$SONARQUBE_URL/api/system/status" > /dev/null 2>&1; then
    echo "✅ SonarQube is accessible"
else
    echo "❌ SonarQube connection failed"
fi

# Create Jenkins job configuration
echo "⚙️ Creating pipeline job configuration..."
cat > flask-app-pipeline-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>Flask Application CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty>
      <projectUrl>https://github.com/your-username/your-repo/</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger>
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/your-username/your-repo.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
</flow-definition>
EOF

echo "✅ Jenkins auto-setup completed!"
echo ""
echo "📋 Manual steps still required:"
echo "1. Add Docker Hub credentials (ID: docker-hub-credentials)"
echo "2. Add SonarQube token (ID: sonar-auth-token)"
echo "3. Configure email SMTP settings"
echo "4. Update pipeline job with your repository URL"
echo "5. Set up GitHub webhook"
echo ""
echo "📖 See JENKINS_SETUP_GUIDE.md for detailed instructions"