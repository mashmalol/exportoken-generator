#!/bin/bash

set -e

APP_DIR="export-token-app"
WEB_ROOT="/var/www/export-token"
NGINX_CONF="/etc/nginx/sites-available/export-token"

# Detect server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "==> Creating app directory..."
mkdir -p "$APP_DIR"

# ── Write index.html ──────────────────────────────────────────────────────────
cat > "$APP_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>ERC-721 Export Token Metadata Generator</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #0d0d0d;
      color: #00ff88;
      font-family: 'Courier New', monospace;
      min-height: 100vh;
      overflow-x: hidden;
    }
    canvas#rain {
      position: fixed; top: 0; left: 0;
      width: 100%; height: 100%;
      z-index: 0; opacity: 0.18;
    }
    .container {
      position: relative; z-index: 1;
      max-width: 860px; margin: 40px auto;
      padding: 0 20px 60px;
    }
    h1 {
      text-align: center;
      font-size: 1.8rem;
      color: #00ffcc;
      text-shadow: 0 0 12px #00ffcc;
      margin-bottom: 8px;
    }
    .subtitle {
      text-align: center;
      color: #557;
      font-size: 0.85rem;
      margin-bottom: 36px;
    }
    .section {
      border: 1px solid #1a3a2a;
      border-radius: 8px;
      padding: 20px 24px;
      margin-bottom: 24px;
      background: rgba(0,20,12,0.75);
    }
    .section h2 {
      font-size: 0.95rem;
      color: #00ffaa;
      text-transform: uppercase;
      letter-spacing: 2px;
      margin-bottom: 16px;
      border-bottom: 1px solid #1a3a2a;
      padding-bottom: 8px;
    }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .full { grid-column: 1 / -1; }
    label {
      display: block;
      font-size: 0.78rem;
      color: #00cc77;
      margin-bottom: 4px;
      letter-spacing: 1px;
    }
    .required::after { content: " *"; color: #ff4444; }
    input, select, textarea {
      width: 100%;
      background: #050f09;
      border: 1px solid #1a4a2a;
      border-radius: 4px;
      color: #00ff88;
      font-family: 'Courier New', monospace;
      font-size: 0.88rem;
      padding: 8px 10px;
      outline: none;
      transition: border-color 0.2s;
    }
    input:focus, select:focus, textarea:focus {
      border-color: #00ff88;
      box-shadow: 0 0 6px rgba(0,255,136,0.2);
    }
    textarea { resize: vertical; min-height: 70px; }
    select option { background: #050f09; }
    .id-row { display: flex; gap: 8px; }
    .id-row input { flex: 1; }
    .btn-auto {
      background: #0a2a18;
      border: 1px solid #00ff88;
      color: #00ff88;
      font-family: 'Courier New', monospace;
      font-size: 0.78rem;
      padding: 8px 12px;
      border-radius: 4px;
      cursor: pointer;
      white-space: nowrap;
      transition: background 0.2s;
    }
    .btn-auto:hover { background: #0f3d22; }
    .actions { display: flex; gap: 12px; margin-top: 28px; }
    .btn {
      flex: 1;
      padding: 12px;
      border-radius: 6px;
      font-family: 'Courier New', monospace;
      font-size: 0.95rem;
      font-weight: bold;
      cursor: pointer;
      letter-spacing: 1px;
      border: none;
      transition: opacity 0.2s;
    }
    .btn:hover { opacity: 0.85; }
    .btn-generate { background: #00ff88; color: #050f09; }
    .btn-download { background: #00ccff; color: #050f09; display: none; }
    .btn-reset { background: #1a1a1a; color: #888; border: 1px solid #333; flex: 0 0 auto; padding: 12px 20px; }
    #preview {
      display: none;
      margin-top: 28px;
      background: #020a05;
      border: 1px solid #1a4a2a;
      border-radius: 8px;
      padding: 20px;
    }
    #preview h3 { color: #00ffcc; font-size: 0.85rem; letter-spacing: 2px; margin-bottom: 12px; }
    #preview pre {
      color: #00ff88;
      font-size: 0.8rem;
      white-space: pre-wrap;
      word-break: break-all;
      max-height: 420px;
      overflow-y: auto;
    }
    .error { border-color: #ff4444 !important; }
    .err-msg { color: #ff4444; font-size: 0.75rem; margin-top: 4px; }
  </style>
</head>
<body>
<canvas id="rain"></canvas>
<div class="container">
  <h1>⬡ ERC-721 Export Token</h1>
  <p class="subtitle">Metadata Generator — Trade & Customs</p>

  <form id="metaForm" novalidate>

    <!-- Token Identity -->
    <div class="section">
      <h2>Token Identity</h2>
      <div class="grid">
        <div class="full">
          <label class="required">Token Name</label>
          <input type="text" name="name" placeholder="e.g. Export Shipment #2024-001" required />
        </div>
        <div class="full">
          <label class="required">Token ID</label>
          <div class="id-row">
            <input type="text" name="token_id" placeholder="e.g. 100042" required />
            <button type="button" class="btn-auto" onclick="autoId()">Auto</button>
          </div>
        </div>
        <div class="full">
          <label>Description</label>
          <textarea name="description" placeholder="Brief description of this export token..."></textarea>
        </div>
      </div>
    </div>

    <!-- HS Code -->
    <div class="section">
      <h2>HS Code Classification</h2>
      <div class="grid">
        <div>
          <label class="required">HS Code</label>
          <input type="text" name="hs_code" placeholder="e.g. 8471.30" required />
        </div>
        <div>
          <label>Chapter</label>
          <input type="text" name="hs_chapter" placeholder="e.g. 84 – Machinery" />
        </div>
        <div>
          <label>Heading</label>
          <input type="text" name="hs_heading" placeholder="e.g. 8471 – Computers" />
        </div>
        <div>
          <label>Duty Rate</label>
          <input type="text" name="duty_rate" placeholder="e.g. 0% / 5%" />
        </div>
        <div class="full">
          <label>Commodity Description</label>
          <input type="text" name="commodity_desc" placeholder="e.g. Portable automatic data processing machines" />
        </div>
      </div>
    </div>

    <!-- Export Details -->
    <div class="section">
      <h2>Export Details</h2>
      <div class="grid">
        <div>
          <label class="required">Exporter Name</label>
          <input type="text" name="exporter_name" placeholder="Company or individual name" required />
        </div>
        <div>
          <label class="required">Exporter Country</label>
          <input type="text" name="exporter_country" placeholder="e.g. Germany" required />
        </div>
        <div>
          <label class="required">Destination Country</label>
          <input type="text" name="destination_country" placeholder="e.g. United States" required />
        </div>
        <div>
          <label>Incoterm</label>
          <select name="incoterm">
            <option value="">— Select —</option>
            <option>EXW</option><option>FCA</option><option>CPT</option>
            <option>CIP</option><option>DAP</option><option>DPU</option>
            <option>DDP</option><option>FAS</option><option>FOB</option>
            <option>CFR</option><option>CIF</option>
          </select>
        </div>
        <div>
          <label>Port of Loading</label>
          <input type="text" name="port_loading" placeholder="e.g. Hamburg" />
        </div>
        <div>
          <label>Port of Discharge</label>
          <input type="text" name="port_discharge" placeholder="e.g. New York" />
        </div>
      </div>
    </div>

    <!-- Shipment & Cargo -->
    <div class="section">
      <h2>Shipment &amp; Cargo</h2>
      <div class="grid">
        <div>
          <label>Quantity</label>
          <input type="number" name="quantity" placeholder="e.g. 500" min="0" />
        </div>
        <div>
          <label>Unit</label>
          <input type="text" name="unit" placeholder="e.g. PCS / KG / CBM" />
        </div>
        <div>
          <label>Gross Weight (kg)</label>
          <input type="number" name="gross_weight" placeholder="e.g. 1200" min="0" />
        </div>
        <div>
          <label>Invoice Value</label>
          <input type="number" name="invoice_value" placeholder="e.g. 45000" min="0" />
        </div>
        <div>
          <label>Currency</label>
          <select name="currency">
            <option value="">— Select —</option>
            <option>USD</option><option>EUR</option><option>GBP</option>
            <option>JPY</option><option>CNY</option><option>AED</option>
            <option>IRR</option><option>Other</option>
          </select>
        </div>
        <div>
          <label>Shipment Date</label>
          <input type="date" name="shipment_date" />
        </div>
        <div>
          <label>Transport Mode</label>
          <select name="transport_mode">
            <option value="">— Select —</option>
            <option>Sea</option><option>Air</option><option>Road</option>
            <option>Rail</option><option>Multimodal</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Document References -->
    <div class="section">
      <h2>Document References</h2>
      <div class="grid">
        <div>
          <label>Invoice Number</label>
          <input type="text" name="invoice_number" placeholder="e.g. INV-2024-0042" />
        </div>
        <div>
          <label>Bill of Lading / AWB</label>
          <input type="text" name="bl_awb" placeholder="e.g. MAEU123456789" />
        </div>
        <div class="full">
          <label>License / Permit Number</label>
          <input type="text" name="license_number" placeholder="e.g. EXP-LIC-2024-007" />
        </div>
      </div>
    </div>

    <!-- Agent Info -->
    <div class="section">
      <h2>Agent Info</h2>
      <div class="grid">
        <div>
          <label>Agent Name</label>
          <input type="text" name="agent_name" placeholder="Customs / freight agent name" />
        </div>
        <div>
          <label>Agent ID / Code</label>
          <input type="text" name="agent_id" placeholder="e.g. AGT-00123" />
        </div>
        <div class="full">
          <label>Agent Wallet (ETH Address)</label>
          <input type="text" name="agent_wallet" placeholder="0x..." />
        </div>
      </div>
    </div>

    <div class="actions">
      <button type="button" class="btn btn-generate" onclick="generate()">Generate JSON</button>
      <button type="button" class="btn btn-download" id="dlBtn" onclick="download()">Download .json</button>
      <button type="button" class="btn btn-reset" onclick="resetForm()">Reset</button>
    </div>
  </form>

  <div id="preview">
    <h3>// JSON PREVIEW</h3>
    <pre id="jsonOut"></pre>
  </div>
</div>

<script>
  // ── Digital Rain ─────────────────────────────────────────────────────────
  const canvas = document.getElementById('rain');
  const ctx = canvas.getContext('2d');
  let cols, drops;
  function initRain() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    cols = Math.floor(canvas.width / 16);
    drops = Array(cols).fill(1);
  }
  function drawRain() {
    ctx.fillStyle = 'rgba(0,0,0,0.05)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = '#00ff88';
    ctx.font = '14px monospace';
    drops.forEach((y, i) => {
      const ch = String.fromCharCode(0x30A0 + Math.random() * 96);
      ctx.fillText(ch, i * 16, y * 16);
      if (y * 16 > canvas.height && Math.random() > 0.975) drops[i] = 0;
      drops[i]++;
    });
  }
  initRain();
  window.addEventListener('resize', initRain);
  setInterval(drawRain, 50);

  // ── Helpers ───────────────────────────────────────────────────────────────
  function autoId() {
    document.querySelector('[name=token_id]').value =
      Math.floor(100000 + Math.random() * 900000);
  }

  let lastJson = '';

  function generate() {
    const form = document.getElementById('metaForm');
    const inputs = form.querySelectorAll('[required]');
    let valid = true;
    inputs.forEach(el => {
      el.classList.remove('error');
      const old = el.parentNode.querySelector('.err-msg');
      if (old) old.remove();
      if (!el.value.trim()) {
        el.classList.add('error');
        const msg = document.createElement('div');
        msg.className = 'err-msg';
        msg.textContent = 'Required';
        el.parentNode.appendChild(msg);
        valid = false;
      }
    });
    if (!valid) return;

    const d = Object.fromEntries(new FormData(form));

    const attrs = [
      { trait_type: 'HS Code',              value: d.hs_code },
      { trait_type: 'HS Chapter',           value: d.hs_chapter },
      { trait_type: 'HS Heading',           value: d.hs_heading },
      { trait_type: 'Commodity Description',value: d.commodity_desc },
      { trait_type: 'Duty Rate',            value: d.duty_rate },
      { trait_type: 'Exporter Name',        value: d.exporter_name },
      { trait_type: 'Exporter Country',     value: d.exporter_country },
      { trait_type: 'Destination Country',  value: d.destination_country },
      { trait_type: 'Incoterm',             value: d.incoterm },
      { trait_type: 'Port of Loading',      value: d.port_loading },
      { trait_type: 'Port of Discharge',    value: d.port_discharge },
      { trait_type: 'Quantity',             value: d.quantity },
      { trait_type: 'Unit',                 value: d.unit },
      { trait_type: 'Gross Weight (kg)',    value: d.gross_weight },
      { trait_type: 'Invoice Value',        value: d.invoice_value },
      { trait_type: 'Currency',             value: d.currency },
      { trait_type: 'Shipment Date',        value: d.shipment_date },
      { trait_type: 'Transport Mode',       value: d.transport_mode },
      { trait_type: 'Invoice Number',       value: d.invoice_number },
      { trait_type: 'Bill of Lading / AWB', value: d.bl_awb },
      { trait_type: 'License / Permit',     value: d.license_number },
      { trait_type: 'Agent Name',           value: d.agent_name },
      { trait_type: 'Agent ID',             value: d.agent_id },
      { trait_type: 'Agent Wallet',         value: d.agent_wallet },
    ].filter(a => a.value && a.value.trim() !== '');

    const meta = {
      name: d.name,
      token_id: d.token_id,
      description: d.description || '',
      image: 'ipfs://YOUR_IMAGE_CID_HERE',
      external_url: 'https://your-platform.com/token/' + d.token_id,
      attributes: attrs,
      metadata_standard: 'ERC-721',
      generated_at: new Date().toISOString()
    };

    lastJson = JSON.stringify(meta, null, 2);
    document.getElementById('jsonOut').textContent = lastJson;
    document.getElementById('preview').style.display = 'block';
    document.getElementById('dlBtn').style.display = 'inline-block';
  }

  function download() {
    if (!lastJson) return;
    const tid = document.querySelector('[name=token_id]').value || 'token';
    const blob = new Blob([lastJson], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'export-token-' + tid + '.json';
    a.click();
  }

  function resetForm() {
    document.getElementById('metaForm').reset();
    document.getElementById('preview').style.display = 'none';
    document.getElementById('dlBtn').style.display = 'none';
    document.querySelectorAll('.error').forEach(e => e.classList.remove('error'));
    document.querySelectorAll('.err-msg').forEach(e => e.remove());
    lastJson = '';
  }
</script>
</body>
</html>
HTMLEOF

echo "==> App files created at $APP_DIR/index.html"

# ── Nginx setup ───────────────────────────────────────────────────────────────
echo "==> Installing Nginx..."
sudo apt update -qq && sudo apt install -y nginx

echo "==> Copying files to web root..."
sudo mkdir -p "$WEB_ROOT"
sudo cp "$APP_DIR/index.html" "$WEB_ROOT/"
sudo chown -R www-data:www-data "$WEB_ROOT"

echo "==> Writing Nginx config..."
sudo tee "$NGINX_CONF" > /dev/null << NGINXEOF
server {
    listen 80;
    server_name $SERVER_IP;

    root $WEB_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINXEOF

echo "==> Enabling site..."
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/export-token
sudo nginx -t
sudo systemctl reload nginx

echo "==> Opening firewall for HTTP..."
sudo ufw allow 'Nginx HTTP' 2>/dev/null || true

echo ""
echo "============================================"
echo "  App is live at: http://$SERVER_IP"
echo "============================================"
