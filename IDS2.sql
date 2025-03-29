DROP TABLE Person CASCADE CONSTRAINTS;
DROP TABLE Customer CASCADE CONSTRAINTS;
DROP TABLE Employee CASCADE CONSTRAINTS;
DROP TABLE bill_tab CASCADE CONSTRAINTS;
DROP TABLE tTable CASCADE CONSTRAINTS;
DROP TABLE lounge CASCADE CONSTRAINTS;
DROP TABLE reservation CASCADE CONSTRAINTS;
DROP TABLE tOrder CASCADE CONSTRAINTS;
DROP TABLE tProduct CASCADE CONSTRAINTS;
DROP TABLE order_item CASCADE CONSTRAINTS;
------------------------------------------------------------------

--The all knowing to do list
---- 1. Create tables
---- 2. Integrity constraints
---- 3. Fill tables with examples


------------------------------------------------------------------
-- Generalization/Specialization: Person is a general entity with shared attributes.
-- Customer and Employee are subtypes, implemented using shared primary key strategy.
-- This ensures that each customer/employee is also a valid person. 
-- Unfortunately, this means person can exist by themselves. Or an employee can be a customer too.
-- The subtype tables use the same primary key as Person and reference it via a foreign key.

-- The column `person_id` in table `Person` represents the Czech birth number,
-- stored in the standard '' format.
-- A CHECK constraint validates its birth number using a regular expression.
CREATE TABLE Person (
    person_id VARCHAR(11) PRIMARY KEY, -- 'YYMMDD/XXXX' - format of cz birth number
    name VARCHAR(20),
    tel VARCHAR(15),
    email VARCHAR(50),
    CHECK (REGEXP_LIKE(person_id, '^[0-9]{6}/[0-9]{4}$')) -- minimal format check
);

CREATE TABLE Customer (
    person_id VARCHAR(11) PRIMARY KEY, -- Why is it in the DB? To make sure they are above drinking age.
    FOREIGN KEY (person_id) REFERENCES Person(person_id),
    loyalty_tier VARCHAR(20)
);

CREATE TABLE Employee (
    person_id VARCHAR(11) PRIMARY KEY,
    FOREIGN KEY (person_id) REFERENCES Person(person_id),
    position VARCHAR(30)
);


CREATE TABLE bill_tab (
    tab_id INT PRIMARY KEY,
    tab_sum DECIMAL(10, 2)
);

CREATE TABLE tTable (
    tTable_id INT PRIMARY KEY,
    capacity INTEGER
);

CREATE TABLE lounge (
    lounge_id INTEGER PRIMARY KEY,
    capacity INTEGER,
    services VARCHAR(50) -- large enough to put in various services
);

CREATE TABLE reservation (
    reservation_id INT PRIMARY KEY,
    date_time DATE,
    number_of_persons INTEGER,
    duration INTEGER
);
------------------------------------------------------------------
CREATE TABLE tOrder (
    tOrder_id INTEGER PRIMARY KEY,
    date_time DATE
);

CREATE TABLE tProduct (
    product_id VARCHAR(9) PRIMARY KEY, -- to simulate a barcode number
    name VARCHAR(50),
    price DECIMAL(10, 2)
);

-- junction table between tProduct and tOrder
CREATE TABLE order_item (
    tOrder_id INTEGER,
    product_id VARCHAR(50),
    quantity INTEGER NOT NULL,

    PRIMARY KEY (tOrder_id, product_id),
    FOREIGN KEY (tOrder_id) REFERENCES tOrder(tOrder_id),
    FOREIGN KEY (product_id) REFERENCES tProduct(product_id)
);
------------------------------------------------------------------

------------------------------------------------------------------
-------------------------- TEST ----------------------------------
------------------------------------------------------------------
-- Employ some ... employees
INSERT INTO Person 
VALUES ('921231/4343', 'Jackie Welles', '+420934929422', 'JackWels@gmail.com');
INSERT INTO Employee
VALUES ('921231/4343', 'Head Cheff');

INSERT INTO Person 
VALUES ('640902/4242', 'Keanu Reeves', '+903303429443', 'KenRev@matrix.com');
INSERT INTO Employee
VALUES ('640902/4242', 'Security');

-- Add some customers
INSERT INTO Person 
VALUES ('600411/1212', 'Jeremy Clarkson', '+949494040393', 'Clark@GrandTour.com');
INSERT INTO Customer
VALUES ('600411/1212', 'Jezza');

INSERT INTO Person 
VALUES ('630116/1213', 'James May', '+934234234234', 'May@GrandTour.com');
INSERT INTO Customer
VALUES ('630116/1213', 'Captain Slow');

INSERT INTO Person 
VALUES ('691219/4242', 'Richard Hammond', '+90444555444', 'Hamm@GrandTour.com');
INSERT INTO Customer
VALUES ('691219/4242', 'The Hamster');
-- Populate lounge with two lounges
INSERT INTO lounge VALUES (1, 10, 'VIP seating');
INSERT INTO lounge VALUES (2, 20, 'Live music');
-- Populate tTable with enough tables to consider it a restaurant
INSERT INTO tTable VALUES (1, 5);
INSERT INTO tTable VALUES (2, 2);
INSERT INTO tTable VALUES (3, 3);
INSERT INTO tTable VALUES (4, 5);
INSERT INTO tTable VALUES (5, 4);
INSERT INTO tTable VALUES (6, 4);
INSERT INTO tTable VALUES (7, 5);
INSERT INTO tTable VALUES (8, 5);
-- Populate tProduct with products - maybe automated generating? - Barcodes must be unique
INSERT INTO tProduct VALUES ('000000001', 'Grilled Cheese',  9.50);
INSERT INTO tProduct VALUES ('000000002', 'French Fries',    4.20);
INSERT INTO tProduct VALUES ('000000003', 'Cordon Bleu',     11.55);
INSERT INTO tProduct VALUES ('000000004', 'Lasagna',         10.50);
INSERT INTO tProduct VALUES ('000000005', 'French Pancakes', 7.20);
INSERT INTO tProduct VALUES ('000000006', 'Schnitzel',       12.10);
INSERT INTO tProduct VALUES ('000000007', 'Kofola',          2.10);
INSERT INTO tProduct VALUES ('000000008', 'Water',           120.99);
-- Create an order
------------------------------------------------------------------
COMMIT;

-- get all employee
SELECT * FROM Employee e JOIN Person p ON e.person_id = p.person_id;
-- get all customers
SELECT * FROM Customer c JOIN Person p ON c.person_id = p.person_id;

SELECT * FROM tProduct; 