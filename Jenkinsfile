pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep"]
    args: ["3600"]
'''
            defaultContainer 'busybox'
        }
    }
    
    stages {
        stage('Test') {
            steps {
                sh 'echo "Pod 创建成功！2"'
                sh 'echo "主机名: $(hostname)"'
                sh 'echo "当前目录: $(pwd)"'
            }
        }
    }
}