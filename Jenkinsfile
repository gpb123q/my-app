pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:latest
    command: ["sleep", "infinity"]
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
    securityContext:
      privileged: true
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep", "infinity"]
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
'''
            defaultContainer 'docker'
        }
    }
    
    environment {
        // 镜像配置（如果使用本地构建，不需要 REGISTRY）
        APP_NAME = 'my-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        IMAGE_NAME = "${APP_NAME}:${IMAGE_TAG}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ 从 GitHub 检出代码成功"
                echo "📌 分支: ${env.BRANCH_NAME}"
                echo "📌 Commit: ${env.GIT_COMMIT}"
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        sh """
                            echo "🛠️ 开始构建 Docker 镜像..."
                            ls -la
                            docker build -t ${IMAGE_NAME} .
                            echo "✅ 镜像构建成功: ${IMAGE_NAME}"
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    script {
                        sh """
                            echo "🚀 部署到 Kubernetes..."
                            
                            # 创建部署
                            cat > deploy.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  labels:
    app: ${APP_NAME}
    version: ${IMAGE_TAG}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
        version: ${IMAGE_TAG}
    spec:
      containers:
      - name: ${APP_NAME}
        image: ${IMAGE_NAME}
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-service
spec:
  type: NodePort
  selector:
    app: ${APP_NAME}
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF
                            
                            # 应用部署
                            kubectl apply -f deploy.yaml
                            kubectl rollout status deployment/${APP_NAME}
                            
                            echo "✅ 部署成功！"
                            echo "🌐 访问地址: http://<节点IP>:30080"
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                container('kubectl') {
                    script {
                        sh """
                            echo "📊 检查部署状态..."
                            kubectl get pods -l app=${APP_NAME}
                            kubectl get svc ${APP_NAME}-service
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            // 注意：post 块中不要使用 container，直接用 echo
            echo """
🎉 流水线执行成功！
📦 镜像: ${IMAGE_NAME}
🌐 访问地址: http://<节点IP>:30080
📌 部署版本: ${IMAGE_TAG}
            """
        }
        failure {
            echo "❌ 流水线执行失败，请查看日志"
        }
        always {
            // post 块中不要执行复杂的容器操作
            echo "📌 流水线执行完毕"
        }
    }
}