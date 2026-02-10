docker pull jenkins/jenkins:2.387.2

docker run -p 8180:8080 -p 5000:5000 --name jenkins \
-u root \
-v /mydata/jenkins_home:/var/jenkins_home \
-d jenkins/jenkins:lts

ssh -L 8180:127.0.0.1:8180 yaolu@10.15.32.90
