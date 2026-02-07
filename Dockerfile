# 建议指定具体版本，避免以后 python:slim 更新导致项目崩溃
FROM python:3.11-slim

# 设置工作目录，避免文件散落在根目录
WORKDIR /home/microblog

# 1. 安装系统级依赖 (解决编译和加密库问题)
# gcc 和 musl-dev/libc-dev 是编译 C 扩展必须的
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. 处理依赖 (利用 Docker 缓存)
COPY requirements.txt requirements.txt
# 既然你在英国，不需要换源；增加超时设置防止偶发断网
RUN pip install --no-cache-dir --default-timeout=100 -r requirements.txt
RUN pip install --no-cache-dir gunicorn pymysql cryptography

# 3. 复制项目文件
COPY app app
COPY migrations migrations
COPY microblog.py config.py boot.sh ./
RUN chmod +x boot.sh

# 4. 环境配置
ENV FLASK_APP microblog.py

# 编译翻译文件（如果报错，请确保你已经安装了 Babel）
RUN flask translate compile

EXPOSE 5000
ENTRYPOINT ["./boot.sh"]

##docker build -t microblog:latest .
#docker run --name microblog -d -p 8000:5000 --rm microblog:latest
