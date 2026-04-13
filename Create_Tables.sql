/**
  * This script creates the necessary tables for the credit card transactions data warehouse.
  * It also includes triggers to calculate the checksum for each row in the staging table.
 */

-- Clean existing databases
USE master
GO

DROP DATABASE IF EXISTS CreaditCardTransactions_DW;
GO

DROP DATABASE IF EXISTS credit_card_transactions_dw;
GO

-- UTF8 (forget nvarchars), case-insensitive and accent sensitive
CREATE DATABASE credit_card_transactions_dw COLLATE Latin1_General_100_CI_AS_SC_UTF8;
GO

USE credit_card_transactions_dw
GO

-- Schemas
CREATE SCHEMA stage;
GO

CREATE SCHEMA dim;
GO

CREATE SCHEMA fact;
GO

CREATE SCHEMA dw;
GO

-- Create staging table (lax data types)
-- Ignore first column (row counter) and unix_time (invalid, 7 years difference)
CREATE TABLE stage.transactions (
    trans_date_trans_time VARCHAR(50),
    cc_num VARCHAR(50),
    merchant VARCHAR(150),
    category VARCHAR(50),
    amt VARCHAR(50),
    first VARCHAR(50),
    last VARCHAR(50),
    gender VARCHAR(10),
    street VARCHAR(255),
    city VARCHAR(50),
    state VARCHAR(5),
    zip VARCHAR(10),
    lat VARCHAR(20),
    long VARCHAR(20),
    city_pop VARCHAR(20),
    job VARCHAR(255),
    dob VARCHAR(20),
    trans_num VARCHAR(150),
    merch_lat VARCHAR(20),
    merch_long VARCHAR(20),
    is_fraud VARCHAR(5),
    merch_zipcode VARCHAR(10),
    dw_row_checksum VARCHAR(200) NULL,
    dw_run_id VARCHAR(50) NOT NULL,
    dw_updated_on DATETIME2 NOT NULL,
    dw_source_system VARCHAR(50) NOT NULL
);
GO

-- Create dimension tables (with appropriate data types)
CREATE TABLE dim.card_holder (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(150) NOT NULL,
    gender CHAR(1) NOT NULL,
    street VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state CHAR(2) NOT NULL,
    zip VARCHAR(10) NOT NULL,
    job VARCHAR(255) NOT NULL,
    birth_date DATE NOT NULL
);
GO

CREATE TABLE dim.merchant (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(150) NOT NULL,
    lat DECIMAL(10, 6) NOT NULL,
    long DECIMAL(10, 6) NOT NULL,
    zip VARCHAR(10) NULL
);
GO

CREATE TABLE dim.full_date (
    id INT PRIMARY KEY, -- YYYYMMDD format (e.g., 20260409)
    date DATE NOT NULL,
    day_of_month INT NOT NULL,
    day_of_week VARCHAR(20) NOT NULL,
    is_weekend BIT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL
);
GO

CREATE TABLE dim.category (
    id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);
GO

-- Create fact table (with foreign keys to dimension tables)
CREATE TABLE fact.credit_card_transaction (
    id BIGINT PRIMARY KEY IDENTITY(1,1),

    -- Transaction info
    trans_num VARCHAR(150) NOT NULL UNIQUE,
    credit_card_number VARCHAR(50) NOT NULL,
    age_at_transaction INT NOT NULL,
    lat DECIMAL(10, 6) NOT NULL,
    long DECIMAL(10, 6) NOT NULL,
    city_population INT NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    is_fraud BIT NOT NULL,
    time_stamp DATETIME2 NOT NULL,
    hour INT NOT NULL,
    dw_row_checksum VARCHAR(200) NULL,
    dw_run_id VARCHAR(50) NOT NULL,
    dw_updated_on DATETIME2 NOT NULL,
    dw_source_system VARCHAR(50) NOT NULL,

    -- FK
    date_id INT NOT NULL,
    card_holder_id BIGINT NOT NULL,
    merchant_id BIGINT NOT NULL,
    category_id INT NOT NULL,

    FOREIGN KEY (date_id) REFERENCES dim.full_date(id),
    FOREIGN KEY (card_holder_id) REFERENCES dim.card_holder(id),
    FOREIGN KEY (merchant_id) REFERENCES dim.merchant(id),
    FOREIGN KEY (category_id) REFERENCES dim.category(id)
);
GO

CREATE TABLE stage.transactions_processed (
    trans_num VARCHAR(150),
    credit_card_number VARCHAR(50),
    age_at_transaction INT,
    lat DECIMAL(10, 6),
    long DECIMAL(10, 6),
    city_population INT,
    amount DECIMAL(18, 2),
    is_fraud BIT,
    time_stamp DATETIME2,
    hour INT,
    date_id INT,
    card_holder_id BIGINT,
    merchant_id BIGINT,
    category_id INT,
    dw_row_checksum VARCHAR(64)
);
GO

-- Create audit table to track ETL runs
CREATE TABLE dw.audit(
	run_id VARCHAR(50) PRIMARY KEY,
	start_on DATETIME2 NOT NULL,
	end_on DATETIME2 NULL,
	name VARCHAR(50) NOT NULL,
	success_row_count BIGINT NULL,
	failed_row_count BIGINT NULL,
	execution_status VARCHAR(20) NOT NULL
);
GO