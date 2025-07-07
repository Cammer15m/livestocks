# Simple SQLPad alternative without external dependencies
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install flask psycopg2-binary

# Create sqlpad user
RUN useradd -m -s /bin/bash sqlpad

WORKDIR /app

# Create simple SQL interface
RUN echo 'from flask import Flask, render_template_string, request, jsonify\n\
import psycopg2\n\
import json\n\
\n\
app = Flask(__name__)\n\
\n\
HTML_TEMPLATE = """\n\
<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>SQLPad - PostgreSQL Browser</title>\n\
    <style>\n\
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }\n\
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }\n\
        .header { background: #007bff; color: white; padding: 15px; margin: -20px -20px 20px -20px; border-radius: 8px 8px 0 0; }\n\
        .form-group { margin: 15px 0; }\n\
        label { display: block; margin-bottom: 5px; font-weight: bold; }\n\
        input, textarea { width: 100%; padding: 10px; margin: 5px 0; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }\n\
        textarea { height: 120px; font-family: monospace; }\n\
        button { padding: 10px 20px; background: #007bff; color: white; border: none; cursor: pointer; border-radius: 4px; margin-right: 10px; }\n\
        button:hover { background: #0056b3; }\n\
        .result { background: #f8f9fa; padding: 15px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #007bff; }\n\
        .error { border-left-color: #dc3545; background: #f8d7da; }\n\
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }\n\
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }\n\
        th { background-color: #f2f2f2; }\n\
        .queries { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 10px; margin: 15px 0; }\n\
        .query-btn { background: #6c757d; padding: 8px 12px; font-size: 12px; }\n\
        .query-btn:hover { background: #5a6268; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="header">\n\
            <h1>🗄️ SQLPad - PostgreSQL Browser</h1>\n\
            <p>Browse and query your PostgreSQL database</p>\n\
        </div>\n\
        \n\
        <div class="form-group">\n\
            <label>Database Connection:</label>\n\
            <input type="text" id="db-url" value="postgresql://postgres:postgres@postgresql:5432/chinook" readonly>\n\
            <button onclick="testConnection()">🔗 Test Connection</button>\n\
            <button onclick="showTables()">📋 Show Tables</button>\n\
        </div>\n\
        \n\
        <div class="form-group">\n\
            <label>Quick Queries:</label>\n\
            <div class="queries">\n\
                <button class="query-btn" onclick="setQuery(\\\"SELECT * FROM track LIMIT 10;\\\")">Sample Tracks</button>\n\
                <button class="query-btn" onclick="setQuery(\\\"SELECT * FROM album LIMIT 10;\\\")">Sample Albums</button>\n\
                <button class="query-btn" onclick="setQuery(\\\"SELECT * FROM artist LIMIT 10;\\\")">Sample Artists</button>\n\
                <button class="query-btn" onclick="setQuery(\\\"SELECT COUNT(*) FROM track;\\\")">Track Count</button>\n\
                <button class="query-btn" onclick="setQuery(\\\"SHOW TABLES;\\\")">List Tables</button>\n\
                <button class="query-btn" onclick="setQuery(\\\"SELECT table_name FROM information_schema.tables WHERE table_schema = \\\\\\\"public\\\\\\\";\\\")">Table Info</button>\n\
            </div>\n\
        </div>\n\
        \n\
        <div class="form-group">\n\
            <label>SQL Query:</label>\n\
            <textarea id="sql-query" placeholder="Enter your SQL query here...">SELECT * FROM track LIMIT 10;</textarea>\n\
            <button onclick="executeQuery()">▶️ Execute Query</button>\n\
            <button onclick="clearResult()">🗑️ Clear</button>\n\
        </div>\n\
        \n\
        <div id="result" class="result" style="display: none;"></div>\n\
    </div>\n\
    \n\
    <script>\n\
        function setQuery(query) {\n\
            document.getElementById(\\\"sql-query\\\").value = query;\n\
        }\n\
        \n\
        function testConnection() {\n\
            showResult(\\\"Testing database connection...\\\", false);\n\
            fetch(\\\"/test\\\", {\n\
                method: \\\"POST\\\",\n\
                headers: {\\\"Content-Type\\\": \\\"application/json\\\"}\n\
            })\n\
            .then(r => r.json())\n\
            .then(data => {\n\
                if (data.status === \\\"success\\\") {\n\
                    showResult(\\\"✅ \\\" + data.message, false);\n\
                } else {\n\
                    showResult(\\\"❌ \\\" + data.message, true);\n\
                }\n\
            })\n\
            .catch(err => showResult(\\\"❌ Network error: \\\" + err, true));\n\
        }\n\
        \n\
        function showTables() {\n\
            setQuery(\\\"SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = \\\\\\\"public\\\\\\\" ORDER BY table_name;\\\");\n\
            executeQuery();\n\
        }\n\
        \n\
        function executeQuery() {\n\
            const query = document.getElementById(\\\"sql-query\\\").value;\n\
            if (!query.trim()) {\n\
                showResult(\\\"❌ Please enter a SQL query\\\", true);\n\
                return;\n\
            }\n\
            \n\
            showResult(\\\"Executing query...\\\", false);\n\
            fetch(\\\"/execute\\\", {\n\
                method: \\\"POST\\\",\n\
                headers: {\\\"Content-Type\\\": \\\"application/json\\\"},\n\
                body: JSON.stringify({query: query})\n\
            })\n\
            .then(r => r.json())\n\
            .then(data => {\n\
                if (data.status === \\\"success\\\") {\n\
                    displayResults(data.results, data.columns);\n\
                } else {\n\
                    showResult(\\\"❌ Error: \\\" + data.message, true);\n\
                }\n\
            })\n\
            .catch(err => showResult(\\\"❌ Network error: \\\" + err, true));\n\
        }\n\
        \n\
        function displayResults(results, columns) {\n\
            if (!results || results.length === 0) {\n\
                showResult(\\\"✅ Query executed successfully. No results returned.\\\", false);\n\
                return;\n\
            }\n\
            \n\
            let html = \\\"<h3>Query Results (\\\" + results.length + \\\" rows)</h3>\\\";\n\
            html += \\\"<table><thead><tr>\\\";\n\
            \n\
            columns.forEach(col => {\n\
                html += \\\"<th>\\\" + col + \\\"</th>\\\";\n\
            });\n\
            \n\
            html += \\\"</tr></thead><tbody>\\\";\n\
            \n\
            results.forEach(row => {\n\
                html += \\\"<tr>\\\";\n\
                row.forEach(cell => {\n\
                    html += \\\"<td>\\\" + (cell !== null ? cell : \\\"NULL\\\") + \\\"</td>\\\";\n\
                });\n\
                html += \\\"</tr>\\\";\n\
            });\n\
            \n\
            html += \\\"</tbody></table>\\\";\n\
            \n\
            const resultDiv = document.getElementById(\\\"result\\\");\n\
            resultDiv.innerHTML = html;\n\
            resultDiv.className = \\\"result\\\";\n\
            resultDiv.style.display = \\\"block\\\";\n\
        }\n\
        \n\
        function clearResult() {\n\
            document.getElementById(\\\"result\\\").style.display = \\\"none\\\";\n\
        }\n\
        \n\
        function showResult(text, isError) {\n\
            const resultDiv = document.getElementById(\\\"result\\\");\n\
            resultDiv.innerHTML = text;\n\
            resultDiv.className = \\\"result\\\" + (isError ? \\\" error\\\" : \\\"\\\");\n\
            resultDiv.style.display = \\\"block\\\";\n\
        }\n\
    </script>\n\
</body>\n\
</html>\n\
"""\n\
\n\
@app.route("/")\n\
def index():\n\
    return render_template_string(HTML_TEMPLATE)\n\
\n\
@app.route("/test", methods=["POST"])\n\
def test_connection():\n\
    try:\n\
        conn = psycopg2.connect(\n\
            host="postgresql",\n\
            database="chinook",\n\
            user="postgres",\n\
            password="postgres"\n\
        )\n\
        cursor = conn.cursor()\n\
        cursor.execute("SELECT version();")\n\
        version = cursor.fetchone()[0]\n\
        cursor.close()\n\
        conn.close()\n\
        return {"status": "success", "message": f"Connected to PostgreSQL: {version}"}\n\
    except Exception as e:\n\
        return {"status": "error", "message": str(e)}\n\
\n\
@app.route("/execute", methods=["POST"])\n\
def execute_query():\n\
    try:\n\
        data = request.json\n\
        query = data["query"].strip()\n\
        \n\
        conn = psycopg2.connect(\n\
            host="postgresql",\n\
            database="chinook",\n\
            user="postgres",\n\
            password="postgres"\n\
        )\n\
        cursor = conn.cursor()\n\
        cursor.execute(query)\n\
        \n\
        if cursor.description:\n\
            columns = [desc[0] for desc in cursor.description]\n\
            results = cursor.fetchall()\n\
        else:\n\
            columns = []\n\
            results = []\n\
            \n\
        cursor.close()\n\
        conn.close()\n\
        \n\
        return {"status": "success", "results": results, "columns": columns}\n\
    except Exception as e:\n\
        return {"status": "error", "message": str(e)}\n\
\n\
if __name__ == "__main__":\n\
    print("🗄️ SQLPad starting on http://0.0.0.0:3000")\n\
    app.run(host="0.0.0.0", port=3000, debug=False)' > /app/sqlpad.py

EXPOSE 3000

USER sqlpad
CMD ["python3", "/app/sqlpad.py"]
