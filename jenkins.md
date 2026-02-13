docker pull jenkins/jenkins:2.387.2

docker run -p 8080:8080 -p 50000:50000 --name jenkins \
  -u root \
  -v /mydata/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -d jenkins_with_docker

ssh -L 8180:127.0.0.1:8180 yaolu@10.15.32.90
