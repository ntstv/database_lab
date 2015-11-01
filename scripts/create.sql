/**
* Отдел продаж "Cахалин"
*/

CREATE DATABASE lab;

BEGIN;

SET search_path TO test1;

CREATE TABLE "bank" (
  id SERIAL PRIMARY KEY,
  license_number CHAR(20) NOT NULL UNIQUE,
  name VARCHAR(60) NOT NULL,
  address TEXT NOT NULL,
  country VARCHAR(60) NOT NULL
);

CREATE TYPE BUYER_TYPE AS ENUM ('магазин', 'оптовик',
  'предприятие сферы обслуживания');

CREATE TABLE "buyer" (
  id SERIAL PRIMARY KEY,
  name VARCHAR(60) NOT NULL,
  license_number VARCHAR(20) NOT NULL UNIQUE, -- AK
  country VARCHAR(60) NOT NULL,
  legal_address TEXT NOT NULL
);

CREATE TABLE "currency" (
  currency_id CHAR(3) NOT NULL PRIMARY KEY,
  name VARCHAR(20) NOT NULL UNIQUE, -- AK
  country VARCHAR(60) NOT NULL,
  comment TEXT NULL
);

CREATE TYPE BANK_ACCOUNT_TYPE AS ENUM ('коререспондетский', 'депозитный',
  'сберегательный');

CREATE TABLE "bank_account" (
  id SERIAL PRIMARY KEY,
  bank_id INTEGER NOT NULL, -- FK
  holder_id INTEGER NOT NULL, -- FK
  category BANK_ACCOUNT_TYPE NOT NULL,
  currency_id CHAR(3) NOT NULL, -- FK

  CONSTRAINT bank_id FOREIGN KEY (bank_id) REFERENCES "bank"(id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

  CONSTRAINT holder_id FOREIGN KEY (holder_id) REFERENCES "buyer"(id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency"(currency_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

CREATE TABLE "exchange_rate" (
  numerator CHAR(3) NOT NULL, --FK
  denominator CHAR(3) NOT NULL, --FK
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  value DECIMAL(6,2) NOT NULL,

  CHECK (value > 0),
  CHECK (numerator != denominator),

  CONSTRAINT composite_key PRIMARY KEY (numerator, denominator, created_at),

  CONSTRAINT numerator FOREIGN KEY (numerator) REFERENCES "currency"(currency_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

  CONSTRAINT denominator FOREIGN KEY (denominator) REFERENCES "currency"(currency_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

CREATE TABLE "payment_order" ( -- E6
  id SERIAL PRIMARY KEY,
  order_id CHAR(20) NOT NULL UNIQUE,
  sum DECIMAL(20) NOT NULL,
  sender INTEGER NOT NULL, -- FK
  destination INTEGER NOT NULL, -- FK
  currency_id CHAR(3) NOT NULL, -- FK
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  invoice_id INTEGER NULL

  CHECK (sum > 0),
  CHECK (sender != destination),

  CONSTRAINT sender FOREIGN KEY (sender) REFERENCES "bank_account"(id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

  CONSTRAINT destination FOREIGN KEY (destination) REFERENCES "bank_account"(id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency"(currency_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION

  CONSTRAINT invoice_id FOREIGN KEY (invoice_id) REFERENCES "invoice"(invoice_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

CREATE TABLE "product" ( -- E7
  id SERIAL PRIMARY KEY,
  article CHAR(20) NOT NULL UNIQUE, -- AK
  available_amount INTEGER NOT NULL,
  name VARCHAR(60) NOT NULL,
  certeficate_id CHAR(20) NULL,
  packaging VARCHAR(20) NOT NULL,
  fabricator VARCHAR(60) NOT NULL,
  price DECIMAL(9) NOT NULL,
  currency_id CHAR(3) NOT NULL, -- FK

  CHECK (available_amount >= 0),
  CHECK (price > 0),

  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency"(currency_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);


CREATE TABLE "invoice" ( --E8
  id SERIAL PRIMARY KEY,
  buyer_id INTEGER NOT NULL, -- FK
  currency_id CHAR(3) NOT NULL, -- FK
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  sum DECIMAL(20) NOT NULL,

  CHECK (sum > 0),

  CONSTRAINT buyer_id FOREIGN KEY (buyer_id) REFERENCES "buyer"(id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,


  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency"(currency_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

CREATE TABLE "invoice_product" ( --E8/E9
  invoice_id INTEGER REFERENCES "invoice"(id),
  product_id INTEGER REFERENCES "product"(id),
  quantity INTEGER NOT NULL,
  PRIMARY KEY (invoice_id, product_id)
);

ROLLBACK;
-- COMMIT;
