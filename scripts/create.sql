/**
* Отдел продаж "Cахалин"
*/

BEGIN;

CREATE TABLE "bank/e1" (
  id SERIAL PRIMARY KEY,
  license_number CHAR(20) NOT NULL UNIQUE,
  name VARCHAR(60) NOT NULL,
  address TEXT NOT NULL,
  country VARCHAR(60) NOT NULL
);

CREATE TYPE BUYER_TYPE AS ENUM ('магазин', 'оптовик',
  'предприятие сферы обслуживания');

CREATE TABLE "buyer/e2" (
  id SERIAL PRIMARY KEY,
  name VARCHAR(20) NOT NULL UNIQUE, -- AK
  country VARCHAR(60) NOT NULL,
  legal_address TEXT NOT NULL
);

CREATE TABLE "currency/e4" (
  currency_id CHAR(3) NOT NULL PRIMARY KEY,
  name VARCHAR(20) NOT NULL UNIQUE, -- AK
  comment TEXT NULL
);

CREATE TYPE BANK_ACCOUNT_TYPE AS ENUM ('коререспондетский', 'депозитный',
  'сберегательный');

CREATE TABLE "bank_account/e3" (
  id SERIAL PRIMARY KEY,
  bank_id INTEGER NOT NULL, -- FK
  holder_id INTEGER NOT NULL, -- FK
  category BANK_ACCOUNT_TYPE NOT NULL,
  currency_id CHAR(3) NOT NULL, -- FK

  CONSTRAINT bank_id FOREIGN KEY (bank_id) REFERENCES "bank/e1"(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT holder_id FOREIGN KEY (holder_id) REFERENCES "buyer/e2"(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency/e4"(currency_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE "exchange_rate/e5" (
  numerator CHAR(3) NOT NULL, --FK
  denominator CHAR(3) NOT NULL, --FK
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  value DECIMAL(6,2) NOT NULL,

  CHECK (value > 0),

  CONSTRAINT numerator FOREIGN KEY (numerator) REFERENCES "currency/e4"(currency_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT denominator FOREIGN KEY (denominator) REFERENCES "currency/e4"(currency_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE "payment_order/e6" (
  id SERIAL PRIMARY KEY,
  order_id CHAR(20) NOT NULL UNIQUE,
  sum DECIMAL(20) NOT NULL,
  sender INTEGER NOT NULL, -- FK
  destination INTEGER NOT NULL, -- FK
  currency_id CHAR(3) NOT NULL, -- FK
  created_at TIMESTAMP NOT NULL,

  CHECK (sum > 0),

  CONSTRAINT sender FOREIGN KEY (sender) REFERENCES "bank_account/e3"(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT destination FOREIGN KEY (destination) REFERENCES "bank_account/e3"(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency/e4"(currency_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE "product/e7" (
  id SERIAL PRIMARY KEY,
  article CHAR(20) NOT NULL UNIQUE, -- AK
  available_amount INTEGER NOT NULL,
  name VARCHAR(60) NOT NULL,
  certeficate_id CHAR(20) NULL,
  packaging VARCHAR(20) NOT NULL,
  fabricator VARCHAR(60) NOT NULL,
  price DECIMAL(9) NOT NULL,
  currency_id CHAR(3) NOT NULL, -- FK

  CHECK (available_amount > 0),
  CHECK (price > 0),

  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency/e4"(currency_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);


CREATE TABLE "invoice/e8" (
  id SERIAL PRIMARY KEY,
  buyer_id INTEGER NOT NULL, -- FK
  local_order_id INTEGER NULL, --FK
  currency_id CHAR(3) NOT NULL, -- FK
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  payed_at TIMESTAMP NULL,
  sum DECIMAL(20) NOT NULL,

  CHECK (sum > 0),

  CONSTRAINT buyer_id FOREIGN KEY (buyer_id) REFERENCES "buyer/e2"(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT local_order_id FOREIGN KEY (local_order_id) REFERENCES "payment_order/e6"(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES "currency/e4"(currency_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE "invoice/e8 product/e7" (
  invoice_id INTEGER REFERENCES "invoice/e8"(id),
  product_id INTEGER REFERENCES "product/e7"(id),
  quantity INTEGER NOT NULL,
  PRIMARY KEY (invoice_id, product_id)
);

ROLLBACK;
