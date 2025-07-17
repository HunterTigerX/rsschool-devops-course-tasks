pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'huntertigerx'
        IMAGE_NAME = 'flask-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        HELM_CHART_PATH = './flask-helm-chart'
        SONAR_PROJECT_KEY = 'flask-app'
        SONAR_HOST_URL = 'http://localhost:9000'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Kubernetes Config') {
            steps {
                echo 'Setting up Kubernetes configuration...'
                sh '''
                    mkdir -p /var/lib/jenkins/.kube
                    if [ ! -f /var/lib/jenkins/.kube/config ]; then
                        echo "Kubeconfig not found, attempting to copy from K3s server"
                        # This assumes Jenkins has SSH access to the K3s server
                        # You may need to adjust this based on your setup
                        scp -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/id_rsa ec2-user@10.0.3.200:/etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
                        # Update server address in the kubeconfig
                        sed -i 's/127.0.0.1/10.0.3.200/g' /var/lib/jenkins/.kube/config
                    else
                        echo "Kubeconfig already exists"
                    fi
                    chmod 600 /var/lib/jenkins/.kube/config
                '''
                echo 'Kubernetes configuration set up successfully'
            }
        }
        
        stage('Build Application') {
            steps {
                echo 'Building Flask application...'
                sh 'pip3 install -r requirements.txt'
                echo 'Application built successfully'
            }
        }
        
        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                script {
                    try {
                        sh 'python3 -m pytest test_main.py -v --junitxml=test-results.xml --cov=. --cov-report=xml'
                    } catch (Exception e) {
                        echo 'Tests failed but continuing pipeline...'
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }
        

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQubeScanner') {
                    sh "/var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/SonarQubeScanner/bin/sonar-scanner -Dsonar.projectKey=flask-app -Dsonar.projectName=flask-app -Dsonar.sources=. -Dsonar.python.coverage.reportPaths=coverage.xml -Dsonar.python.xunit.reportPath=test-results.xml '-Dsonar.exclusions=flask-helm-chart/**'"
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo 'Checking SonarQube quality gate...'
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}")
                    echo "Docker image built: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        def image = docker.image("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}")
                        image.push()
                        image.push('latest')
                    }
                    echo "Docker image pushed: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                script {
                    echo 'Deploying to Kubernetes with Helm...'
                    sh """
                        helm upgrade --install flask-app ${HELM_CHART_PATH} \
                        --set image.repository=${DOCKER_REGISTRY}/${IMAGE_NAME} \
                        --set image.tag=${IMAGE_TAG} \
                        --namespace default \
                        --wait
                    """
                    echo 'Deployment completed successfully'
                }
            }
        }
        
        stage('Application Verification') {
            steps {
                script {
                    echo 'Verifying application deployment...'
                    sh '''
                        # Wait for pods to be ready
                        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=flask-helm-chart --timeout=300s
                        
                        # Use the correct service name
                        SERVICE_NAME="flask-app-flask-helm-chart"
                        echo "Using service: $SERVICE_NAME"
                        kubectl get svc $SERVICE_NAME
                        
                        # Port forward and test (use a different local port)
                        kubectl port-forward svc/$SERVICE_NAME 8888:8080 &
                        PF_PID=$!
                        sleep 10
                        
                        # Test the application
                        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888)
                        if [ "$RESPONSE" = "200" ]; then
                            echo "✅ Application is responding correctly"
                        else
                            echo "❌ Application verification failed with HTTP code: $RESPONSE"
                            kill $PF_PID 2>/dev/null || true
                            exit 1
                        fi
                        
                        # Test content
                        CONTENT=$(curl -s http://localhost:8888)
                        if [[ "$CONTENT" == *"Hello, World!"* ]]; then
                            echo "✅ Application content verification passed"
                        else
                            echo "❌ Application content verification failed"
                            kill $PF_PID 2>/dev/null || true
                            exit 1
                        fi
                        
                        kill $PF_PID 2>/dev/null || true
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed'
            cleanWs()
        }
        success {
            echo '✅ Pipeline executed successfully!'
            emailext (
                subject: "✅ Jenkins Pipeline Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Execution Successful</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><strong>Docker Image:</strong> ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}</p>
                    <p>Application has been successfully deployed to Kubernetes cluster.</p>
                """,
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'huntertigerx@gmail.com'}",
                mimeType: 'text/html'
            )
        }
        failure {
            echo '❌ Pipeline failed!'
            emailext (
                subject: "❌ Jenkins Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Execution Failed</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><strong>Failed Stage:</strong> ${env.STAGE_NAME}</p>
                    <p>Please check the build logs for more details.</p>
                """,
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'huntertigerx@gmail.com'}",
                mimeType: 'text/html'
            )
        }
    }
}
