pipeline {
    agent any // 在任何可用的节点上运行

    stages {
        stage('Checkout') {
            steps {
                // 从 Git 拉取代码
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                // 构建 Docker 镜像，使用构建号作为标签
                sh "docker build -t microblog:${env.BUILD_NUMBER} ."
            }
        }

        stage('Clean Old Container') {
            steps {
                // 停止并删除旧容器（如果存在），忽略报错
                sh "docker stop microblog || true && docker rm microblog || true"
            }
        }

        stage('Deploy') {
            steps {
                // 启动新容器
                sh "docker run -d --name microblog -p 8000:5000 microblog:${env.BUILD_NUMBER}"
            }
        }
    }
}
