# service-wrapper/server.py
import os
from flask import Flask, request, jsonify
import subprocess

if os.getenv("SENTRY_DSN"):
    import sentry_sdk
    sentry_sdk.init(
        dsn=os.getenv("SENTRY_DSN"),
        traces_sample_rate=1.0,
        profiles_sample_rate=1.0,
    )

app = Flask(os.getenv("SERVICE_NAME", "generic-service"))

@app.post("/process")
def process():
    try:
        params = request.get_json()
        result = subprocess.run(
            [os.getenv("SERVICE_PROGRAM"), params["in_path"], "-o", params["out_path"]],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            return jsonify({"status": "success", "output": result.stdout})
        else:
            return jsonify({"status": "error", "error": result.stderr}), 500
    except Exception as e:
        if os.getenv("SENTRY_DSN"):
            sentry_sdk.capture_exception(e)
        return jsonify({"status": "error", "error": str(e)}), 500

if __name__ == "__main__":
    port = int(os.getenv("SERVICE_PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
