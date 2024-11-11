# Pythonのバージョンを指定
ARG PYTHON_VERSION="3.12.5"

# バージョン番号から短縮バージョンを設定（例えば "3.12"）
ARG PYTHON_SHORT_VERSION="3.12"

# uvの公式Dockerイメージを利用
FROM ghcr.io/astral-sh/uv:python${PYTHON_SHORT_VERSION}-bookworm-slim AS build

# 環境変数の設定
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=python${PYTHON_SHORT_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    SUPPRESS_WARNINGS=true

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
    rm -rf /var/lib/apt/lists/* /usr/include/x86_64-linux-gnu/c++/12/bits

# 作業ディレクトリの設定
WORKDIR /app

# アプリケーションコードのコピー
COPY . /app

# キャッシュを使いながら仮想環境を作成し、依存関係を同期
RUN uv venv /app/.venv && \
    set -ex && \
    cd /app && \
    uv sync --frozen --no-install-project

# Pythonのslimイメージで最終ステージの設定
FROM python:${PYTHON_VERSION}-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH

# 作業ディレクトリの設定およびファイルのコピー
WORKDIR /app
COPY --from=build /app /app

# オプション：uvを実行時に使用したい場合はインストール
RUN . /app/.venv/bin/activate && \
    pip install uv

# アプリケーションポートの公開
EXPOSE 8080

# アプリケーションをPythonで実行
CMD ["/app/.venv/bin/python", "main.py"]
