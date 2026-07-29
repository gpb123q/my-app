pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep"]
    args: ["3600"]
'''
            defaultContainer 'kubectl'
        }
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ 代码检出成功"
                echo "📌 分支: ${env.BRANCH_NAME}"
                echo "📌 Commit: ${env.GIT_COMMIT}"
            }
        }
        
        stage('Deploy Nginx') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "🚀 开始部署 Nginx 到 Kubernetes"
                    echo "=========================================="
                    
                    # 1. 检查 kubectl
                    echo ""
                    echo "1️⃣ 检查 kubectl 版本..."
                    kubectl version --client
                    
                    # 2. 检查集群连接
                    echo ""
                    echo "2️⃣ 检查集群连接..."
                    kubectl get nodes
                    
                    # 3. 查看当前命名空间
                    echo ""
                    echo "3️⃣ 当前命名空间:"
                    kubectl config view --minify | grep namespace || echo "default"
                    
                    # 4. 清理旧资源
                    echo ""
                    echo "4️⃣ 清理旧资源..."
                    kubectl delete deployment my-app --ignore-not-found=true
                    kubectl delete service my-app-service --ignore-not-found=true
                    
                    # 5. 创建 Deployment
                    echo ""
                    echo "5️⃣ 创建 Deployment (使用 nginx:alpine)..."
                    kubectl create deployment my-app --image=nginx:alpine
                    
                    # 6. 等待 Pod 启动
                    echo ""
                    echo "6️⃣ 等待 Pod 启动..."
                    sleep 5
                    
                    # 7. 检查 Pod 状态
                    echo ""
                    echo "7️⃣ 查看 Pod 状态:"
                    kubectl get pods -l app=my-app
                    
                    # 8. 暴露 Service (NodePort)
                    echo ""
                    echo "8️⃣ 创建 Service (NodePort: 30080)..."
                    kubectl expose deployment my-app --port=80 --type=NodePort --node-port=30080
                    
                    # 9. 查看 Service
                    echo ""
                    echo "9️⃣ 查看 Service 状态:"
                    kubectl get svc my-app-service
                    
                    echo ""
                    echo "=========================================="
                    echo "✅ 部署完成！"
                    echo "=========================================="
                    echo "🌐 访问地址: http://<节点IP>:30080"
                    echo "=========================================="
                '''
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh '''
                    echo ""
                    echo "=========================================="
                    echo "📊 验证部署"
                    echo "=========================================="
                    
                    echo ""
                    echo "📦 所有 Pods:"
                    kubectl get pods -l app=my-app -o wide
                    
                    echo ""
                    echo "🌐 所有 Services:"
                    kubectl get svc | grep my-app
                    
                    echo ""
                    echo "📋 获取 Pod 日志:"
                    POD_NAME=$(kubectl get pods -l app=my-app -o jsonpath='{.items[0].metadata.name}')
                    if [ ! -z "$POD_NAME" ]; then
                        echo "Pod: $POD_NAME"
                        kubectl logs $POD_NAME --tail=10
                    else
                        echo "⚠️ 没有找到 Pod"
                    fi
                    
                    echo ""
                    echo "=========================================="
                    echo "✅ 验证完成！"
                    echo "=========================================="
                '''
            }
        }
    }
    
    post {
        success {
            echo """
🎉 ==========================================
🎉 流水线执行成功！
🎉 ==========================================
📦 应用: my-app
🌐 访问地址: http://<节点IP>:30080
🔢 Pod 副本: 1
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
    }
}