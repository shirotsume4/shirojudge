# Pythonのベースイメージを使用
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

# 必要なパッケージのインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    g++ \
    default-jdk \
    pypy3 \
    wget \
    bzip2 &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# 作業ディレクトリの設定
WORKDIR /app

# アプリケーションコードをコピー
COPY . /app

# 依存ライブラリのインストール poetry
RUN pip install poetry
RUN poetry config virtualenvs.create false
RUN poetry install --no-dev

# アプリケーションの起動
CMD ["python", "main.py"]
