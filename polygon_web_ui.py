"""
Polygon.io Data Fetcher Web UI
Real-time monitoring and configuration interface for stock data fetching
"""

import os
import json
import threading
import time
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, redirect, url_for
from flask_socketio import SocketIO, emit
import psycopg2
from psycopg2.extras import RealDictCursor
from polygon_config import config
from polygon_fetcher import PolygonDataFetcher
from polygon_utils import get_database_stats
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['SECRET_KEY'] = 'polygon_data_fetcher_secret_key'
socketio = SocketIO(app, cors_allowed_origins="*")

# Global variables for tracking fetching status
fetching_status = {
    'is_running': False,
    'current_ticker': None,
    'progress': 0,
    'total_tickers': 0,
    'last_fetch_time': None,
    'errors': [],
    'success_count': 0,
    'error_count': 0
}

fetcher_thread = None
fetcher_instance = None

def emit_status_update():
    """Emit current status to all connected clients"""
    socketio.emit('status_update', fetching_status)

def emit_log_message(level, message):
    """Emit log message to all connected clients"""
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'level': level,
        'message': message
    }
    socketio.emit('log_message', log_entry)

class WebUILogHandler(logging.Handler):
    """Custom log handler to send logs to web UI"""
    def emit(self, record):
        log_entry = {
            'timestamp': datetime.fromtimestamp(record.created).isoformat(),
            'level': record.levelname,
            'message': record.getMessage()
        }
        socketio.emit('log_message', log_entry)

def get_database_connection():
    """Get database connection using current config"""
    return psycopg2.connect(
        host=config.db_host,
        port=config.db_port,
        database=config.db_name,
        user=config.db_user,
        password=config.db_password,
        cursor_factory=RealDictCursor
    )

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

@app.route('/api/status')
def api_status():
    """Get current fetching status"""
    return jsonify(fetching_status)

@app.route('/api/config')
def api_config():
    """Get current configuration"""
    return jsonify({
        'polygon_api_name': config.polygon_api_name,
        'db_host': config.db_host,
        'db_port': config.db_port,
        'db_name': config.db_name,
        'db_user': config.db_user,
        'default_tickers': config.default_tickers,
        'fetch_interval_minutes': config.fetch_interval_minutes,
        'days_back_initial': config.days_back_initial,
        'enable_realtime': config.enable_realtime,
        'enable_daily_aggregates': config.enable_daily_aggregates,
        'enable_minute_aggregates': config.enable_minute_aggregates,
        'enable_trades': config.enable_trades,
        'enable_quotes': config.enable_quotes,
        'requests_per_minute': config.requests_per_minute,
        'log_level': config.log_level
    })

@app.route('/api/config', methods=['POST'])
def api_update_config():
    """Update configuration"""
    try:
        data = request.get_json()
        
        # Update environment variables (these will be picked up on next restart)
        env_updates = {}
        if 'default_tickers' in data:
            env_updates['DEFAULT_TICKERS'] = ','.join(data['default_tickers'])
        if 'fetch_interval_minutes' in data:
            env_updates['FETCH_INTERVAL_MINUTES'] = str(data['fetch_interval_minutes'])
        if 'days_back_initial' in data:
            env_updates['DAYS_BACK_INITIAL'] = str(data['days_back_initial'])
        if 'enable_daily_aggregates' in data:
            env_updates['ENABLE_DAILY_AGGREGATES'] = str(data['enable_daily_aggregates']).lower()
        if 'enable_minute_aggregates' in data:
            env_updates['ENABLE_MINUTE_AGGREGATES'] = str(data['enable_minute_aggregates']).lower()
        if 'enable_trades' in data:
            env_updates['ENABLE_TRADES'] = str(data['enable_trades']).lower()
        if 'enable_quotes' in data:
            env_updates['ENABLE_QUOTES'] = str(data['enable_quotes']).lower()
        if 'requests_per_minute' in data:
            env_updates['REQUESTS_PER_MINUTE'] = str(data['requests_per_minute'])
        
        # Update .env file
        env_file_path = '.env'
        if os.path.exists(env_file_path):
            with open(env_file_path, 'r') as f:
                lines = f.readlines()
            
            # Update existing values or add new ones
            updated_lines = []
            updated_keys = set()
            
            for line in lines:
                if '=' in line and not line.strip().startswith('#'):
                    key = line.split('=')[0].strip()
                    if key in env_updates:
                        updated_lines.append(f"{key}={env_updates[key]}\n")
                        updated_keys.add(key)
                    else:
                        updated_lines.append(line)
                else:
                    updated_lines.append(line)
            
            # Add new keys that weren't found
            for key, value in env_updates.items():
                if key not in updated_keys:
                    updated_lines.append(f"{key}={value}\n")
            
            with open(env_file_path, 'w') as f:
                f.writelines(updated_lines)
        
        emit_log_message('INFO', f'Configuration updated: {env_updates}')
        return jsonify({'success': True, 'message': 'Configuration updated successfully'})
        
    except Exception as e:
        logger.error(f"Failed to update configuration: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/data/tickers')
def api_data_tickers():
    """Get ticker data from database"""
    try:
        with get_database_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT ticker, name, active, market, locale, 
                           primary_exchange, type, currency_name,
                           created_at, updated_at
                    FROM stock_tickers 
                    ORDER BY ticker
                """)
                tickers = cur.fetchall()
                return jsonify([dict(row) for row in tickers])
    except Exception as e:
        logger.error(f"Failed to fetch ticker data: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/daily_aggregates')
def api_data_daily_aggregates():
    """Get daily aggregates data from database"""
    try:
        limit = request.args.get('limit', 100, type=int)
        ticker = request.args.get('ticker', '')
        
        with get_database_connection() as conn:
            with conn.cursor() as cur:
                query = """
                    SELECT ticker, date, open, high, low, close, volume, 
                           vwap, transactions, created_at
                    FROM daily_aggregates 
                """
                params = []
                
                if ticker:
                    query += " WHERE ticker = %s"
                    params.append(ticker)
                
                query += " ORDER BY date DESC, ticker LIMIT %s"
                params.append(limit)
                
                cur.execute(query, params)
                aggregates = cur.fetchall()
                return jsonify([dict(row) for row in aggregates])
    except Exception as e:
        logger.error(f"Failed to fetch daily aggregates: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/fetch_log')
def api_data_fetch_log():
    """Get fetch log data from database"""
    try:
        limit = request.args.get('limit', 50, type=int)
        
        with get_database_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT operation_type, ticker, status, records_processed,
                           error_message, created_at, completed_at
                    FROM data_fetch_log 
                    ORDER BY created_at DESC 
                    LIMIT %s
                """, (limit,))
                logs = cur.fetchall()
                return jsonify([dict(row) for row in logs])
    except Exception as e:
        logger.error(f"Failed to fetch log data: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats')
def api_stats():
    """Get database statistics"""
    try:
        stats = get_database_stats()
        return jsonify(stats)
    except Exception as e:
        logger.error(f"Failed to fetch stats: {e}")
        return jsonify({'error': str(e)}), 500

def run_data_fetch():
    """Run data fetching in background thread"""
    global fetching_status, fetcher_instance
    
    try:
        fetching_status['is_running'] = True
        fetching_status['errors'] = []
        fetching_status['success_count'] = 0
        fetching_status['error_count'] = 0
        emit_status_update()
        
        # Initialize fetcher
        fetcher_instance = PolygonDataFetcher()
        
        # Add web UI log handler
        web_handler = WebUILogHandler()
        web_handler.setLevel(logging.INFO)
        fetcher_logger = logging.getLogger('polygon_fetcher')
        fetcher_logger.addHandler(web_handler)
        
        emit_log_message('INFO', 'Starting data fetch process...')
        
        # Initialize tickers first
        emit_log_message('INFO', 'Initializing ticker information...')
        fetcher_instance.initialize_tickers()
        
        # Fetch daily aggregates for each ticker
        tickers = config.default_tickers
        fetching_status['total_tickers'] = len(tickers)
        
        for i, ticker in enumerate(tickers):
            if not fetching_status['is_running']:  # Check if stopped
                break
                
            fetching_status['current_ticker'] = ticker
            fetching_status['progress'] = i
            emit_status_update()
            
            try:
                emit_log_message('INFO', f'Fetching daily aggregates for {ticker}...')
                
                # Calculate date range
                end_date = datetime.now().strftime('%Y-%m-%d')
                start_date = (datetime.now() - timedelta(days=config.days_back_initial)).strftime('%Y-%m-%d')
                
                records = fetcher_instance.fetch_daily_aggregates(ticker, start_date, end_date)
                
                fetching_status['success_count'] += 1
                emit_log_message('INFO', f'Successfully fetched {records} records for {ticker}')
                
            except Exception as e:
                fetching_status['error_count'] += 1
                error_msg = f'Failed to fetch data for {ticker}: {str(e)}'
                fetching_status['errors'].append(error_msg)
                emit_log_message('ERROR', error_msg)
        
        fetching_status['progress'] = len(tickers)
        fetching_status['last_fetch_time'] = datetime.now().isoformat()
        emit_log_message('INFO', 'Data fetch process completed')
        
    except Exception as e:
        error_msg = f'Data fetch process failed: {str(e)}'
        fetching_status['errors'].append(error_msg)
        emit_log_message('ERROR', error_msg)
    
    finally:
        fetching_status['is_running'] = False
        fetching_status['current_ticker'] = None
        emit_status_update()

@socketio.on('start_fetch')
def handle_start_fetch():
    """Handle start fetch request from client"""
    global fetcher_thread
    
    if not fetching_status['is_running']:
        fetcher_thread = threading.Thread(target=run_data_fetch)
        fetcher_thread.daemon = True
        fetcher_thread.start()
        emit_log_message('INFO', 'Data fetch started by user')
    else:
        emit_log_message('WARNING', 'Data fetch is already running')

@socketio.on('stop_fetch')
def handle_stop_fetch():
    """Handle stop fetch request from client"""
    if fetching_status['is_running']:
        fetching_status['is_running'] = False
        emit_log_message('INFO', 'Data fetch stopped by user')
        emit_status_update()

@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    emit_status_update()
    emit_log_message('INFO', 'Client connected to monitoring interface')

if __name__ == '__main__':
    # Install the web UI log handler for the polygon_fetcher logger
    web_handler = WebUILogHandler()
    web_handler.setLevel(logging.INFO)
    polygon_logger = logging.getLogger('polygon_fetcher')
    polygon_logger.addHandler(web_handler)
    
    print("Starting Polygon.io Data Fetcher Web UI...")
    print("Access the interface at: http://localhost:5001")

    socketio.run(app, host='0.0.0.0', port=5001, debug=True)
