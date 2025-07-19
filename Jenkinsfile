pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'huntertigerx' 
        IMAGE_NAME = 'flask-app'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        HELM_RELEASE_NAME = 'flask-app'
        HELM_CHART_PATH = './flask-helm-chart'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        SONAR_SCANNER_TOOL = 'SonarQubeScanner' // Имя инструмента SonarQube Scanner в Jenkins
        SONAR_SERVER = 'SonarQube' // Имя SonarQube сервера в Jenkins
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
                // Рекомендуется хранить kubeconfig как 'Secret file' в Jenkins Credentials
                // и использовать withCredentials для доступа к нему.
                // Этот шаг оставлен для совместимости, но его стоит улучшить.
                sh '''
                    mkdir -p $HOME/.kube
                    if [ ! -f "${KUBECONFIG}" ]; then
                        echo "Kubeconfig not found. Please configure it manually or using credentials."
                        // Здесь можно добавить логику копирования, если это необходимо
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
                sh 'python3 -m pytest test_main.py --cov=app --cov-report=xml --junitxml=test-results.xml'
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
                withSonarQubeEnv(SONAR_SERVER) { 
                    sh """
                        ${tool(SONAR_SCANNER_TOOL)}/bin/sonar-scanner \
                        -Dsonar.projectKey=flask-app \
                        -Dsonar.projectName=flask-app \
                        -Dsonar.sources=. \
                        -Dsonar.python.coverage.reportPaths=coverage.xml \
                        -Dsonar.python.xunit.reportPath=test-results.xml \
                        -Dsonar.exclusions=flask-helm-chart/**,**/__pycache__/**,*.pyc,*.db
                    """
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo 'Checking SonarQube quality gate...'
                // УВЕЛИЧЕННЫЙ ТАЙМАУТ: Увеличиваем до 5 минут, чтобы дать SonarQube время на обработку
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build and Push Docker Image') {
            when {
                expression { return !env.BRANCH_NAME.startsWith('PR-') } // Не выполнять для Pull Request
            }
            steps {
                script {
                    echo "Building Docker image for ARM64 architecture..."
                    // Убедитесь, что ваш Dockerfile использует базовый образ для aarch64/arm64
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
                expression { return !env.BRANCH_NAME.startsWith('PR-') } // Не выполнять для Pull Request
            }
            steps {
                script {
                    echo 'Deploying to Kubernetes with Helm...'
                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \
                        --set image.repository=${DOCKER_REGISTRY}/${IMAGE_NAME} \
                        --set image.tag=${IMAGE_TAG} \
                        --namespace default \
                        --wait --timeout 5m0s
                    """
                    echo 'Deployment completed successfully.'
                }
            }
        }
        
        stage('Application Verification') {
            when {
                expression { return !env.BRANCH_NAME.startsWith('PR-') } // Не выполнять для Pull Request
            }
            steps {
                script {
                    echo 'Verifying application deployment...'
                    sh '''
                        # Даем приложению немного времени на запуск после --wait
                        sleep 15
                        
                        # Динамическое получение имени сервиса
                        SERVICE_NAME=$(kubectl get svc -l app.kubernetes.io/instance=${HELM_RELEASE_NAME} -o jsonpath='{.items[0].metadata.name}')
                        if [ -z "$SERVICE_NAME" ]; then
                            echo "❌ Could not find the service for release ${HELM_RELEASE_NAME}"
                            exit 1
                        fi
                        echo "Found service: $SERVICE_NAME"
                        
                        # Проброс порта и проверка
                        kubectl port-forward svc/$SERVICE_NAME 8888:80 &
                        PF_PID=$!
                        sleep 5
                        
                        RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888)
                        kill $PF_PID
                        
                        if [ "$RESPONSE_CODE" = "200" ]; then
                            echo "✅ Application verification successful (HTTP 200 OK)"
                        else
                            echo "❌ Application verification failed with HTTP code: $RESPONSE_CODE"
                            exit 1
                        fi
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
