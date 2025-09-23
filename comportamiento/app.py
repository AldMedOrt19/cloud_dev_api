from flask import Flask, request, jsonify
import os, json, urllib.request, urllib.parse

app = Flask(__name__)

CLIMA_BASE   = os.getenv("CLIMA_API_BASE",   "https://httpbin.org/anything/clima")
TEMBLOR_BASE = os.getenv("TEMBLOR_API_BASE", "https://httpbin.org/anything/temblor")

def http_get(url: str, params: dict):
    qs = urllib.parse.urlencode(params)
    with urllib.request.urlopen(f"{url}?{qs}", timeout=6) as r:
        return json.loads(r.read().decode())

@app.get("/comportamiento")
def comportamiento():
    city = (request.args.get("city") or "Lima").title()
    date = request.args.get("date") or "2025-09-23"

    try:
        clima = http_get(CLIMA_BASE,   {"city": city, "date": date})
    except Exception:
        clima = {"temperature": 25, "humidity": 0.6}

    try:
        temblor = http_get(TEMBLOR_BASE, {"city": city, "date": date})
    except Exception:
        temblor = {"riskIndex": 0.2}

    temp = float(clima.get("temperature", 25))
    risk = float(temblor.get("riskIndex", 0))

    behaviour = "soleado" if temp > 24 else "templado"
    if risk >= 0.5:
        behaviour += "-con-riesgo-sismico"

    return jsonify({
        "city": city,
        "date": date,
        "behaviour": behaviour,
        "inputs": {"clima": clima, "temblor": temblor}
    })

@app.get("/health")
def health():
    return jsonify({"status": "ok"})