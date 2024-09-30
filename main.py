from flask import Flask, request, jsonify
import subprocess
import time
import os
import shlex
from logging import debug, info, warning, error, critical
app = Flask(__name__)

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')  # すべてのオリジンを許可
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')  # 許可するHTTPメソッド
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type')  # 許可するヘッダー
    return response
@app.route('/', methods=['GET'])
def index():
    return {'message': 'Hello, World!'}
@app.route('/execute', methods=['POST'])
def execute_code():
    data = request.json
    code = data.get('code')
    language = data.get('language')
    input_text = data.get('input', '')
    # コードファイルを作成
    code_filename = f"code.{language}"
    with open(code_filename, 'w') as f:
        f.write(code)

    # 実行環境に応じたコマンドを設定
    commands = {
        'cpp': f"g++ {code_filename} -o code && ./code",
        'java': f"javac {code_filename} && java Main",
        'pypy': f"pypy3 {code_filename}",
        'python': f"python {code_filename}"
    }

    if language not in commands:
        return jsonify({'status': 'IE', 'message': 'Unsupported language'}), 400

    command = commands[language]
    start_time = time.time()

    try:
        # 入力を標準入力として渡す
        process = subprocess.Popen(shlex.split(command), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, error = process.communicate(input=input_text.encode(), timeout=5)
        exit_code = process.returncode
        end_time = time.time()
        elapsed_time = f"{(end_time - start_time):.3f}"

        output = output.decode().strip()
        error = error.decode().strip()
        if error:
            return jsonify({'status': 'RE', 'exit_code': exit_code, 'message': error, 'elapsed_time': elapsed_time}), 200
        else:
            return jsonify({'status': 'OK', 'message': error, 'output': output, 'elapsed_time': elapsed_time}), 200
    except Exception as e:
        return jsonify({'status': 'IE', 'message': str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
