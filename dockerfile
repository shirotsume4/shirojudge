# Pythonのベースイメージを使用
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV SUPPRESS_WARNINGS=true
# 必要なパッケージのインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    g++ \
    default-jdk \
    pypy3 \
    wget \
    bzip2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/include/x86_64-linux-gnu/c++/12/bits


# 作業ディレクトリの設定
WORKDIR /app
COPY --from=build /app /app

# オプション：uvを実行時に使用したい場合はインストール
RUN . /app/.venv/bin/activate && \
    pip install uv

# アプリケーションポートの公開
EXPOSE 8080

# アプリケーションをPythonで実行
CMD ["/app/.venv/bin/python", "main.py"]
