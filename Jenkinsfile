pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.9-alpine
    command: ["sleep"]
    args: ["3600"]
'''
            defaultContainer 'python'
        }
    }
    
    stages {
        stage('Deploy to K8s') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "🚀 使用 Python 调用 K8s API"
                    echo "=========================================="
                    
                    # 安装 kubernetes 客户端
                    pip install kubernetes
                    
                    # 创建 Python 部署脚本
                    cat > deploy.py << 'EOF'
import os
import kubernetes
import kubernetes.client
from kubernetes.client.rest import ApiException

# 加载集群内配置
kubernetes.config.load_incluster_config()

# 创建 API 客户端
apps_v1 = kubernetes.client.AppsV1Api()
core_v1 = kubernetes.client.CoreV1Api()
namespace = open('/var/run/secrets/kubernetes.io/serviceaccount/namespace').read()

# 创建 Deployment
deployment = kubernetes.client.V1Deployment(
    metadata=kubernetes.client.V1ObjectMeta(name="my-app", labels={"app": "my-app"}),
    spec=kubernetes.client.V1DeploymentSpec(
        replicas=1,
        selector=kubernetes.client.V1LabelSelector(match_labels={"app": "my-app"}),
        template=kubernetes.client.V1PodTemplateSpec(
            metadata=kubernetes.client.V1ObjectMeta(labels={"app": "my-app"}),
            spec=kubernetes.client.V1PodSpec(
                containers=[
                    kubernetes.client.V1Container(
                        name="nginx",
                        image="nginx:alpine",
                        ports=[kubernetes.client.V1ContainerPort(container_port=80)]
                    )
                ]
            )
        )
    )
)

try:
    apps_v1.delete_namespaced_deployment(name="my-app", namespace=namespace)
    print("Deleted old Deployment")
except ApiException as e:
    if e.status != 404:
        print(f"Error: {e}")

apps_v1.create_namespaced_deployment(namespace=namespace, body=deployment)
print("✅ Deployment created")

# 创建 Service
service = kubernetes.client.V1Service(
    metadata=kubernetes.client.V1ObjectMeta(name="my-app-service"),
    spec=kubernetes.client.V1ServiceSpec(
        type="NodePort",
        selector={"app": "my-app"},
        ports=[kubernetes.client.V1ServicePort(port=80, target_port=80, node_port=30080)]
    )
)

try:
    core_v1.delete_namespaced_service(name="my-app-service", namespace=namespace)
    print("Deleted old Service")
except ApiException as e:
    if e.status != 404:
        print(f"Error: {e}")

core_v1.create_namespaced_service(namespace=namespace, body=service)
print("✅ Service created")

# 获取 Pod 状态
pods = core_v1.list_namespaced_pod(namespace=namespace, label_selector="app=my-app")
for pod in pods.items:
    print(f"Pod: {pod.metadata.name} - Status: {pod.status.phase}")
EOF
                    
                    # 执行 Python 脚本
                    python deploy.py
                    
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