from flask import Flask, request, jsonify
import hashlib

app = Flask(__name__)

def pseudo_random_01(seed: str) -> float:
    h = hashlib.sha256(seed.encode()).hexdigest()
    return int(h[:8], 16) / 0xFFFFFFFF  # 0..1

@app.get("/clima")
def clima():
    city = (request.args.get("city") or "Lima").title()
    date = request.args.get("date") or "2025-09-23"

    r = pseudo_random_01(f"{city}-{date}")
    temperature = round(18 + r * 14, 1)     # 18..32 °C aprox.
    humidity    = round(0.40 + r * 0.50, 2) # 0.40..0.90

    return jsonify({
        "city": city,
        "date": date,
        "temperature": temperature,
        "humidity": humidity
    })

@app.get("/health")
def health():
    return jsonify({"status": "ok"})