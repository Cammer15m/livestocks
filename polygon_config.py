"""
Configuration management for Polygon.io data fetcher
Handles environment variables, API keys, and database connections
"""

import os
import logging
from typing import Optional, List
from dotenv import load_dotenv

# Load environment variables from .env file if it exists
load_dotenv()

class PolygonConfig:
    """Configuration class for Polygon.io data fetcher"""
    
    def __init__(self):
        # Polygon.io API Configuration
        self.polygon_api_key = os.getenv('POLYGON_API_KEY', 'ObYzcj_rvlU1czNwYLmRZJgg7TXWAX5q')
        self.polygon_api_name = os.getenv('POLYGON_API_NAME', 'Default')
        
        # Database Configuration
        self.db_host = os.getenv('DB_HOST', 'localhost')
        self.db_port = int(os.getenv('DB_PORT', '5432'))
        self.db_name = os.getenv('DB_NAME', 'chinook')
        self.db_user = os.getenv('DB_USER', 'postgres')
        self.db_password = os.getenv('DB_PASSWORD', 'postgres')
        
        # Data Fetching Configuration
        self.default_tickers = self._parse_tickers(os.getenv('DEFAULT_TICKERS', 'AAPL,GOOGL,MSFT,TSLA,AMZN'))
        self.fetch_interval_minutes = int(os.getenv('FETCH_INTERVAL_MINUTES', '60'))
        self.max_retries = int(os.getenv('MAX_RETRIES', '3'))
        self.retry_delay_seconds = int(os.getenv('RETRY_DELAY_SECONDS', '30'))
        
        # Data Range Configuration
        self.days_back_initial = int(os.getenv('DAYS_BACK_INITIAL', '30'))
        self.enable_realtime = os.getenv('ENABLE_REALTIME', 'true').lower() == 'true'
        self.enable_daily_aggregates = os.getenv('ENABLE_DAILY_AGGREGATES', 'true').lower() == 'true'
        self.enable_minute_aggregates = os.getenv('ENABLE_MINUTE_AGGREGATES', 'false').lower() == 'true'
        self.enable_trades = os.getenv('ENABLE_TRADES', 'false').lower() == 'true'
        self.enable_quotes = os.getenv('ENABLE_QUOTES', 'false').lower() == 'true'
        
        # Logging Configuration
        self.log_level = os.getenv('LOG_LEVEL', 'INFO').upper()
        self.log_file = os.getenv('LOG_FILE', 'polygon_fetcher.log')
        self.enable_console_logging = os.getenv('ENABLE_CONSOLE_LOGGING', 'true').lower() == 'true'
        
        # Rate Limiting Configuration
        self.requests_per_minute = int(os.getenv('REQUESTS_PER_MINUTE', '5'))  # Free tier limit
        self.batch_size = int(os.getenv('BATCH_SIZE', '100'))
        
        # Validate configuration
        self._validate_config()
    
    def _parse_tickers(self, tickers_str: str) -> List[str]:
        """Parse comma-separated ticker string into list"""
        if not tickers_str:
            return []
        return [ticker.strip().upper() for ticker in tickers_str.split(',') if ticker.strip()]
    
    def _validate_config(self):
        """Validate configuration values"""
        if not self.polygon_api_key:
            raise ValueError("POLYGON_API_KEY is required")
        
        if not self.default_tickers:
            raise ValueError("At least one ticker must be specified in DEFAULT_TICKERS")
        
        if self.fetch_interval_minutes < 1:
            raise ValueError("FETCH_INTERVAL_MINUTES must be at least 1")
        
        if self.requests_per_minute < 1:
            raise ValueError("REQUESTS_PER_MINUTE must be at least 1")
    
    @property
    def database_url(self) -> str:
        """Get PostgreSQL connection URL"""
        return f"postgresql://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"
    
    @property
    def sqlalchemy_url(self) -> str:
        """Get SQLAlchemy connection URL"""
        return f"postgresql+psycopg2://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"
    
    def setup_logging(self) -> logging.Logger:
        """Setup logging configuration"""
        logger = logging.getLogger('polygon_fetcher')
        logger.setLevel(getattr(logging, self.log_level))
        
        # Clear existing handlers
        logger.handlers.clear()
        
        # Create formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        # Add file handler
        if self.log_file:
            file_handler = logging.FileHandler(self.log_file)
            file_handler.setLevel(getattr(logging, self.log_level))
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)
        
        # Add console handler
        if self.enable_console_logging:
            console_handler = logging.StreamHandler()
            console_handler.setLevel(getattr(logging, self.log_level))
            console_handler.setFormatter(formatter)
            logger.addHandler(console_handler)
        
        return logger
    
    def get_config_summary(self) -> dict:
        """Get a summary of current configuration (excluding sensitive data)"""
        return {
            'polygon_api_name': self.polygon_api_name,
            'polygon_api_key_set': bool(self.polygon_api_key),
            'db_host': self.db_host,
            'db_port': self.db_port,
            'db_name': self.db_name,
            'db_user': self.db_user,
            'default_tickers': self.default_tickers,
            'fetch_interval_minutes': self.fetch_interval_minutes,
            'days_back_initial': self.days_back_initial,
            'enable_realtime': self.enable_realtime,
            'enable_daily_aggregates': self.enable_daily_aggregates,
            'enable_minute_aggregates': self.enable_minute_aggregates,
            'enable_trades': self.enable_trades,
            'enable_quotes': self.enable_quotes,
            'log_level': self.log_level,
            'requests_per_minute': self.requests_per_minute,
            'batch_size': self.batch_size
        }

# Global configuration instance
config = PolygonConfig()
