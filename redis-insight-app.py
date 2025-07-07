from flask import Flask, render_template_string, request, jsonify
import redis
import json

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Redis Insight - RDI Training</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { background: #dc382d; color: white; padding: 15px; margin: -20px -20px 20px -20px; border-radius: 8px 8px 0 0; }
        .form-group { margin: 15px 0; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input, textarea { width: 100%; padding: 10px; margin: 5px 0; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
        button { padding: 10px 20px; background: #dc382d; color: white; border: none; cursor: pointer; border-radius: 4px; margin-right: 10px; }
        button:hover { background: #c23321; }
        .result { background: #f8f9fa; padding: 15px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #dc382d; font-family: monospace; white-space: pre-wrap; }
        .success { border-left-color: #28a745; }
        .error { border-left-color: #dc3545; background: #f8d7da; }
        .commands { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 15px 0; }
        .cmd-btn { background: #6c757d; padding: 8px 12px; font-size: 12px; }
        .cmd-btn:hover { background: #5a6268; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Redis Insight - RDI Training Environment</h1>
            <p>Connect to your Redis Cloud instance and explore data</p>
        </div>
        
        <div class="form-group">
            <label>Redis Connection String:</label>
            <input type="text" id="redis-url" placeholder="redis://default:password@host:port" value="redis://localhost:6379">
            <button onclick="testConnection()">🔗 Test Connection</button>
            <button onclick="getInfo()">ℹ️ Redis Info</button>
        </div>
        
        <div class="form-group">
            <label>Quick Commands:</label>
            <div class="commands">
                <button class="cmd-btn" onclick="setCommand('KEYS *')">List All Keys</button>
                <button class="cmd-btn" onclick="setCommand('INFO')">Redis Info</button>
                <button class="cmd-btn" onclick="setCommand('DBSIZE')">Database Size</button>
                <button class="cmd-btn" onclick="setCommand('MEMORY USAGE')">Memory Usage</button>
                <button class="cmd-btn" onclick="setCommand('CLIENT LIST')">Client List</button>
                <button class="cmd-btn" onclick="setCommand('CONFIG GET *')">Configuration</button>
            </div>
        </div>
        
        <div class="form-group">
            <label>Redis Command:</label>
            <input type="text" id="redis-cmd" placeholder="e.g., KEYS *, GET key, HGETALL key, SCAN 0">
            <button onclick="executeCommand()">▶️ Execute</button>
            <button onclick="clearResult()">🗑️ Clear</button>
        </div>
        
        <div id="result" class="result" style="display: none;"></div>
        
        <div class="form-group">
            <h3>Common RDI Commands:</h3>
            <ul>
                <li><code>KEYS rdi:*</code> - List RDI-related keys</li>
                <li><code>HGETALL track:1</code> - Get track data</li>
                <li><code>SCAN 0 MATCH track:*</code> - Scan for track keys</li>
                <li><code>XLEN rdi:stream</code> - Check stream length</li>
                <li><code>MONITOR</code> - Monitor Redis commands (use with caution)</li>
            </ul>
        </div>
    </div>
    
    <script>
        function setCommand(cmd) {
            document.getElementById('redis-cmd').value = cmd;
        }
        
        function testConnection() {
            const url = document.getElementById('redis-url').value;
            showResult('Testing connection...', 'info');
            fetch('/test', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({url: url})
            })
            .then(r => r.json())
            .then(data => {
                if (data.status === 'success') {
                    showResult('✅ ' + data.message, 'success');
                } else {
                    showResult('❌ ' + data.message, 'error');
                }
            })
            .catch(err => showResult('❌ Network error: ' + err, 'error'));
        }
        
        function getInfo() {
            setCommand('INFO');
            executeCommand();
        }
        
        function executeCommand() {
            const url = document.getElementById('redis-url').value;
            const cmd = document.getElementById('redis-cmd').value;
            if (!cmd.trim()) {
                showResult('❌ Please enter a command', 'error');
                return;
            }
            
            showResult('Executing: ' + cmd, 'info');
            fetch('/execute', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({url: url, command: cmd})
            })
            .then(r => r.json())
            .then(data => {
                if (data.status === 'success') {
                    showResult('✅ Result:\\n' + JSON.stringify(data.result, null, 2), 'success');
                } else {
                    showResult('❌ Error: ' + data.message, 'error');
                }
            })
            .catch(err => showResult('❌ Network error: ' + err, 'error'));
        }
        
        function clearResult() {
            document.getElementById('result').style.display = 'none';
        }
        
        function showResult(text, type) {
            const resultDiv = document.getElementById('result');
            resultDiv.textContent = text;
            resultDiv.className = 'result ' + type;
            resultDiv.style.display = 'block';
        }
    </script>
</body>
</html>
"""

@app.route("/")
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route("/test", methods=["POST"])
def test_connection():
    try:
        data = request.json
        r = redis.from_url(data["url"])
        r.ping()
        info = r.info()
        return {
            "status": "success", 
            "message": f"Connected to Redis {info.get('redis_version', 'unknown')} - {info.get('used_memory_human', 'unknown')} used"
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.route("/execute", methods=["POST"])
def execute_command():
    try:
        data = request.json
        r = redis.from_url(data["url"])
        cmd_parts = data["command"].strip().split()
        if not cmd_parts:
            return {"status": "error", "message": "Empty command"}
        
        cmd = cmd_parts[0].upper()
        args = cmd_parts[1:] if len(cmd_parts) > 1 else []
        
        # Handle special commands
        if cmd == "KEYS":
            result = r.keys(args[0] if args else "*")
            result = [key.decode() if isinstance(key, bytes) else key for key in result]
        elif cmd == "SCAN":
            cursor = int(args[0]) if args else 0
            match_pattern = None
            if len(args) >= 3 and args[1].upper() == "MATCH":
                match_pattern = args[2]
            result = r.scan(cursor, match=match_pattern)
        else:
            result = r.execute_command(cmd, *args)
            
        # Convert bytes to strings for JSON serialization
        if isinstance(result, bytes):
            result = result.decode()
        elif isinstance(result, list):
            result = [item.decode() if isinstance(item, bytes) else item for item in result]
        elif isinstance(result, dict):
            result = {k.decode() if isinstance(k, bytes) else k: 
                     v.decode() if isinstance(v, bytes) else v for k, v in result.items()}
            
        return {"status": "success", "result": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    print("🔍 Redis Insight starting on http://0.0.0.0:5540")
    app.run(host="0.0.0.0", port=5540, debug=False)
