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
    command:
    - /bin/sh
    - -c
    - |
      echo "Container started"
      while true; do sleep 30; done
'''
            defaultContainer 'kubectl'
        }
    }
    
    stages {
        stage('Deploy') {
            steps {
                // 使用 shell 脚本直接执行
                sh '''
                    echo "===== 在容器中执行 ====="
                    
                    # 检查进程
                    ps aux
                    
                    # 检查 kubectl
                    which kubectl
                    
                    # 简单命令测试
                    echo "测试 kubectl..."
                    kubectl version --client
                    
                    # 部署（如果集群不可达，会输出错误但不会卡住）
                    kubectl create deployment my-app --image=nginx:alpine --dry-run=client -o yaml > deploy.yaml
                    cat deploy.yaml
                    
                    echo "===== 完成 ====="
                '''
            }
        }
    }
}