from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({"message": "User application is running!"})

@app.route("/status")
def status():
    return jsonify({"status": "ok", "description": "Flask app is healthy!"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
