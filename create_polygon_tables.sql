-- PostgreSQL Database Schema for Polygon.io Stock Market Data
-- This script creates tables for storing stock market data from Polygon.io API

\echo 'Creating Polygon.io stock market data tables...'

-- Create Table for Stock Tickers (Reference Data)
\echo 'Creating stock_tickers table...'
CREATE TABLE IF NOT EXISTS "stock_tickers" (
  "ticker" VARCHAR(20) PRIMARY KEY,
  "name" TEXT,
  "market" VARCHAR(10),
  "locale" VARCHAR(10),
  "primary_exchange" VARCHAR(10),
  "type" VARCHAR(20),
  "active" BOOLEAN DEFAULT TRUE,
  "currency_name" VARCHAR(10),
  "cik" VARCHAR(20),
  "composite_figi" VARCHAR(20),
  "share_class_figi" VARCHAR(20),
  "last_updated_utc" TIMESTAMP,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
\echo 'stock_tickers table created successfully.'

-- Create Table for Daily Aggregates (OHLCV data)
\echo 'Creating daily_aggregates table...'
CREATE TABLE IF NOT EXISTS "daily_aggregates" (
  "id" SERIAL PRIMARY KEY,
  "ticker" VARCHAR(20) NOT NULL,
  "date" DATE NOT NULL,
  "open" NUMERIC(15, 4),
  "high" NUMERIC(15, 4),
  "low" NUMERIC(15, 4),
  "close" NUMERIC(15, 4),
  "volume" BIGINT,
  "vwap" NUMERIC(15, 4),
  "timestamp" BIGINT,
  "transactions" INTEGER,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("ticker") REFERENCES "stock_tickers"("ticker"),
  UNIQUE("ticker", "date")
);
\echo 'daily_aggregates table created successfully.'

-- Create Table for Minute Aggregates (for intraday data)
\echo 'Creating minute_aggregates table...'
CREATE TABLE IF NOT EXISTS "minute_aggregates" (
  "id" SERIAL PRIMARY KEY,
  "ticker" VARCHAR(20) NOT NULL,
  "timestamp" BIGINT NOT NULL,
  "datetime" TIMESTAMP NOT NULL,
  "open" NUMERIC(15, 4),
  "high" NUMERIC(15, 4),
  "low" NUMERIC(15, 4),
  "close" NUMERIC(15, 4),
  "volume" BIGINT,
  "vwap" NUMERIC(15, 4),
  "transactions" INTEGER,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("ticker") REFERENCES "stock_tickers"("ticker"),
  UNIQUE("ticker", "timestamp")
);
\echo 'minute_aggregates table created successfully.'

-- Create Table for Trades
\echo 'Creating trades table...'
CREATE TABLE IF NOT EXISTS "trades" (
  "id" SERIAL PRIMARY KEY,
  "ticker" VARCHAR(20) NOT NULL,
  "timestamp" BIGINT NOT NULL,
  "datetime" TIMESTAMP NOT NULL,
  "timeframe" VARCHAR(20),
  "price" NUMERIC(15, 4),
  "size" BIGINT,
  "conditions" INTEGER[],
  "exchange" INTEGER,
  "participant_timestamp" BIGINT,
  "sequence_number" BIGINT,
  "sip_timestamp" BIGINT,
  "trf_id" INTEGER,
  "trf_timestamp" BIGINT,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("ticker") REFERENCES "stock_tickers"("ticker")
);
\echo 'trades table created successfully.'

-- Create Table for Quotes
\echo 'Creating quotes table...'
CREATE TABLE IF NOT EXISTS "quotes" (
  "id" SERIAL PRIMARY KEY,
  "ticker" VARCHAR(20) NOT NULL,
  "timestamp" BIGINT NOT NULL,
  "datetime" TIMESTAMP NOT NULL,
  "timeframe" VARCHAR(20),
  "bid" NUMERIC(15, 4),
  "bid_size" BIGINT,
  "ask" NUMERIC(15, 4),
  "ask_size" BIGINT,
  "exchange" INTEGER,
  "participant_timestamp" BIGINT,
  "sequence_number" BIGINT,
  "sip_timestamp" BIGINT,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("ticker") REFERENCES "stock_tickers"("ticker")
);
\echo 'quotes table created successfully.'

-- Create Table for Market Status
\echo 'Creating market_status table...'
CREATE TABLE IF NOT EXISTS "market_status" (
  "id" SERIAL PRIMARY KEY,
  "market" VARCHAR(20) NOT NULL,
  "server_time" TIMESTAMP,
  "exchanges" JSONB,
  "currencies" JSONB,
  "early_hours" BOOLEAN,
  "market_open" BOOLEAN,
  "after_hours" BOOLEAN,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE("market", "server_time")
);
\echo 'market_status table created successfully.'

-- Create Table for Data Fetch Log (for monitoring)
\echo 'Creating data_fetch_log table...'
CREATE TABLE IF NOT EXISTS "data_fetch_log" (
  "id" SERIAL PRIMARY KEY,
  "fetch_type" VARCHAR(50) NOT NULL,
  "ticker" VARCHAR(20),
  "start_date" DATE,
  "end_date" DATE,
  "records_fetched" INTEGER DEFAULT 0,
  "status" VARCHAR(20) DEFAULT 'started',
  "error_message" TEXT,
  "fetch_duration_seconds" NUMERIC(10, 2),
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "completed_at" TIMESTAMP
);
\echo 'data_fetch_log table created successfully.'

-- Create indexes for better performance
\echo 'Creating indexes...'
CREATE INDEX IF NOT EXISTS "idx_daily_aggregates_ticker_date" ON "daily_aggregates"("ticker", "date");
CREATE INDEX IF NOT EXISTS "idx_minute_aggregates_ticker_datetime" ON "minute_aggregates"("ticker", "datetime");
CREATE INDEX IF NOT EXISTS "idx_trades_ticker_datetime" ON "trades"("ticker", "datetime");
CREATE INDEX IF NOT EXISTS "idx_quotes_ticker_datetime" ON "quotes"("ticker", "datetime");
CREATE INDEX IF NOT EXISTS "idx_data_fetch_log_created_at" ON "data_fetch_log"("created_at");
CREATE INDEX IF NOT EXISTS "idx_data_fetch_log_ticker_type" ON "data_fetch_log"("ticker", "fetch_type");
\echo 'Indexes created successfully.'

-- Create a function to update the updated_at timestamp
\echo 'Creating update timestamp function...'
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_stock_tickers_updated_at BEFORE UPDATE ON "stock_tickers" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_aggregates_updated_at BEFORE UPDATE ON "daily_aggregates" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_minute_aggregates_updated_at BEFORE UPDATE ON "minute_aggregates" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
\echo 'Triggers created successfully.'

\echo 'Polygon.io database schema created successfully!'
\echo 'Tables created: stock_tickers, daily_aggregates, minute_aggregates, trades, quotes, market_status, data_fetch_log'
\echo 'Indexes and triggers have been set up for optimal performance.'
