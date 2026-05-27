from flask import Flask
import time

app = Flask(__name__)


requests_count = 0
start_time = time.time()

@app.before_request()
def requests_counter():
    global requests_count
    requests_count += 1

# Home route
@app.route('/', methods=['GET'])
def home():
    return {
        "Project": "infrastructure operations lab"
        }, 200

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return {
        "status": "healthy"
        }, 200

# Version endpoint
@app.route('/version', methods=['GET'])
def version():
    return {
        "version": "1.0.0"
        }, 200

# Metric endpoint
@app.route('/metrics', methods=['GET'])
def metric():
    up_time = int(time.time() - start_time)
    return {
        "requests": requests_count, 
        "uptime": up_time
        }, 200

