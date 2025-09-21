"""
Polygon.io Continuous Data Monitor
Continuously monitors and fetches new stock market data from Polygon.io API
"""

import time
import schedule
import signal
import sys
from datetime import datetime, timedelta, timezone
from typing import Dict, Any
from polygon_fetcher import PolygonDataFetcher
from polygon_config import config

class PolygonMonitor:
    """Continuous monitoring service for Polygon.io data"""
    
    def __init__(self):
        self.fetcher = PolygonDataFetcher()
        self.logger = self.fetcher.logger
        self.running = True
        self.setup_signal_handlers()
        
    def setup_signal_handlers(self):
        """Setup signal handlers for graceful shutdown"""
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
    
    def is_market_hours(self) -> bool:
        """Check if current time is during market hours (9:30 AM - 4:00 PM ET)"""
        try:
            # Get current time in ET
            from pytz import timezone as pytz_timezone
            et_tz = pytz_timezone('US/Eastern')
            current_et = datetime.now(et_tz)
            
            # Check if it's a weekday
            if current_et.weekday() >= 5:  # Saturday = 5, Sunday = 6
                return False
            
            # Check if it's during market hours (9:30 AM - 4:00 PM ET)
            market_open = current_et.replace(hour=9, minute=30, second=0, microsecond=0)
            market_close = current_et.replace(hour=16, minute=0, second=0, microsecond=0)
            
            return market_open <= current_et <= market_close
        except Exception as e:
            self.logger.error(f"Error checking market hours: {e}")
            return False
    
    def fetch_latest_daily_data(self):
        """Fetch latest daily data for all tickers"""
        self.logger.info("Starting scheduled daily data fetch")
        
        try:
            # Get yesterday's date (since daily data is available after market close)
            yesterday = (datetime.now() - timedelta(days=1)).date()
            date_str = str(yesterday)
            
            for ticker in config.default_tickers:
                try:
                    if config.enable_daily_aggregates:
                        self.fetcher.fetch_daily_aggregates(ticker, date_str, date_str)
                    
                    # Rate limiting
                    time.sleep(60 / config.requests_per_minute)
                    
                except Exception as e:
                    self.logger.error(f"Failed to fetch daily data for {ticker}: {e}")
                    continue
            
            self.logger.info("Completed scheduled daily data fetch")
            
        except Exception as e:
            self.logger.error(f"Daily data fetch failed: {e}")
    
    def fetch_current_market_data(self):
        """Fetch current market data during market hours"""
        if not self.is_market_hours():
            self.logger.debug("Market is closed, skipping current data fetch")
            return
        
        self.logger.info("Fetching current market data")
        
        try:
            # Fetch market status
            self.fetcher.fetch_market_status()
            
            # For real-time data, we would fetch minute aggregates, trades, or quotes
            # This is limited by the free tier, so we'll focus on daily aggregates
            if config.enable_minute_aggregates:
                today = datetime.now().date()
                date_str = str(today)
                
                for ticker in config.default_tickers:
                    try:
                        # Note: Minute aggregates require a paid plan
                        # This is a placeholder for when you upgrade
                        self.logger.info(f"Would fetch minute data for {ticker} (requires paid plan)")
                        
                        # Rate limiting
                        time.sleep(60 / config.requests_per_minute)
                        
                    except Exception as e:
                        self.logger.error(f"Failed to fetch current data for {ticker}: {e}")
                        continue
            
        except Exception as e:
            self.logger.error(f"Current market data fetch failed: {e}")
    
    def update_ticker_info(self):
        """Periodically update ticker information"""
        self.logger.info("Updating ticker information")
        
        try:
            for ticker in config.default_tickers:
                try:
                    ticker_data = self.fetcher.fetch_ticker_details(ticker)
                    if ticker_data:
                        self.fetcher.upsert_ticker(ticker_data)
                        self.logger.debug(f"Updated ticker info for {ticker}")
                    
                    # Rate limiting
                    time.sleep(60 / config.requests_per_minute)
                    
                except Exception as e:
                    self.logger.error(f"Failed to update ticker info for {ticker}: {e}")
                    continue
            
            self.logger.info("Completed ticker information update")
            
        except Exception as e:
            self.logger.error(f"Ticker info update failed: {e}")
    
    def cleanup_old_logs(self):
        """Clean up old fetch logs to prevent database bloat"""
        try:
            self.logger.info("Cleaning up old fetch logs")
            
            with self.fetcher.connect_db() as conn:
                with conn.cursor() as cur:
                    # Delete logs older than 30 days
                    cur.execute("""
                        DELETE FROM data_fetch_log 
                        WHERE created_at < NOW() - INTERVAL '30 days'
                    """)
                    deleted_count = cur.rowcount
                    conn.commit()
                    
                    self.logger.info(f"Cleaned up {deleted_count} old fetch log entries")
                    
        except Exception as e:
            self.logger.error(f"Failed to cleanup old logs: {e}")
    
    def health_check(self):
        """Perform health check on the system"""
        try:
            self.logger.debug("Performing health check")
            
            # Check database connection
            with self.fetcher.connect_db() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1")
                    cur.fetchone()
            
            # Check recent fetch activity
            with self.fetcher.connect_db() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT COUNT(*) as recent_fetches
                        FROM data_fetch_log 
                        WHERE created_at > NOW() - INTERVAL '24 hours'
                        AND status = 'completed'
                    """)
                    result = cur.fetchone()
                    recent_fetches = result['recent_fetches'] if result else 0
                    
                    if recent_fetches == 0:
                        self.logger.warning("No successful fetches in the last 24 hours")
                    else:
                        self.logger.debug(f"Health check passed: {recent_fetches} successful fetches in last 24h")
            
        except Exception as e:
            self.logger.error(f"Health check failed: {e}")
    
    def setup_schedule(self):
        """Setup the monitoring schedule"""
        self.logger.info("Setting up monitoring schedule")
        
        # Daily data fetch - run after market close (5 PM ET)
        schedule.every().day.at("22:00").do(self.fetch_latest_daily_data)  # 5 PM ET = 10 PM UTC (approximate)
        
        # Update ticker info - weekly on Sunday
        schedule.every().sunday.at("06:00").do(self.update_ticker_info)
        
        # Cleanup old logs - monthly
        schedule.every().monday.at("02:00").do(self.cleanup_old_logs)
        
        # Health check - every 6 hours
        schedule.every(6).hours.do(self.health_check)
        
        # Current market data - every 15 minutes during market hours
        if config.enable_realtime:
            schedule.every(15).minutes.do(self.fetch_current_market_data)
        
        self.logger.info("Monitoring schedule configured")
        self.logger.info("Scheduled jobs:")
        for job in schedule.jobs:
            self.logger.info(f"  - {job}")
    
    def run(self):
        """Main monitoring loop"""
        self.logger.info("Starting Polygon.io data monitor")
        self.logger.info(f"Monitoring {len(config.default_tickers)} tickers: {', '.join(config.default_tickers)}")
        
        # Setup schedule
        self.setup_schedule()
        
        # Run initial health check
        self.health_check()
        
        # Main monitoring loop
        while self.running:
            try:
                schedule.run_pending()
                time.sleep(60)  # Check every minute
                
            except KeyboardInterrupt:
                self.logger.info("Received keyboard interrupt")
                break
            except Exception as e:
                self.logger.error(f"Error in monitoring loop: {e}")
                time.sleep(60)  # Wait before retrying
        
        self.logger.info("Polygon.io data monitor stopped")

def main():
    """Main entry point"""
    monitor = PolygonMonitor()
    
    try:
        # Run initial setup if this is the first time
        monitor.logger.info("Checking if initial setup is needed...")
        
        with monitor.fetcher.connect_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) as ticker_count FROM stock_tickers")
                result = cur.fetchone()
                ticker_count = result['ticker_count'] if result else 0
                
                if ticker_count == 0:
                    monitor.logger.info("No tickers found, running initial setup...")
                    monitor.fetcher.run_initial_setup()
                else:
                    monitor.logger.info(f"Found {ticker_count} existing tickers, skipping initial setup")
        
        # Start monitoring
        monitor.run()
        
    except Exception as e:
        monitor.logger.error(f"Monitor startup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
