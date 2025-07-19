pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'huntertigerx'
        IMAGE_NAME = 'flask-app'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        HELM_RELEASE_NAME = 'flask-app'
        HELM_CHART_PATH = './flask-helm-chart'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        SONAR_SCANNER_TOOL = 'SonarQubeScanner'
        SONAR_SERVER = 'SonarQube'
        COVERAGE_MODULE = 'main'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Setup Kubernetes Config') {
            steps {
                echo 'Setting up Kubernetes configuration...'
                sh '''
                    mkdir -p $HOME/.kube
                    if [ ! -f "${KUBECONFIG}" ]; then
                        echo "Kubeconfig not found. Please ensure it is configured on the Jenkins agent."
                    else
                        echo "Kubeconfig already exists."
                    fi
                    chmod 600 ${KUBECONFIG}
                '''
                echo 'Kubernetes configuration set up successfully.'
            }
        }

        stage('Build & Test') {
            steps {
                echo 'Installing dependencies and running tests...'
                sh 'pip3 install -r requirements.txt'
                sh "python3 -m pytest test_main.py --cov=${COVERAGE_MODULE} --cov-report=xml --junitxml=test-results.xml"
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            options {
                retry(1)
            }
            environment {
                SONAR_SCANNER_OPTS = "-Xmx512m"
            }
            steps {
                echo "Running SonarQube analysis with memory limit: ${SONAR_SCANNER_OPTS}"
                withSonarQubeEnv(SONAR_SERVER) {
                    sh """
                        ${tool(SONAR_SCANNER_TOOL)}/bin/sonar-scanner \\
                        -Dsonar.projectKey=flask-app \\
                        -Dsonar.projectName=flask-app \\
                        -Dsonar.sources=. \\
                        -Dsonar.python.coverage.reportPaths=coverage.xml \\
                        -Dsonar.python.xunit.reportPath=test-results.xml \\
                        -Dsonar.exclusions=flask-helm-chart/**,**/__pycache__/**,*.pyc,*.db,venv/**
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo 'Checking SonarQube quality gate...'
                timeout(time: 45, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build and Push Docker Image') {
            when {
                expression {
                    def branchName = env.BRANCH_NAME ?: 'main' 
                    return !branchName.startsWith('PR-')
                }
            }
            steps {
                script {
                    echo "Building Docker image for ARM64 architecture..."
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        def customImage = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}", "--platform linux/arm64 .")
                        customImage.push()
                        customImage.push('latest')
                    }
                    echo "Docker image pushed: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to K8s with Helm') {
            when {
                expression {
                    def branchName = env.BRANCH_NAME ?: 'main' 
                    return !branchName.startsWith('PR-')
                }
            }
            steps {
                script {
                    echo 'Deploying to Kubernetes with Helm...'
                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \\
                        --set image.repository=${DOCKER_REGISTRY}/${IMAGE_NAME} \\
                        --set image.tag=${IMAGE_TAG} \\
                        --namespace default \\
                        --wait --timeout 5m0s
                    """
                    echo 'Deployment completed successfully.'
                }
            }
        }

        stage('Application Verification') {
            when {
                expression {
                    def branchName = env.BRANCH_NAME ?: 'main' 
                    return !branchName.startsWith('PR-')
                }
            }
            steps {
                script {
                    echo 'Verifying application deployment...'
                    sleep 20
                    sh '''
                        set +e
                        SERVICE_NAME=$(kubectl get svc -l app.kubernetes.io/instance=${HELM_RELEASE_NAME} -o jsonpath='{.items[0].metadata.name}')
                        if [ -z "$SERVICE_NAME" ]; then
                            echo "❌ Could not find the service for release ${HELM_RELEASE_NAME}"
                            exit 1
                        fi
                        echo "Found service: $SERVICE_NAME"
                        
                        kubectl port-forward svc/$SERVICE_NAME 8888:80 &
                        PF_PID=$!
                        sleep 10
                        RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888)
                        kill $PF_PID
                        wait $PF_PID 2>/dev/null
                        
                        if [ "$RESPONSE_CODE" = "200" ]; then
                            echo "✅ Application verification successful (HTTP 200 OK)"
                        else
                            echo "❌ Application verification failed with HTTP code: $RESPONSE_CODE"
                            POD_NAME=$(kubectl get pods -l app.kubernetes.io/instance=${HELM_RELEASE_NAME} -o jsonpath='{.items[0].metadata.name}')
                            echo "Logs from pod ${POD_NAME}:"
                            kubectl logs $POD_NAME
                            exit 1
                        fi
                        set -e
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution finished.'
            cleanWs()
        }
        success {
            emailext (
                subject: "✅ SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: "Pipeline for ${env.JOB_NAME} build #${env.BUILD_NUMBER} completed successfully. Check it here: ${env.BUILD_URL}",
                to: "huntertigerx@gmail.com"
            )
        }
        failure {
            emailext (
                subject: "❌ FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: "Pipeline for ${env.JOB_NAME} build #${env.BUILD_NUMBER} failed at stage '${env.STAGE_NAME}'. Check the logs: ${env.BUILD_URL}",
                to: "huntertigerx@gmail.com"
            )
        }
    }
}
