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
    command: ["cat"]
    tty: true
'''
            defaultContainer 'kubectl'
        }
    }
    
    stages {
        stage('Deploy') {
            steps {
                script {
                    sh '''
                        set -x  # 开启调试模式，显示每条命令
                        echo "🚀 开始部署..."
                        
                        # 1. 检查 kubectl 是否可用
                        echo "1. 检查 kubectl 版本..."
                        kubectl version --client
                        
                        # 2. 检查集群连接
                        echo "2. 检查集群连接..."
                        kubectl cluster-info
                        
                        # 3. 检查当前命名空间
                        echo "3. 当前命名空间:"
                        kubectl config view --minify | grep namespace
                        
                        # 4. 先删除旧资源（如果有）
                        echo "4. 清理旧资源..."
                        kubectl delete deployment my-app --ignore-not-found=true
                        kubectl delete service my-app-service --ignore-not-found=true
                        
                        # 5. 创建部署
                        echo "5. 创建 Deployment..."
                        kubectl create deployment my-app --image=nginx:alpine
                        
                        # 6. 等待 Deployment 就绪
                        echo "6. 等待 Deployment 就绪..."
                        kubectl rollout status deployment/my-app --timeout=60s
                        
                        # 7. 暴露服务
                        echo "7. 创建 Service..."
                        kubectl expose deployment my-app --port=80 --type=NodePort --node-port=30080
                        
                        # 8. 查看状态
                        echo "8. 查看部署状态..."
                        kubectl get pods
                        kubectl get svc
                        
                        echo "✅ 部署完成！"
                        echo "🌐 访问端口: 30080"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "📌 流水线执行完毕"
        }
    }
}