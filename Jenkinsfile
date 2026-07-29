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
                sh '''
                    echo "=========================================="
                    echo "🚀 安装工具并部署"
                    echo "=========================================="
                    
                    # 安装 curl 和 jq
                    echo "安装 curl..."
                    apk add --no-cache curl jq
                    
                    # 获取 K8s API 信息
                    APISERVER=https://kubernetes.default.svc
                    TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                    CA_CERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                    NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
                    
                    echo "API Server: $APISERVER"
                    echo "Namespace: $NAMESPACE"
                    
                    # ========== 创建 Deployment ==========
                    echo ""
                    echo "创建 Deployment..."
                    
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
                    
                    # 先删除旧的（如果存在）
                    curl -k --cacert $CA_CERT \
                         -H "Authorization: Bearer $TOKEN" \
                         -H "Content-Type: application/json" \
                         -X DELETE \
                         $APISERVER/apis/apps/v1/namespaces/$NAMESPACE/deployments/my-app \
                         2>/dev/null || echo "Deployment 不存在，跳过删除"
                    
                    # 创建新的
                    curl -k --cacert $CA_CERT \
                         -H "Authorization: Bearer $TOKEN" \
                         -H "Content-Type: application/json" \
                         -X POST \
                         -d @deploy.json \
                         $APISERVER/apis/apps/v1/namespaces/$NAMESPACE/deployments
                    
                    echo ""
                    echo "✅ Deployment 创建成功"
                    
                    # ========== 创建 Service ==========
                    echo ""
                    echo "创建 Service..."
                    
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
                    
                    # 先删除旧的
                    curl -k --cacert $CA_CERT \
                         -H "Authorization: Bearer $TOKEN" \
                         -H "Content-Type: application/json" \
                         -X DELETE \
                         $APISERVER/api/v1/namespaces/$NAMESPACE/services/my-app-service \
                         2>/dev/null || echo "Service 不存在，跳过删除"
                    
                    # 创建新的
                    curl -k --cacert $CA_CERT \
                         -H "Authorization: Bearer $TOKEN" \
                         -H "Content-Type: application/json" \
                         -X POST \
                         -d @service.json \
                         $APISERVER/api/v1/namespaces/$NAMESPACE/services
                    
                    echo ""
                    echo "✅ Service 创建成功"
                    
                    # ========== 查看状态 ==========
                    echo ""
                    echo "查看部署状态..."
                    
                    curl -k --cacert $CA_CERT \
                         -H "Authorization: Bearer $TOKEN" \
                         $APISERVER/api/v1/namespaces/$NAMESPACE/pods?labelSelector=app=my-app \
                         | jq '.items[] | {name: .metadata.name, status: .status.phase}'
                    
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