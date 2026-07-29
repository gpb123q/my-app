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
    command: ["cat"]
    tty: true
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
    securityContext:
      privileged: true
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
'''
            defaultContainer 'docker'
        }
    }
    
    environment {
        APP_NAME = 'my-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        IMAGE_NAME = "${APP_NAME}:${IMAGE_TAG}"
        // 使用本地镜像，不推送到远程仓库
        DOCKER_HOST = "unix:///var/run/docker.sock"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ 从 GitHub 检出代码成功"
                echo "📌 Commit: ${env.GIT_COMMIT}"
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        sh """
                            echo "🛠️ 开始构建 Docker 镜像..."
                            echo "当前目录内容："
                            ls -la
                            
                            echo "检查 Dockerfile 内容："
                            cat Dockerfile
                            
                            echo "构建镜像: ${IMAGE_NAME}"
                            docker build -t ${IMAGE_NAME} .
                            
                            echo "查看构建的镜像："
                            docker images | grep ${APP_NAME}
                            
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
                            
                            # 创建部署文件
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
                            
                            echo "部署文件内容："
                            cat deploy.yaml
                            
                            # 应用部署
                            kubectl apply -f deploy.yaml
                            
                            # 等待部署完成
                            kubectl rollout status deployment/${APP_NAME}
                            
                            echo "✅ 部署成功！"
                            echo "🌐 访问地址: http://<节点IP>:30080"
                            
                            # 查看 Pod 状态
                            kubectl get pods -l app=${APP_NAME}
                            kubectl get svc ${APP_NAME}-service
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
                            echo "📊 验证部署..."
                            
                            # 获取 Pod 状态
                            POD_STATUS=\$(kubectl get pods -l app=${APP_NAME} -o jsonpath='{.items[0].status.phase}')
                            echo "Pod 状态: \${POD_STATUS}"
                            
                            if [ "\${POD_STATUS}" = "Running" ]; then
                                echo "✅ Pod 运行正常"
                                
                                # 获取 Pod IP
                                POD_IP=\$(kubectl get pods -l app=${APP_NAME} -o jsonpath='{.items[0].status.podIP}')
                                echo "Pod IP: \${POD_IP}"
                                
                                # 测试服务（如果有 curl）
                                echo "测试服务访问..."
                                kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://\${POD_IP} || echo "服务测试完成"
                            else
                                echo "⚠️ Pod 状态: \${POD_STATUS}"
                                kubectl describe pod -l app=${APP_NAME}
                            fi
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
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
            echo "📌 流水线执行完毕"
        }
    }
}