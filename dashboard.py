from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import platform
from datetime import datetime, timezone

HTML = """<!doctype html><html lang="tr"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Netizen Dev Dashboard</title><style>
:root{font-family:system-ui,Arial,sans-serif;color:#fff;background:#03152d}body{margin:0;padding:24px;max-width:900px;margin:auto}header{border-bottom:1px solid #174568;padding-bottom:20px}h1{font-size:clamp(28px,6vw,48px);margin:10px 0}small{color:#afc2d7}.accent{color:#ff304a}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;margin-top:28px}.card{background:#071d38;border:1px solid #174568;border-radius:16px;padding:22px}.value{font-size:24px;font-weight:700;overflow-wrap:anywhere}button{background:#ff304a;color:white;border:0;border-radius:9px;padding:12px 18px;cursor:pointer}#status{color:#ffd02a}</style>
<header><small>NETIZEN / DEVELOPMENT</small><h1>Dev <span class="accent">Dashboard</span></h1><p>iPad ve iPhone için ilk geliştirme testi.</p></header>
<div class="grid"><section class="card"><small>API durumu</small><p class="value" id="status">Kontrol ediliyor…</p></section><section class="card"><small>Python sürümü</small><p class="value" id="python">—</p></section><section class="card"><small>Sunucu zamanı (UTC)</small><p class="value" id="time">—</p></section></div><p><button onclick="refresh()">Yenile</button></p>
<script>async function refresh(){try{const r=await fetch('/api/status');if(!r.ok)throw Error(r.status);const d=await r.json();document.getElementById('status').textContent=d.status;document.getElementById('python').textContent=d.python;document.getElementById('time').textContent=d.time;}catch(e){document.getElementById('status').textContent='Bağlantı hatası';}}refresh();</script></html>"""

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/status":
            data = json.dumps({"status": "Çalışıyor", "python": platform.python_version(), "time": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")}, ensure_ascii=False).encode()
            content_type = "application/json; charset=utf-8"
        elif self.path == "/":
            data = HTML.encode()
            content_type = "text/html; charset=utf-8"
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

if __name__ == "__main__":
    print("Netizen Dev Dashboard: http://localhost:8000", flush=True)
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
