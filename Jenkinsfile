pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sleep"]
    args: ["3600"]
'''
            defaultContainer 'alpine'
        }
    }
    
    stages {
        stage('Deploy to K8s') {
            steps {
                script {
                    // 使用 Kubernetes 插件提供的功能
                    sh '''
                        echo "=========================================="
                        echo "🚀 通过 Jenkins 插件部署"
                        echo "=========================================="
                        
                        # 用 curl 直接调用 K8s API
                        echo "使用 K8s API 部署..."
                        
                        # 获取 K8s API Server 地址
                        APISERVER=https://kubernetes.default.svc
                        TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                        CA_CERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                        
                        echo "API Server: $APISERVER"
                        
                        # 创建 Deployment
                        cat > deploy.json << 'EOF'
{
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "name": "my-app",
    "labels": {"app": "my-app"}
  },
  "spec": {
    "replicas": 1,
    "selector": {
      "matchLabels": {"app": "my-app"}
    },
    "template": {
      "metadata": {
        "labels": {"app": "my-app"}
      },
      "spec": {
        "containers": [{
          "name": "nginx",
          "image": "nginx:alpine",
          "ports": [{"containerPort": 80}]
        }]
      }
    }
  }
}
EOF
                        
                        # 调用 API 创建 Deployment
                        curl -k --cacert $CA_CERT \
                             -H "Authorization: Bearer $TOKEN" \
                             -H "Content-Type: application/json" \
                             -X POST \
                             -d @deploy.json \
                             $APISERVER/apis/apps/v1/namespaces/default/deployments
                        
                        echo ""
                        echo "✅ Deployment 创建成功"
                        
                        # 创建 Service
                        cat > service.json << 'EOF'
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": "my-app-service"
  },
  "spec": {
    "type": "NodePort",
    "selector": {
      "app": "my-app"
    },
    "ports": [{
      "port": 80,
      "targetPort": 80,
      "nodePort": 30080
    }]
  }
}
EOF
                        
                        # 调用 API 创建 Service
                        curl -k --cacert $CA_CERT \
                             -H "Authorization: Bearer $TOKEN" \
                             -H "Content-Type: application/json" \
                             -X POST \
                             -d @service.json \
                             $APISERVER/api/v1/namespaces/default/services
                        
                        echo ""
                        echo "✅ Service 创建成功"
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
}