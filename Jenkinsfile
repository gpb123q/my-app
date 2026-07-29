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
    args: ["infinity"]
'''
            defaultContainer 'kubectl'
        }
    }
    
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    echo "🚀 开始部署..."
                    
                    # 检查 kubectl
                    kubectl version --client
                    
                    # 测试集群连接
                    kubectl get nodes
                    
                    # 部署 Nginx
                    kubectl create deployment my-app --image=nginx:alpine
                    kubectl expose deployment my-app --port=80 --type=NodePort --node-port=30080
                    
                    # 查看状态
                    kubectl get pods
                    kubectl get svc
                    
                    echo "✅ 部署完成！访问端口: 30080"
                '''
            }
        }
    }
}