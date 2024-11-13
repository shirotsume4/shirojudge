# Pythonのベースイメージを使用
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV SUPPRESS_WARNINGS=true

# 必要なパッケージのインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    python3-distutils \
    ca-certificates \
    g++ \
    default-jdk \
    pypy3 \
    wget \
    bzip2 \
    libboost-all-dev \
    libgmp-dev \
    libeigen3-dev \
    git \
    make \
    build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# bits/stdc++.hをプリコンパイル
RUN mkdir -p /usr/local/include/bits && \
    echo '#include <bits/stdc++.h>' > temp.cpp && \
    g++ -std=c++17 -O2 -x c++-header temp.cpp -o /usr/local/include/bits/stdc++.gch && \
    rm temp.cpp

# AC Libraryのインストール
RUN git clone https://github.com/atcoder/ac-library.git /ac-library && \
    cp -r /ac-library/atcoder /usr/local/include/

# AC Libraryのヘッダーファイルをコピー
RUN mkdir -p /usr/local/include/atcoder && \
    cp -r /ac-library/atcoder/* /usr/local/include/atcoder

# 個別にプリコンパイル
RUN find /usr/local/include/atcoder -name '*.h' -exec g++ -std=c++17 -O2 -x c++-header {} -o {}.gch \;

# ヘッダーファイルを1つにまとめる
RUN find /usr/local/include/atcoder -name '*.h' -exec cat {} \; > /usr/local/include/atcoder/all.h

# まとめたファイルをプリコンパイル
RUN g++ -std=c++17 -O2 -x c++-header /usr/local/include/atcoder/all.h -o /usr/local/include/atcoder/all.h.gch


# 作業ディレクトリの設定
WORKDIR /app

# アプリケーションコードをコピー
COPY . /app

# 共通の仮想環境を作成し、poetryでパッケージをインストール
RUN apt-get update && apt-get install -y python3-pip python3-venv gfortran && \
    python3 -m venv /shared_env && \
    . /shared_env/bin/activate && \
    pip install --upgrade pip && \
    pip install poetry && \
    poetry config virtualenvs.in-project true && \
    poetry install --no-dev

# 環境変数を設定して、共通仮想環境のパスを指定
ENV PYTHONPATH=/shared_env/lib/python3.11/site-packages

# pythonとpypy3コマンドが共通の仮想環境を使うようにシンボリックリンクを設定
RUN rm -f /usr/bin/python /usr/bin/pypy3 && \
    ln -s /shared_env/bin/python3 /usr/bin/python && \
    ln -s /shared_env/bin/pypy3 /usr/bin/pypy3

# アプリケーションの起動
CMD ["python", "main.py"]
