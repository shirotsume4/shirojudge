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

# 依存ライブラリのインストール poetry
RUN pip install poetry
RUN poetry config virtualenvs.create false
RUN poetry install --no-dev

# アプリケーションの起動
CMD ["python", "main.py"]
