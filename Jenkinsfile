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
        stage('Deploy to K8s') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "🚀 使用 kubectl 部署"
                    echo "=========================================="
                    
                    # bitnami/kubectl 自带 curl
                    which curl
                    
                    # 获取 K8s 认证信息
                    APISERVER=https://kubernetes.default.svc
                    TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                    CA_CERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                    NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
                    
                    # 使用 curl 调用 API
                    echo "创建 Deployment..."
                    
                    curl -k --cacert $CA_CERT \
                         -H "Authorization: Bearer $TOKEN" \
                         -H "Content-Type: application/yaml" \
                         -X POST \
                         -d '
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
  labels:
    app: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
' \
                         $APISERVER/apis/apps/v1/namespaces/default/deployments
                    
                    echo ""
                    
                    curl -k --cacert $CA_CERT \
                         -H "Authorization: Bearer $TOKEN" \
                         -H "Content-Type: application/yaml" \
                         -X POST \
                         -d '
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: default
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
' \
                         $APISERVER/api/v1/namespaces/default/services
                    
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