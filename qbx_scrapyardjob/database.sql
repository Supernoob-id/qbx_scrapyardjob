CREATE TABLE IF NOT EXISTS scrapyard_locations (
  id VARCHAR(50) NOT NULL,
  label VARCHAR(100) NOT NULL,
  coords JSON NULL,
  pickup_location JSON NULL,
  dropoff_location JSON NULL,
  enabled TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_businesses (
  id VARCHAR(50) NOT NULL,
  location_id VARCHAR(50) NOT NULL,
  owner_citizenid VARCHAR(50) NOT NULL,
  ownership_type ENUM('purchase','rental') NOT NULL,
  status ENUM('active','suspended','expired') NOT NULL DEFAULT 'active',
  bank_account_id VARCHAR(100) NOT NULL,
  purchase_price BIGINT NOT NULL DEFAULT 0,
  rental_price BIGINT NOT NULL DEFAULT 0,
  lease_started_at BIGINT NOT NULL DEFAULT 0,
  lease_expires_at BIGINT NOT NULL DEFAULT 0,
  grace_expires_at BIGINT NOT NULL DEFAULT 0,
  last_rent_payment_at BIGINT NOT NULL DEFAULT 0,
  active_location_id VARCHAR(50) GENERATED ALWAYS AS (CASE WHEN status IN ('active','suspended') THEN location_id ELSE NULL END) STORED,
  PRIMARY KEY (id), UNIQUE KEY uq_scrapyard_active_location (active_location_id),
  KEY idx_scrapyard_owner_status (owner_citizenid,status), KEY idx_scrapyard_lease (status,ownership_type,lease_expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_employees (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  business_id VARCHAR(50) NOT NULL,
  citizenid VARCHAR(50) NOT NULL,
  grade TINYINT UNSIGNED NOT NULL DEFAULT 0,
  hired_at BIGINT NOT NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_scrapyard_employee (business_id,citizenid), KEY idx_scrapyard_employee_citizen (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_auctions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  model VARCHAR(80) NOT NULL,
  vehicle_class TINYINT UNSIGNED NOT NULL,
  price BIGINT NOT NULL,
  status ENUM('available','sold','expired','disabled') NOT NULL DEFAULT 'available',
  pickup_location JSON NULL,
  listed_at BIGINT NOT NULL,
  expires_at BIGINT NOT NULL,
  PRIMARY KEY (id), KEY idx_scrapyard_auction_status (status,expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_vehicles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  business_id VARCHAR(50) NOT NULL,
  auction_id BIGINT UNSIGNED NOT NULL,
  purchased_by VARCHAR(50) NOT NULL,
  model VARCHAR(80) NOT NULL,
  vehicle_class TINYINT UNSIGNED NOT NULL,
  plate VARCHAR(12) NOT NULL,
  purchase_price BIGINT NOT NULL,
  status ENUM('awaiting_pickup','in_transit','delivered','scrapped') NOT NULL DEFAULT 'awaiting_pickup',
  pickup_location JSON NULL,
  vehicle_net_id INT UNSIGNED NULL,
  pickup_started_at BIGINT NOT NULL DEFAULT 0,
  delivered_at BIGINT NOT NULL DEFAULT 0,
  scrapped_at BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (id), UNIQUE KEY uq_scrapyard_plate (plate), UNIQUE KEY uq_scrapyard_auction_sale (auction_id), KEY idx_scrapyard_business_stock (business_id,status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  business_id VARCHAR(50) NOT NULL,
  transaction_id VARCHAR(100) NOT NULL,
  title VARCHAR(120) NOT NULL,
  amount BIGINT NOT NULL,
  transaction_type ENUM('deposit','withdraw') NOT NULL,
  issuer VARCHAR(50) NOT NULL,
  created_at BIGINT NOT NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_scrapyard_transaction_id (transaction_id), KEY idx_scrapyard_transactions (business_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_scrap_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  business_id VARCHAR(50) NULL,
  citizenid VARCHAR(50) NOT NULL,
  plate VARCHAR(12) NOT NULL,
  model VARCHAR(80) NOT NULL,
  rewards JSON NOT NULL,
  created_at BIGINT NOT NULL,
  PRIMARY KEY (id), KEY idx_scrapyard_scrap_player (citizenid,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_player_cooldowns (
  citizenid VARCHAR(50) NOT NULL,
  expires_at BIGINT NOT NULL,
  PRIMARY KEY (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS scrapyard_vehicle_cooldowns (
  plate VARCHAR(12) NOT NULL,
  expires_at BIGINT NOT NULL,
  PRIMARY KEY (plate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
