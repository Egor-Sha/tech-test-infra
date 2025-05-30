import os
from flask import Flask
from datetime import datetime

app = Flask(__name__)

@app.route('/clock')
def clock():
    now = datetime.now()
    return str(int(now.timestamp()))

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8000))
    app.run(host='0.0.0.0', port=port)