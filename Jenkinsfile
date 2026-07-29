pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  # Docker 构建容器
  - name: docker
    image: docker:latest
    command:
    - sleep
    args:
    - infinity
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
    securityContext:
      privileged: true
  # Kubectl 操作容器
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - sleep
    args:
    - infinity
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
'''
            defaultContainer 'docker'
        }
    }
    
    environment {
        // 镜像仓库配置（使用 Harbor 或 Docker Hub）
        REGISTRY = 'harbor.example.com'
        PROJECT = 'my-project'
        APP_NAME = 'my-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        IMAGE_NAME = "${REGISTRY}/${PROJECT}/${APP_NAME}:${IMAGE_TAG}"
        
        // K8s 配置（如果需要认证）
        KUBECONFIG = credentials('kubeconfig')  // Jenkins 凭据中保存的 kubeconfig
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ 代码检出成功'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        // 构建镜像
                        sh """
                            docker build -t ${IMAGE_NAME} .
                            echo "✅ Docker 镜像构建成功: ${IMAGE_NAME}"
                        """
                    }
                }
            }
        }
        
        stage('Push Image') {
            steps {
                container('docker') {
                    script {
                        // 登录镜像仓库（如果需要）
                        withCredentials([usernamePassword(
                            credentialsId: 'harbor-credentials',
                            usernameVariable: 'REGISTRY_USER',
                            passwordVariable: 'REGISTRY_PASS'
                        )]) {
                            sh """
                                docker login ${REGISTRY} -u ${REGISTRY_USER} -p ${REGISTRY_PASS}
                                docker push ${IMAGE_NAME}
                                echo "✅ 镜像推送成功: ${IMAGE_NAME}"
                            """
                        }
                    }
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                container('kubectl') {
                    script {
                        // 使用 kubeconfig 配置认证
                        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                            // 替换 deployment.yaml 中的镜像名
                            sh """
                                sed -i 's|\${IMAGE_NAME}|${IMAGE_NAME}|g' k8s/deployment.yaml
                                
                                # 部署到 Kubernetes
                                kubectl apply -f k8s/deployment.yaml
                                
                                # 等待部署完成
                                kubectl rollout status deployment/my-app -n default
                                
                                echo "✅ 部署成功！"
                                echo "📌 访问地址: http://<node-ip>:30080"
                            """
                        }
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                container('kubectl') {
                    script {
                        // 获取 Pod 状态
                        sh """
                            echo "📊 Pod 状态:"
                            kubectl get pods -l app=${APP_NAME}
                            
                            echo "📊 Service 状态:"
                            kubectl get svc ${APP_NAME}-service
                        """
                        
                        // 测试服务是否可用
                        sh """
                            echo "🔍 测试服务..."
                            # 获取 Pod IP 并测试
                            POD_IP=\$(kubectl get pods -l app=${APP_NAME} -o jsonpath='{.items[0].status.podIP}')
                            echo "Pod IP: \$POD_IP"
                            
                            # 在集群内测试
                            kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s http://\$POD_IP | head -n 5 || echo "测试完成"
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
🌐 访问地址: http://<node-ip>:30080
            """
        }
        failure {
            echo "❌ 流水线执行失败，请检查日志"
        }
        always {
            script {
                // 清理资源（可选）
                container('docker') {
                    sh """
                        docker rmi ${IMAGE_NAME} || true
                    """
                }
            }
        }
    }
}