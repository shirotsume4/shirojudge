from flask import Flask, request, jsonify
import subprocess
import time
import os
import shlex

app = Flask(__name__)
@app.route('/', methods=['GET'])
def index():
    return {'message': 'Hello, World!'}
@app.route('/execute', methods=['GET'])
def execute_code():
    data = request.json
    code = data.get('code')
    language = data.get('language')
    input_text = data.get('input', '')
    expected_output = data.get('expected_output', '')
    time_limit = data.get('time_limit', 2)

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
        output, error = process.communicate(input=input_text.encode(), timeout=time_limit)

        end_time = time.time()
        elapsed_time = end_time - start_time
        elapsed_time_ms = int(elapsed_time * 1000)

        if elapsed_time >= time_limit:
            return jsonify({'status': 'TLE', 'output': '', 'elapsed_time': elapsed_time_ms})

        output = output.decode().strip()
        error = error.decode().strip()

        # コードの実行結果と期待される出力を比較
        #末尾の空白や改行は無視して比較
        match = output.rstrip() == expected_output.rstrip()

        return jsonify({
            'status': 'RE' if process.returncode != 0 else 'AC' if match else 'WA',
            'output': output,
            'elapsed_time': elapsed_time_ms,
        })

    except subprocess.TimeoutExpired:
        return jsonify({'status': 'time_limit_exceeded', 'output': '', 'match': False})
    except Exception as e:
        return jsonify({'status': 'error', 'output': str(e), 'match': False})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
