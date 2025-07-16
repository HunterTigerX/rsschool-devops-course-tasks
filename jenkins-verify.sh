#!/bin/bash

# Jenkins Configuration Verification Script

JENKINS_URL=${1:-"http://localhost:8080"}
SONARQUBE_URL=${2:-"http://localhost:9000"}

echo "🔍 Verifying Jenkins Configuration"
echo "=================================="

# Check Jenkins accessibility
echo "1. Testing Jenkins accessibility..."
if curl -f "$JENKINS_URL" > /dev/null 2>&1; then
    echo "✅ Jenkins is accessible at $JENKINS_URL"
else
    echo "❌ Jenkins is not accessible at $JENKINS_URL"
    exit 1
fi

# Check Docker access for Jenkins user
echo "2. Testing Docker access..."
if sudo -u jenkins docker ps > /dev/null 2>&1; then
    echo "✅ Jenkins user can access Docker"
else
    echo "❌ Jenkins user cannot access Docker"
    echo "   Run: sudo usermod -aG docker jenkins"
fi

# Check SonarQube accessibility
echo "3. Testing SonarQube accessibility..."
if curl -f "$SONARQUBE_URL/api/system/status" > /dev/null 2>&1; then
    echo "✅ SonarQube is accessible at $SONARQUBE_URL"
else
    echo "❌ SonarQube is not accessible at $SONARQUBE_URL"
fi

# Check Kubernetes access
echo "4. Testing Kubernetes access..."
if sudo -u jenkins kubectl cluster-info > /dev/null 2>&1; then
    echo "✅ Jenkins user can access Kubernetes"
else
    echo "❌ Jenkins user cannot access Kubernetes"
    echo "   Check kubeconfig at /var/jenkins_home/.kube/config"
fi

# Check required plugins
echo "5. Checking required plugins..."
REQUIRED_PLUGINS=(
    "workflow-aggregator"
    "docker-workflow"
    "sonar"
    "email-ext"
    "kubernetes-cli"
)

for plugin in "${REQUIRED_PLUGINS[@]}"; do
    if curl -s "$JENKINS_URL/pluginManager/api/json?depth=1" | grep -q "\"shortName\":\"$plugin\""; then
        echo "✅ Plugin installed: $plugin"
    else
        echo "❌ Plugin missing: $plugin"
    fi
done

echo ""
echo "🎯 Configuration Summary:"
echo "========================"
echo "Jenkins URL: $JENKINS_URL"
echo "SonarQube URL: $SONARQUBE_URL"
echo ""
echo "📋 Next Steps:"
echo "1. Add credentials in Jenkins UI"
echo "2. Configure email settings"
echo "3. Create pipeline job"
echo "4. Set up GitHub webhook"