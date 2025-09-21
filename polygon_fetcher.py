"""
Polygon.io Data Fetcher
Fetches stock market data from Polygon.io API and stores it in PostgreSQL database
"""

import time
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any
import psycopg2
from psycopg2.extras import RealDictCursor
from sqlalchemy import create_engine, text
from polygon import RESTClient
from polygon_config import config

class PolygonDataFetcher:
    """Main class for fetching and storing Polygon.io data"""
    
    def __init__(self):
        self.logger = config.setup_logging()
        self.polygon_client = RESTClient(api_key=config.polygon_api_key)
        self.engine = create_engine(config.sqlalchemy_url)
        self.logger.info("Polygon Data Fetcher initialized")
        self.logger.info(f"Configuration: {config.get_config_summary()}")
    
    def connect_db(self):
        """Create database connection"""
        try:
            conn = psycopg2.connect(
                host=config.db_host,
                port=config.db_port,
                database=config.db_name,
                user=config.db_user,
                password=config.db_password,
                cursor_factory=RealDictCursor
            )
            return conn
        except Exception as e:
            self.logger.error(f"Database connection failed: {e}")
            raise
    
    def log_fetch_start(self, fetch_type: str, ticker: Optional[str] = None, 
                       start_date: Optional[str] = None, end_date: Optional[str] = None) -> int:
        """Log the start of a data fetch operation"""
        try:
            with self.connect_db() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO data_fetch_log (fetch_type, ticker, start_date, end_date, status)
                        VALUES (%s, %s, %s, %s, 'started')
                        RETURNING id
                    """, (fetch_type, ticker, start_date, end_date))
                    fetch_id = cur.fetchone()['id']
                    conn.commit()
                    return fetch_id
        except Exception as e:
            self.logger.error(f"Failed to log fetch start: {e}")
            return -1
    
    def log_fetch_complete(self, fetch_id: int, records_fetched: int, 
                          error_message: Optional[str] = None, duration: Optional[float] = None):
        """Log the completion of a data fetch operation"""
        try:
            with self.connect_db() as conn:
                with conn.cursor() as cur:
                    status = 'completed' if error_message is None else 'failed'
                    cur.execute("""
                        UPDATE data_fetch_log 
                        SET status = %s, records_fetched = %s, error_message = %s, 
                            fetch_duration_seconds = %s, completed_at = CURRENT_TIMESTAMP
                        WHERE id = %s
                    """, (status, records_fetched, error_message, duration, fetch_id))
                    conn.commit()
        except Exception as e:
            self.logger.error(f"Failed to log fetch completion: {e}")
    
    def upsert_ticker(self, ticker_data: Dict[str, Any]):
        """Insert or update ticker information"""
        try:
            with self.connect_db() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO stock_tickers (
                            ticker, name, market, locale, primary_exchange, type, 
                            active, currency_name, cik, composite_figi, share_class_figi,
                            last_updated_utc
                        ) VALUES (
                            %(ticker)s, %(name)s, %(market)s, %(locale)s, %(primary_exchange)s, 
                            %(type)s, %(active)s, %(currency_name)s, %(cik)s, 
                            %(composite_figi)s, %(share_class_figi)s, %(last_updated_utc)s
                        )
                        ON CONFLICT (ticker) DO UPDATE SET
                            name = EXCLUDED.name,
                            market = EXCLUDED.market,
                            locale = EXCLUDED.locale,
                            primary_exchange = EXCLUDED.primary_exchange,
                            type = EXCLUDED.type,
                            active = EXCLUDED.active,
                            currency_name = EXCLUDED.currency_name,
                            cik = EXCLUDED.cik,
                            composite_figi = EXCLUDED.composite_figi,
                            share_class_figi = EXCLUDED.share_class_figi,
                            last_updated_utc = EXCLUDED.last_updated_utc,
                            updated_at = CURRENT_TIMESTAMP
                    """, ticker_data)
                    conn.commit()
        except Exception as e:
            self.logger.error(f"Failed to upsert ticker {ticker_data.get('ticker', 'unknown')}: {e}")
            raise
    
    def fetch_ticker_details(self, ticker: str) -> Optional[Dict[str, Any]]:
        """Fetch ticker details from Polygon API"""
        try:
            self.logger.info(f"Fetching ticker details for {ticker}")
            ticker_details = self.polygon_client.get_ticker_details(ticker)
            
            if ticker_details and hasattr(ticker_details, 'results'):
                result = ticker_details.results
                return {
                    'ticker': result.ticker,
                    'name': getattr(result, 'name', None),
                    'market': getattr(result, 'market', None),
                    'locale': getattr(result, 'locale', None),
                    'primary_exchange': getattr(result, 'primary_exchange', None),
                    'type': getattr(result, 'type', None),
                    'active': getattr(result, 'active', True),
                    'currency_name': getattr(result, 'currency_name', None),
                    'cik': getattr(result, 'cik', None),
                    'composite_figi': getattr(result, 'composite_figi', None),
                    'share_class_figi': getattr(result, 'share_class_figi', None),
                    'last_updated_utc': getattr(result, 'last_updated_utc', None)
                }
            return None
        except Exception as e:
            self.logger.error(f"Failed to fetch ticker details for {ticker}: {e}")
            return None
    
    def fetch_daily_aggregates(self, ticker: str, start_date: str, end_date: str) -> int:
        """Fetch daily aggregate data for a ticker"""
        fetch_id = self.log_fetch_start('daily_aggregates', ticker, start_date, end_date)
        start_time = time.time()
        records_fetched = 0
        
        try:
            self.logger.info(f"Fetching daily aggregates for {ticker} from {start_date} to {end_date}")
            
            # Fetch data from Polygon API
            aggs = self.polygon_client.list_aggs(
                ticker=ticker,
                multiplier=1,
                timespan="day",
                from_=start_date,
                to=end_date,
                limit=50000
            )
            
            # Store data in database
            with self.connect_db() as conn:
                with conn.cursor() as cur:
                    for agg in aggs:
                        try:
                            # Convert timestamp to date
                            agg_date = datetime.fromtimestamp(agg.timestamp / 1000, tz=timezone.utc).date()
                            
                            cur.execute("""
                                INSERT INTO daily_aggregates (
                                    ticker, date, open, high, low, close, volume, vwap, 
                                    timestamp, transactions
                                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                                ON CONFLICT (ticker, date) DO UPDATE SET
                                    open = EXCLUDED.open,
                                    high = EXCLUDED.high,
                                    low = EXCLUDED.low,
                                    close = EXCLUDED.close,
                                    volume = EXCLUDED.volume,
                                    vwap = EXCLUDED.vwap,
                                    timestamp = EXCLUDED.timestamp,
                                    transactions = EXCLUDED.transactions,
                                    updated_at = CURRENT_TIMESTAMP
                            """, (
                                ticker, agg_date, agg.open, agg.high, agg.low, agg.close,
                                agg.volume, getattr(agg, 'vwap', None), agg.timestamp,
                                getattr(agg, 'transactions', None)
                            ))
                            records_fetched += 1
                        except Exception as e:
                            self.logger.error(f"Failed to insert aggregate for {ticker} on {agg_date}: {e}")
                    
                    conn.commit()
            
            duration = time.time() - start_time
            self.log_fetch_complete(fetch_id, records_fetched, None, duration)
            self.logger.info(f"Successfully fetched {records_fetched} daily aggregates for {ticker}")
            return records_fetched
            
        except Exception as e:
            duration = time.time() - start_time
            error_msg = str(e)
            self.log_fetch_complete(fetch_id, records_fetched, error_msg, duration)
            self.logger.error(f"Failed to fetch daily aggregates for {ticker}: {e}")
            raise
    
    def fetch_market_status(self):
        """Fetch current market status"""
        try:
            self.logger.info("Fetching market status")
            status = self.polygon_client.get_market_status()
            
            if status and hasattr(status, 'results'):
                result = status.results
                with self.connect_db() as conn:
                    with conn.cursor() as cur:
                        cur.execute("""
                            INSERT INTO market_status (
                                market, server_time, exchanges, currencies, 
                                early_hours, market_open, after_hours
                            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                            ON CONFLICT (market, server_time) DO NOTHING
                        """, (
                            'stocks',
                            getattr(result, 'server_time', None),
                            getattr(result, 'exchanges', {}),
                            getattr(result, 'currencies', {}),
                            getattr(result, 'early_hours', False),
                            getattr(result, 'market', False),
                            getattr(result, 'after_hours', False)
                        ))
                        conn.commit()
                        
        except Exception as e:
            self.logger.error(f"Failed to fetch market status: {e}")
    
    def initialize_tickers(self):
        """Initialize ticker information for configured tickers"""
        self.logger.info("Initializing ticker information")
        for ticker in config.default_tickers:
            try:
                ticker_data = self.fetch_ticker_details(ticker)
                if ticker_data:
                    self.upsert_ticker(ticker_data)
                    self.logger.info(f"Initialized ticker: {ticker}")
                else:
                    # Create minimal ticker entry if API call fails
                    minimal_ticker = {
                        'ticker': ticker,
                        'name': None,
                        'market': 'stocks',
                        'locale': 'us',
                        'primary_exchange': None,
                        'type': None,
                        'active': True,
                        'currency_name': 'usd',
                        'cik': None,
                        'composite_figi': None,
                        'share_class_figi': None,
                        'last_updated_utc': None
                    }
                    self.upsert_ticker(minimal_ticker)
                    self.logger.warning(f"Created minimal ticker entry for: {ticker}")
                
                # Rate limiting
                time.sleep(60 / config.requests_per_minute)
                
            except Exception as e:
                self.logger.error(f"Failed to initialize ticker {ticker}: {e}")
    
    def fetch_historical_data(self):
        """Fetch historical data for all configured tickers"""
        self.logger.info("Starting historical data fetch")
        
        # Calculate date range
        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=config.days_back_initial)
        
        for ticker in config.default_tickers:
            try:
                if config.enable_daily_aggregates:
                    self.fetch_daily_aggregates(ticker, str(start_date), str(end_date))
                
                # Rate limiting between tickers
                time.sleep(60 / config.requests_per_minute)
                
            except Exception as e:
                self.logger.error(f"Failed to fetch historical data for {ticker}: {e}")
                continue
    
    def run_initial_setup(self):
        """Run initial setup: initialize tickers and fetch historical data"""
        self.logger.info("Starting initial setup")
        try:
            self.initialize_tickers()
            self.fetch_historical_data()
            self.fetch_market_status()
            self.logger.info("Initial setup completed successfully")
        except Exception as e:
            self.logger.error(f"Initial setup failed: {e}")
            raise

if __name__ == "__main__":
    fetcher = PolygonDataFetcher()
    fetcher.run_initial_setup()
