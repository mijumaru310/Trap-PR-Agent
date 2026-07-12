FROM python:3.11-slim

# コンテナ内で出力がバッファリングされないようにする
ENV PYTHONUNBUFFERED=True

# 作業ディレクトリの設定
WORKDIR /app

# 依存関係ファイルのコピーとインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションのコードをコピー
COPY . .

# Cloud Runなどの環境変数がPORTを指定している場合はそれを使用し、デフォルトは8000
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
