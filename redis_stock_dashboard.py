#!/usr/bin/env python3
"""
Redis Stock Dashboard - Real-time stock data visualization from Redis
Features:
- Real-time stock data from Redis
- Stock crash/upturn simulation
- RDI job configuration documentation
- Live charts and alerts
"""

import os
import json
import redis
import random
import time
from datetime import datetime, timedelta
from flask import Flask, render_template, jsonify, request
from flask_socketio import SocketIO, emit
import threading
import logging
from polygon_config import PolygonConfig

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['SECRET_KEY'] = 'redis-stock-dashboard-secret'
socketio = SocketIO(app, cors_allowed_origins="*")

# Redis connection - using the connection info from startup
redis_client = redis.Redis(
    host='redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com',
    port=17173,
    username='default',
    password='redislabs',
    decode_responses=True
)

# Global variables for simulation
simulation_active = False
simulation_thread = None

class StockSimulator:
    def __init__(self):
        self.tickers = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN']
        self.base_prices = {
            'AAPL': 245.50,
            'GOOGL': 254.72,
            'MSFT': 517.93,
            'TSLA': 426.07,
            'AMZN': 231.48
        }
    
    def simulate_crash(self, intensity=0.3):
        """Simulate a stock market crash"""
        logger.info(f"🔴 SIMULATING MARKET CRASH - Intensity: {intensity}")
        
        for ticker in self.tickers:
            # Crash: 15-50% drop
            drop_percent = random.uniform(0.15, intensity)
            new_price = self.base_prices[ticker] * (1 - drop_percent)
            
            # Create dramatic crash data
            crash_data = {
                'ticker': ticker,
                'date': datetime.now().strftime('%Y-%m-%d'),
                'time': datetime.now().strftime('%H:%M:%S'),
                'open': self.base_prices[ticker],
                'high': self.base_prices[ticker] * 1.02,  # Small morning gain
                'low': new_price * 0.95,  # Even lower intraday
                'close': new_price,
                'volume': random.randint(200000000, 500000000),  # High volume
                'price_change': new_price - self.base_prices[ticker],
                'price_change_percent': round(-drop_percent * 100, 2),
                'event_type': 'CRASH',
                'volatility': 'EXTREME'
            }
            
            # Store in Redis
            key = f"live:crash:{ticker}"
            redis_client.hset(key, mapping=crash_data)
            redis_client.expire(key, 3600)  # Expire in 1 hour
            
            # Also update latest price
            redis_client.hset(f"latest:{ticker}", mapping=crash_data)
            
            logger.info(f"💥 {ticker} CRASHED: {self.base_prices[ticker]:.2f} → {new_price:.2f} ({-drop_percent*100:.1f}%)")
    
    def simulate_upturn(self, intensity=0.4):
        """Simulate a dramatic stock upturn"""
        logger.info(f"🚀 SIMULATING MARKET SURGE - Intensity: {intensity}")
        
        for ticker in self.tickers:
            # Surge: 20-60% gain
            gain_percent = random.uniform(0.20, intensity)
            new_price = self.base_prices[ticker] * (1 + gain_percent)
            
            # Create dramatic surge data
            surge_data = {
                'ticker': ticker,
                'date': datetime.now().strftime('%Y-%m-%d'),
                'time': datetime.now().strftime('%H:%M:%S'),
                'open': self.base_prices[ticker],
                'high': new_price * 1.05,  # Even higher intraday
                'low': self.base_prices[ticker] * 0.98,  # Small dip
                'close': new_price,
                'volume': random.randint(300000000, 600000000),  # Very high volume
                'price_change': new_price - self.base_prices[ticker],
                'price_change_percent': round(gain_percent * 100, 2),
                'event_type': 'SURGE',
                'volatility': 'EXTREME'
            }
            
            # Store in Redis
            key = f"live:surge:{ticker}"
            redis_client.hset(key, mapping=surge_data)
            redis_client.expire(key, 3600)  # Expire in 1 hour
            
            # Also update latest price
            redis_client.hset(f"latest:{ticker}", mapping=surge_data)
            
            logger.info(f"🚀 {ticker} SURGED: {self.base_prices[ticker]:.2f} → {new_price:.2f} (+{gain_percent*100:.1f}%)")

simulator = StockSimulator()

@app.route('/')
def dashboard():
    return render_template('redis_dashboard.html')

@app.route('/api/redis/stocks')
def get_redis_stocks():
    """Get all stock data from Redis"""
    try:
        stocks = []
        
        # Get all stock keys
        stock_keys = redis_client.keys('stock:*')
        latest_keys = redis_client.keys('latest:*')
        crash_keys = redis_client.keys('live:crash:*')
        surge_keys = redis_client.keys('live:surge:*')
        
        all_keys = stock_keys + latest_keys + crash_keys + surge_keys
        
        for key in all_keys:
            data = redis_client.hgetall(key)
            if data:
                data['redis_key'] = key
                data['key_type'] = key.split(':')[0]
                stocks.append(data)
        
        return jsonify({
            'success': True,
            'stocks': stocks,
            'total_keys': len(all_keys),
            'stock_keys': len(stock_keys),
            'latest_keys': len(latest_keys),
            'crash_keys': len(crash_keys),
            'surge_keys': len(surge_keys)
        })
    
    except Exception as e:
        logger.error(f"Error fetching Redis stocks: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/simulate/crash', methods=['POST'])
def simulate_crash():
    """Trigger stock market crash simulation"""
    try:
        intensity = float(request.json.get('intensity', 0.3))
        simulator.simulate_crash(intensity)
        
        # Emit real-time update
        socketio.emit('market_event', {
            'type': 'CRASH',
            'intensity': intensity,
            'message': f'🔴 MARKET CRASH SIMULATED! Average drop: {intensity*100:.0f}%'
        })
        
        return jsonify({'success': True, 'message': 'Market crash simulated!'})
    
    except Exception as e:
        logger.error(f"Error simulating crash: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/simulate/upturn', methods=['POST'])
def simulate_upturn():
    """Trigger stock market upturn simulation"""
    try:
        intensity = float(request.json.get('intensity', 0.4))
        simulator.simulate_upturn(intensity)
        
        # Emit real-time update
        socketio.emit('market_event', {
            'type': 'SURGE',
            'intensity': intensity,
            'message': f'🚀 MARKET SURGE SIMULATED! Average gain: {intensity*100:.0f}%'
        })
        
        return jsonify({'success': True, 'message': 'Market surge simulated!'})
    
    except Exception as e:
        logger.error(f"Error simulating upturn: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/rdi/jobs')
def get_rdi_jobs():
    """Get RDI job configurations for documentation"""
    jobs = {
        'daily_stock_sync': {
            'name': 'Daily Stock Data Sync',
            'description': 'Syncs daily stock aggregates with price calculations',
            'config': {
                'name': 'daily-stock-sync',
                'source': {'table': 'daily_aggregates'},
                'transform': [
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'price_change',
                            'expression': 'close - open',
                            'language': 'sql'
                        }
                    },
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'price_change_percent',
                            'expression': 'round(((close - open) / open) * 100, 2)',
                            'language': 'sql'
                        }
                    }
                ],
                'output': [
                    {
                        'uses': 'redis.write',
                        'with': {
                            'connection': 'target',
                            'key': {
                                'expression': "concat('stock:', ticker, ':', date)",
                                'language': 'sql'
                            }
                        }
                    }
                ]
            }
        },
        'latest_prices': {
            'name': 'Latest Stock Prices',
            'description': 'Syncs only the latest prices for each ticker',
            'config': {
                'name': 'latest-prices',
                'source': {'table': 'daily_aggregates'},
                'transform': [
                    {
                        'uses': 'filter',
                        'with': {
                            'expression': 'date = (SELECT MAX(date) FROM daily_aggregates)',
                            'language': 'sql'
                        }
                    },
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'price_change',
                            'expression': 'close - open',
                            'language': 'sql'
                        }
                    },
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'price_change_percent',
                            'expression': 'round(((close - open) / open) * 100, 2)',
                            'language': 'sql'
                        }
                    }
                ],
                'output': [
                    {
                        'uses': 'redis.write',
                        'with': {
                            'connection': 'target',
                            'key': {
                                'expression': "concat('latest:', ticker)",
                                'language': 'sql'
                            }
                        }
                    }
                ]
            }
        },
        'stock_tickers_info': {
            'name': 'Stock Ticker Information',
            'description': 'Syncs stock ticker metadata and company information',
            'config': {
                'name': 'stock-tickers-info',
                'source': {'table': 'stock_tickers'},
                'output': [
                    {
                        'uses': 'redis.write',
                        'with': {
                            'connection': 'target',
                            'key': {
                                'expression': "concat('ticker:', ticker)",
                                'language': 'sql'
                            }
                        }
                    }
                ]
            }
        },
        'high_volume_alerts': {
            'name': 'High Volume Trading Alerts',
            'description': 'Filters and syncs stocks with unusually high trading volume',
            'config': {
                'name': 'high-volume-alerts',
                'source': {'table': 'daily_aggregates'},
                'transform': [
                    {
                        'uses': 'filter',
                        'with': {
                            'expression': 'volume > 100000000',
                            'language': 'sql'
                        }
                    },
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'volume_millions',
                            'expression': 'round(volume / 1000000.0, 2)',
                            'language': 'sql'
                        }
                    },
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'alert_type',
                            'expression': "'HIGH_VOLUME'",
                            'language': 'sql'
                        }
                    }
                ],
                'output': [
                    {
                        'uses': 'redis.write',
                        'with': {
                            'connection': 'target',
                            'key': {
                                'expression': "concat('alert:volume:', ticker, ':', date)",
                                'language': 'sql'
                            }
                        }
                    }
                ]
            }
        },
        'price_volatility': {
            'name': 'Price Volatility Tracker',
            'description': 'Tracks stocks with high price volatility (large daily ranges)',
            'config': {
                'name': 'price-volatility',
                'source': {'table': 'daily_aggregates'},
                'transform': [
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'daily_range',
                            'expression': 'high - low',
                            'language': 'sql'
                        }
                    },
                    {
                        'uses': 'add_field',
                        'with': {
                            'field': 'volatility_percent',
                            'expression': 'round(((high - low) / open) * 100, 2)',
                            'language': 'sql'
                        }
                    },
                    {
                        'uses': 'filter',
                        'with': {
                            'expression': '((high - low) / open) > 0.05',
                            'language': 'sql'
                        }
                    }
                ],
                'output': [
                    {
                        'uses': 'redis.write',
                        'with': {
                            'connection': 'target',
                            'key': {
                                'expression': "concat('volatility:', ticker, ':', date)",
                                'language': 'sql'
                            }
                        }
                    }
                ]
            }
        }
    }

    return jsonify(jobs)

def background_monitor():
    """Background thread to monitor Redis and emit updates"""
    while True:
        try:
            # Get latest stock data
            stocks = []
            latest_keys = redis_client.keys('latest:*')
            
            for key in latest_keys:
                data = redis_client.hgetall(key)
                if data:
                    data['redis_key'] = key
                    stocks.append(data)
            
            if stocks:
                socketio.emit('stock_update', {'stocks': stocks})
            
            time.sleep(2)  # Update every 2 seconds
            
        except Exception as e:
            logger.error(f"Background monitor error: {e}")
            time.sleep(5)

@socketio.on('connect')
def handle_connect():
    logger.info('Client connected to Redis dashboard')
    emit('status', {'message': 'Connected to Redis Stock Dashboard'})

if __name__ == '__main__':
    logger.info("Starting Redis Stock Dashboard...")
    logger.info("Access the dashboard at: http://localhost:5002")
    
    # Start background monitoring
    monitor_thread = threading.Thread(target=background_monitor, daemon=True)
    monitor_thread.start()
    
    socketio.run(app, host='0.0.0.0', port=9998, debug=True)
