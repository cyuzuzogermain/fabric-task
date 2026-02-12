-- ============================================
-- MoMo SMS Database Setup Script
-- Team: EWDGroup-13
-- ============================================

CREATE DATABASE IF NOT EXISTS momo_sms_db;
USE momo_sms_db;

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS system_logs;
DROP TABLE IF EXISTS transaction_tags;
DROP TABLE IF EXISTS user_transactions;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS transaction_categories;
DROP TABLE IF EXISTS users;

-- ============================================
-- TABLE: users
-- Stores people who send or receive money
-- ============================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    id_number VARCHAR(50) NULL COMMENT 'National ID for KYC',
    date_of_birth DATE NULL COMMENT 'DOB for KYC verification',
    user_type ENUM('individual', 'business', 'agent') NOT NULL DEFAULT 'individual',
    current_balance DECIMAL(15,2) DEFAULT 0.00,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,

    CONSTRAINT chk_phone_format CHECK (phone_number REGEXP '^250[0-9]{9}$'),
    CONSTRAINT unique_id_number UNIQUE (id_number)
);

CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_type ON users(user_type);

-- ============================================
-- TABLE: transaction_categories
-- The types of MoMo transactions
-- ============================================

CREATE TABLE transaction_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    category_code VARCHAR(20) NOT NULL UNIQUE,
    direction ENUM('inbound', 'outbound', 'internal') NOT NULL,
    description TEXT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);


-- ============================================
-- TABLE: transactions
-- Main table for all MoMo transactions
-- ============================================

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_ref VARCHAR(50) NOT NULL UNIQUE,
    category_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    fee DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(10) NOT NULL DEFAULT 'RWF',
    transaction_date DATETIME NOT NULL,
    raw_sms TEXT NULL,
    status ENUM('pending', 'completed', 'failed', 'reversed') NOT NULL DEFAULT 'completed',
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,

    CONSTRAINT chk_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_fee_valid CHECK (fee >= 0),

    FOREIGN KEY (category_id) REFERENCES transaction_categories(category_id)
);

CREATE INDEX idx_trans_date ON transactions(transaction_date);
CREATE INDEX idx_trans_category ON transactions(category_id);
CREATE INDEX idx_trans_status ON transactions(status);

-- ============================================
-- TABLE: user_transactions (Junction Table)
-- Links users to transactions with their role
-- ============================================

CREATE TABLE user_transactions (
    user_transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    transaction_id INT NOT NULL,
    role ENUM('sender', 'receiver') NOT NULL,
    balance_snapshot DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY unique_user_transaction (user_id, transaction_id),

    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE
);

CREATE INDEX idx_user_trans_user ON user_transactions(user_id);
CREATE INDEX idx_user_trans_trans ON user_transactions(transaction_id);

-- ============================================
-- TABLE: tags
-- Labels for transactions
-- ============================================

CREATE TABLE tags (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(50) NOT NULL UNIQUE,
    color_code VARCHAR(10) NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- ============================================
-- TABLE: transaction_tags (Junction Table)
-- Links transactions to tags (many-to-many)
-- ============================================

CREATE TABLE transaction_tags (
    transaction_tag_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    tag_id INT NOT NULL,
    added_by VARCHAR(50) NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY unique_transaction_tag (transaction_id, tag_id),

    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id)
);

-- ============================================
-- TABLE: system_logs
-- Logs from processing the XML
-- Also stores failed SMS in raw_content
-- ============================================

CREATE TABLE system_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NULL,
    log_level ENUM('info', 'warning', 'error', 'critical') NOT NULL,
    action VARCHAR(100) NOT NULL,
    details TEXT NULL,
    raw_content TEXT NULL COMMENT 'Stores raw SMS that failed to parse (dead letter)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL
);

CREATE INDEX idx_logs_level ON system_logs(log_level);

-- ============================================
-- INSERT SAMPLE DATA
-- ============================================

-- Sample categories
INSERT INTO transaction_categories (category_name, category_code, direction, description) VALUES
('Incoming Transfer', 'INCOMING', 'inbound', 'Money received from another user'),
('P2P Transfer', 'P2P', 'outbound', 'Person to person transfer'),
('Cash Withdrawal', 'WITHDRAW', 'outbound', 'Cash withdrawal from agent'),
('Payment to Code', 'PAYMENT', 'outbound', 'Payment using merchant code'),
('Airtime Purchase', 'AIRTIME', 'outbound', 'Airtime top-up');

-- Sample users with KYC
INSERT INTO users (phone_number, full_name, id_number, date_of_birth, user_type, current_balance) VALUES
('250788123456', 'Jean Pierre Habimana', '1199880012345678', '1988-05-15', 'individual', 52000.00),
('250788111222', 'Marie Claire Uwase', '1199285012345678', '1992-08-20', 'individual', 35000.00),
('250788333444', 'Emmanuel Ndayisaba', NULL, NULL, 'business', 120000.00);

-- Sample tags
INSERT INTO tags (tag_name, color_code) VALUES
('Personal', '#3498db'),
('Business', '#2ecc71'),
('Urgent', '#e74c3c');

-- Sample transaction
INSERT INTO transactions (transaction_ref, category_id, amount, fee, currency, transaction_date, raw_sms) VALUES
('12345678901', 4, 5000.00, 0.00, 'RWF', '2025-01-15 10:30:00', 'TxId:12345678901*Payment of 5,000 RWF to SHOP123*Balance:52,000 RWF');

-- Sample user_transaction
INSERT INTO user_transactions (user_id, transaction_id, role, balance_snapshot) VALUES
(1, 1, 'sender', 52000.00);

-- Sample logs (including a failed SMS in dead letter)
INSERT INTO system_logs (transaction_id, log_level, action, details, raw_content) VALUES
(1, 'info', 'SMS_PARSED', 'Successfully parsed payment transaction', NULL),
(NULL, 'error', 'PARSE_FAILED', 'Could not extract transaction data', 'Invalid SMS content that could not be parsed - missing transaction ID');
