pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  # 只使用 kubectl 容器，不需要 Docker
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
'''
            defaultContainer 'kubectl'
        }
    }
    
    environment {
        APP_NAME = 'my-app'
        NAMESPACE = 'default'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ 代码已从 GitHub 检出"
                echo "📌 分支: ${env.BRANCH_NAME}"
                echo "📌 Commit: ${env.GIT_COMMIT}"
                
                sh 'ls -la'
                sh 'echo "📂 src 目录内容:" && ls -la src/ || echo "src 目录不存在"'
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    script {
                        sh """
                            echo "🚀 开始部署到 Kubernetes..."
                            
                            # ========== 1. 创建 ConfigMap（存储静态文件） ==========
                            echo "📦 创建 ConfigMap..."
                            if [ -d "src" ] && [ "\$(ls -A src 2>/dev/null)" ]; then
                                kubectl create configmap ${APP_NAME}-html \
                                    --from-file=src/ \
                                    --dry-run=client -o yaml | kubectl apply -f -
                                echo "✅ ConfigMap 创建成功（从 src 目录）"
                            else
                                echo "⚠️ src 目录为空或不存在，创建默认页面"
                                mkdir -p src
                                cat > src/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>My App</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        h1 { color: #4CAF50; }
    </style>
</head>
<body>
    <h1>🚀 Hello from Jenkins + Kubernetes!</h1>
    <p>Deployed at: \$(date)</p>
    <p>Version: ${BUILD_NUMBER}</p>
</body>
</html>
HTMLEOF
                                kubectl create configmap ${APP_NAME}-html \
                                    --from-file=src/ \
                                    --dry-run=client -o yaml | kubectl apply -f -
                                echo "✅ ConfigMap 创建成功（使用默认页面）"
                            fi
                            
                            # ========== 2. 创建 Deployment ==========
                            echo "📦 创建 Deployment..."
                            cat > deploy.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
    version: "${BUILD_NUMBER}"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
        version: "${BUILD_NUMBER}"
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      volumes:
      - name: html
        configMap:
          name: ${APP_NAME}-html
EOF
                            
                            kubectl apply -f deploy.yaml
                            echo "✅ Deployment 创建成功"
                            
                            echo "⏳ 等待 Pod 启动..."
                            kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=120s
                            
                            # ========== 3. 创建 Service ==========
                            echo "📦 创建 Service..."
                            cat > service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-service
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
spec:
  type: NodePort
  selector:
    app: ${APP_NAME}
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF
                            
                            kubectl apply -f service.yaml
                            echo "✅ Service 创建成功"
                            
                            echo ""
                            echo "=========================================="
                            echo "✅ 部署完成！"
                            echo "=========================================="
                            echo "🌐 访问地址: http://<节点IP>:30080"
                            echo "📌 部署版本: ${BUILD_NUMBER}"
                            echo "=========================================="
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
                            echo ""
                            echo "📊 ========== 部署状态 =========="
                            
                            echo ""
                            echo "📦 Pods:"
                            kubectl get pods -l app=${APP_NAME} -n ${NAMESPACE} -o wide
                            
                            echo ""
                            echo "🌐 Services:"
                            kubectl get svc ${APP_NAME}-service -n ${NAMESPACE}
                            
                            echo ""
                            echo "📊 ConfigMap:"
                            kubectl get configmap ${APP_NAME}-html -n ${NAMESPACE} -o yaml | head -20
                            
                            echo ""
                            echo "📋 最近的 Pod 日志:"
                            POD_NAME=\$(kubectl get pods -l app=${APP_NAME} -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')
                            if [ ! -z "\$POD_NAME" ]; then
                                kubectl logs \$POD_NAME -n ${NAMESPACE} --tail=10
                            fi
                            
                            echo ""
                            echo "✅ 验证完成！"
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo """
🎉 ==========================================
🎉 流水线执行成功！
🎉 ==========================================
📦 应用: ${APP_NAME}
🌐 访问地址: http://<节点IP>:30080
📌 部署版本: ${BUILD_NUMBER}
🔢 Pod 副本: 2
==========================================
            """
        }
        failure {
            echo """
❌ ==========================================
❌ 流水线执行失败！
❌ ==========================================
📌 请查看上方日志排查问题
==========================================
            """
        }
        always {
            echo "📌 流水线执行完毕"
        }
    }
}