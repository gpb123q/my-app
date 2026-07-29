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
    env:
    - name: KUBERNETES_SERVICE_HOST
      value: "kubernetes.default.svc"
'''
            defaultContainer 'kubectl'
        }
    }
    
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "🚀 使用 kubectl 部署"
                    echo "=========================================="
                    
                    # 检查 kubectl
                    kubectl version --client
                    
                    # 配置 kubectl 使用集群内认证
                    kubectl config set-cluster kubernetes \
                        --server=https://kubernetes.default.svc \
                        --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                    
                    kubectl config set-credentials jenkins \
                        --token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                    
                    kubectl config set-context kubernetes \
                        --cluster=kubernetes \
                        --user=jenkins \
                        --namespace=default
                    
                    kubectl config use-context kubernetes
                    
                    # 测试连接
                    kubectl get nodes
                    
                    # 部署 Nginx
                    kubectl create deployment my-app --image=nginx:alpine
                    kubectl expose deployment my-app --port=80 --type=NodePort --node-port=30080
                    
                    # 查看状态
                    kubectl get pods
                    kubectl get svc
                    
                    echo ""
                    echo "=========================================="
                    echo "✅ 部署完成！"
                    echo "🌐 访问地址: http://<节点IP>:30080"
                    echo "=========================================="
                '''
            }
        }
    }
}