"""
Utility functions for Polygon.io data fetcher
Includes retry logic, error handling, and helper functions
"""

import time
import logging
import functools
from typing import Callable, Any, Optional, Dict
from datetime import datetime, timezone
import psycopg2
from polygon_config import config

def retry_with_backoff(max_retries: int = None, delay: float = None, backoff_factor: float = 2.0):
    """
    Decorator for retrying functions with exponential backoff
    
    Args:
        max_retries: Maximum number of retry attempts (default from config)
        delay: Initial delay between retries in seconds (default from config)
        backoff_factor: Factor to multiply delay by after each retry
    """
    if max_retries is None:
        max_retries = config.max_retries
    if delay is None:
        delay = config.retry_delay_seconds
    
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            logger = logging.getLogger('polygon_fetcher')
            last_exception = None
            
            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    
                    if attempt == max_retries:
                        logger.error(f"Function {func.__name__} failed after {max_retries + 1} attempts: {e}")
                        raise e
                    
                    wait_time = delay * (backoff_factor ** attempt)
                    logger.warning(f"Function {func.__name__} failed (attempt {attempt + 1}/{max_retries + 1}): {e}")
                    logger.info(f"Retrying in {wait_time:.1f} seconds...")
                    time.sleep(wait_time)
            
            # This should never be reached, but just in case
            raise last_exception
        
        return wrapper
    return decorator

def rate_limit(requests_per_minute: int = None):
    """
    Decorator for rate limiting API calls
    
    Args:
        requests_per_minute: Number of requests allowed per minute (default from config)
    """
    if requests_per_minute is None:
        requests_per_minute = config.requests_per_minute
    
    delay_between_calls = 60.0 / requests_per_minute
    
    def decorator(func: Callable) -> Callable:
        last_called = [0.0]  # Use list to make it mutable in closure
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            elapsed = time.time() - last_called[0]
            if elapsed < delay_between_calls:
                sleep_time = delay_between_calls - elapsed
                time.sleep(sleep_time)
            
            result = func(*args, **kwargs)
            last_called[0] = time.time()
            return result
        
        return wrapper
    return decorator

def safe_database_operation(func: Callable) -> Callable:
    """
    Decorator for safe database operations with automatic connection handling
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Any:
        logger = logging.getLogger('polygon_fetcher')
        
        try:
            return func(*args, **kwargs)
        except psycopg2.OperationalError as e:
            logger.error(f"Database operational error in {func.__name__}: {e}")
            raise
        except psycopg2.IntegrityError as e:
            logger.error(f"Database integrity error in {func.__name__}: {e}")
            raise
        except psycopg2.Error as e:
            logger.error(f"Database error in {func.__name__}: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in {func.__name__}: {e}")
            raise
    
    return wrapper

def log_execution_time(func: Callable) -> Callable:
    """
    Decorator to log function execution time
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Any:
        logger = logging.getLogger('polygon_fetcher')
        start_time = time.time()
        
        try:
            result = func(*args, **kwargs)
            execution_time = time.time() - start_time
            logger.debug(f"Function {func.__name__} completed in {execution_time:.2f} seconds")
            return result
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"Function {func.__name__} failed after {execution_time:.2f} seconds: {e}")
            raise
    
    return wrapper

def validate_ticker(ticker: str) -> bool:
    """
    Validate ticker symbol format
    
    Args:
        ticker: Ticker symbol to validate
        
    Returns:
        True if ticker is valid, False otherwise
    """
    if not ticker or not isinstance(ticker, str):
        return False
    
    # Basic validation: 1-5 uppercase letters
    ticker = ticker.strip().upper()
    return len(ticker) >= 1 and len(ticker) <= 5 and ticker.isalpha()

def format_timestamp(timestamp: int) -> datetime:
    """
    Convert Unix timestamp (milliseconds) to datetime object
    
    Args:
        timestamp: Unix timestamp in milliseconds
        
    Returns:
        datetime object in UTC
    """
    return datetime.fromtimestamp(timestamp / 1000, tz=timezone.utc)

def safe_float(value: Any) -> Optional[float]:
    """
    Safely convert value to float, returning None if conversion fails
    
    Args:
        value: Value to convert
        
    Returns:
        Float value or None
    """
    try:
        if value is None:
            return None
        return float(value)
    except (ValueError, TypeError):
        return None

def safe_int(value: Any) -> Optional[int]:
    """
    Safely convert value to int, returning None if conversion fails
    
    Args:
        value: Value to convert
        
    Returns:
        Integer value or None
    """
    try:
        if value is None:
            return None
        return int(value)
    except (ValueError, TypeError):
        return None

def get_database_stats() -> Dict[str, Any]:
    """
    Get database statistics for monitoring
    
    Returns:
        Dictionary with database statistics
    """
    from polygon_fetcher import PolygonDataFetcher
    
    try:
        fetcher = PolygonDataFetcher()
        stats = {}
        
        with fetcher.connect_db() as conn:
            with conn.cursor() as cur:
                # Get table row counts
                tables = ['stock_tickers', 'daily_aggregates', 'minute_aggregates', 
                         'trades', 'quotes', 'market_status', 'data_fetch_log']
                
                for table in tables:
                    cur.execute(f'SELECT COUNT(*) as count FROM "{table}"')
                    result = cur.fetchone()
                    stats[f'{table}_count'] = result['count'] if result else 0
                
                # Get latest data timestamps
                cur.execute("""
                    SELECT 
                        MAX(date) as latest_daily_date,
                        COUNT(DISTINCT ticker) as daily_tickers
                    FROM daily_aggregates
                """)
                result = cur.fetchone()
                if result:
                    stats['latest_daily_date'] = result['latest_daily_date']
                    stats['daily_tickers'] = result['daily_tickers']
                
                # Get recent fetch activity
                cur.execute("""
                    SELECT 
                        COUNT(*) as total_fetches,
                        COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_fetches,
                        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_fetches
                    FROM data_fetch_log
                    WHERE created_at > NOW() - INTERVAL '24 hours'
                """)
                result = cur.fetchone()
                if result:
                    stats['recent_total_fetches'] = result['total_fetches']
                    stats['recent_successful_fetches'] = result['successful_fetches']
                    stats['recent_failed_fetches'] = result['failed_fetches']
        
        return stats
        
    except Exception as e:
        logger = logging.getLogger('polygon_fetcher')
        logger.error(f"Failed to get database stats: {e}")
        return {}

def check_api_limits() -> Dict[str, Any]:
    """
    Check API usage and limits (placeholder for future implementation)
    
    Returns:
        Dictionary with API usage information
    """
    # This would require tracking API calls and potentially
    # calling Polygon's API to check usage limits
    # For now, return basic info
    return {
        'requests_per_minute_limit': config.requests_per_minute,
        'estimated_daily_requests': config.requests_per_minute * 60 * 24,
        'note': 'API usage tracking not implemented yet'
    }

class PolygonAPIError(Exception):
    """Custom exception for Polygon API errors"""
    pass

class DatabaseError(Exception):
    """Custom exception for database errors"""
    pass

class ConfigurationError(Exception):
    """Custom exception for configuration errors"""
    pass
