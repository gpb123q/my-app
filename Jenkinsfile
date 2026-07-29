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
                sh '''
                    echo "🚀 部署 Nginx"
                    
                    # 创建部署
                    kubectl create deployment my-app --image=nginx:alpine --dry-run=client -o yaml > deploy.yaml
                    kubectl apply -f deploy.yaml
                    
                    # 暴露服务
                    kubectl expose deployment my-app --port=80 --type=NodePort --node-port=30080 --dry-run=client -o yaml > service.yaml
                    kubectl apply -f service.yaml
                    
                    # 查看状态
                    kubectl get pods
                    kubectl get svc
                    
                    echo "✅ 部署完成！访问端口: 30080"
                '''
            }
        }
    }
}