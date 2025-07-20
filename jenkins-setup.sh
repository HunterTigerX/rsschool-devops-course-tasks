#!/bin/bash

# Jenkins Setup Script for Task 6
# This script helps configure Jenkins for the CI/CD pipeline

echo "🚀 Setting up Jenkins for Flask App CI/CD Pipeline"

# Install required Jenkins plugins
echo "📦 Installing Jenkins plugins..."
jenkins-cli install-plugin pipeline-stage-view
jenkins-cli install-plugin docker-workflow
jenkins-cli install-plugin sonar
jenkins-cli install-plugin email-ext
jenkins-cli install-plugin kubernetes-cli

# Configure SonarQube server
echo "🔍 Configuring SonarQube integration..."
cat > sonarqube-config.xml << EOF
<hudson.plugins.sonar.SonarGlobalConfiguration>
  <installations>
    <hudson.plugins.sonar.SonarInstallation>
      <name>SonarQube</name>
      <serverUrl>http://sonarqube:9000</serverUrl>
      <credentialsId>sonar-auth-token</credentialsId>
    </hudson.plugins.sonar.SonarInstallation>
  </installations>
</hudson.plugins.sonar.SonarGlobalConfiguration>
EOF

# Configure Docker Hub credentials
echo "🐳 Setting up Docker Hub credentials..."
echo "Please add Docker Hub credentials in Jenkins:"
echo "1. Go to Manage Jenkins > Manage Credentials"
echo "2. Add Username/Password credential"
echo "3. ID: docker-hub-credentials"
echo "4. Username: your-dockerhub-username"
echo "5. Password: your-dockerhub-password"

# Configure email notifications
echo "📧 Email notification setup:"
echo "1. Go to Manage Jenkins > Configure System"
echo "2. Configure SMTP server settings"
echo "3. Test email configuration"

# Create pipeline job
echo "⚙️ Creating pipeline job..."
echo "1. New Item > Pipeline"
echo "2. Name: flask-app-pipeline"
echo "3. Pipeline script from SCM"
echo "4. Repository URL: your-git-repo"
echo "5. Script Path: Jenkinsfile"

echo "✅ Jenkins setup guide completed!"
echo "📋 Next steps:"
echo "   1. Configure credentials as mentioned above"
echo "   2. Set up SonarQube server"
echo "   3. Configure webhook in GitHub"
echo "   4. Test the pipeline"