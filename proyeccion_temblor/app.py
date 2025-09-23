from flask import Flask, request, jsonify
import hashlib

app = Flask(__name__)

def pseudo_random_01(seed: str) -> float:
    h = hashlib.sha256(seed.encode()).hexdigest()
    return int(h[:8], 16) / 0xFFFFFFFF  # 0..1

@app.get("/temblor")
def temblor():
    city = (request.args.get("city") or "Lima").title()
    date = request.args.get("date") or "2025-09-23"

    r = pseudo_random_01(f"{city}-{date}-sismo")
    risk_index = round(r, 2)  # 0..1

    return jsonify({
        "city": city,
        "date": date,
        "riskIndex": risk_index
    })

@app.get("/health")
def health():
    return jsonify({"status": "ok"})