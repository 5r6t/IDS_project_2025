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

DROP SEQUENCE tTable_num;
DROP SEQUENCE lounge_num;
DROP SEQUENCE bill_num;
------------------------------------------------------------------

-- 1. Create tables
-- 2. Integrity constraints
-- 3. Fill tables with examples

------------------------------------------------------------------
-- Generalization/Specialization: Person is a general entity with shared attributes.
-- Customer and Employee are subtypes, implemented using shared primary key strategy.
-- The column `person_id` in table `Person` represents the Czech birth number.
-- A CHECK constraint validates its birth number using a regular expression.
CREATE TABLE Person (
    person_id VARCHAR(11) PRIMARY KEY, -- 'YYMMDD/XXXX' format
    name VARCHAR(20),
    tel VARCHAR(15),
    email VARCHAR(50),
    CHECK (REGEXP_LIKE(person_id, '^[0-9]{6}/[0-9]{4}$'))
);

CREATE TABLE Customer (
    person_id VARCHAR(11) PRIMARY KEY,
    FOREIGN KEY (person_id) REFERENCES Person(person_id),
    loyalty_tier VARCHAR(20)
);

CREATE TABLE Employee (
    person_id VARCHAR(11) PRIMARY KEY,
    FOREIGN KEY (person_id) REFERENCES Person(person_id),
    position VARCHAR(30)
);

CREATE TABLE tTable (
    tTable_id INT PRIMARY KEY,
    capacity INTEGER
);

CREATE TABLE lounge (
    lounge_id INTEGER PRIMARY KEY,
    capacity INTEGER,
    services VARCHAR(50)
);

CREATE TABLE reservation (
    reservation_id INT PRIMARY KEY,
    date_time DATE,
    number_of_persons INTEGER,
    duration INTEGER,
    customer_id VARCHAR(11),
    tTable_id INT,
    lounge_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(person_id),
    FOREIGN KEY (tTable_id) REFERENCES tTable(tTable_id),
    FOREIGN KEY (lounge_id) REFERENCES lounge(lounge_id),
    CHECK (
        (tTable_id IS NOT NULL AND lounge_id IS NULL) OR
        (tTable_id IS NULL AND lounge_id IS NOT NULL)
    )
);

------------------------------------------------------------------
CREATE TABLE bill_tab (
    tab_id INT PRIMARY KEY,
    tab_sum DECIMAL(10, 2),
    tTable_id INT,
    lounge_id INT,
    FOREIGN KEY (tTable_id) REFERENCES tTable(tTable_id),
    FOREIGN KEY (lounge_id) REFERENCES lounge(lounge_id),
    CHECK (
        (tTable_id IS NOT NULL AND lounge_id IS NULL) OR
        (tTable_id IS NULL AND lounge_id IS NOT NULL)
    )
);

CREATE TABLE tOrder (
    tOrder_id INTEGER PRIMARY KEY,
    date_time DATE,
    tab_id INT NOT NULL,
    employee_id VARCHAR(11),
    FOREIGN KEY (tab_id) REFERENCES bill_tab(tab_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(person_id)
);


CREATE TABLE tProduct (
    product_id VARCHAR(9) PRIMARY KEY,
    name VARCHAR(50),
    price DECIMAL(10, 2)
);

CREATE TABLE order_item (
    tOrder_id INTEGER,
    product_id VARCHAR(50),
    quantity INTEGER NOT NULL,
    PRIMARY KEY (tOrder_id, product_id),
    FOREIGN KEY (tOrder_id) REFERENCES tOrder(tOrder_id),
    FOREIGN KEY (product_id) REFERENCES tProduct(product_id)
);
------------------------------------------------------------------
-- TEST DATA
------------------------------------------------------------------
-- Employees
INSERT INTO Person VALUES ('921231/4343', 'Jackie Welles', '+420934929422', 'JackWels@arasaka.com');
INSERT INTO Employee VALUES ('921231/4343', 'Head Cheff');

INSERT INTO Person VALUES ('640902/6646', 'Keanu Reeves', '+903303429443', 'KenRev@matrix.com');
INSERT INTO Employee VALUES ('640902/6646', 'Security');

INSERT INTO Person VALUES ('640107/5544', 'Nicolas Cage', '+934111089999', 'NicCage@holywood.com');
INSERT INTO Employee VALUES ('640107/5544', 'Waiter');

INSERT INTO Person VALUES ('670726/3232', 'Jason Statham', '+944030333944', 'J.StatHam@Crank.com');
INSERT INTO Employee VALUES ('670726/3232', 'Waiter');

-- Customers
INSERT INTO Person VALUES ('001131/0000', 'Henry of Skalitz', '+000000000001', 'Henry@Skalitz.com');
INSERT INTO Customer VALUES ('001131/0000', 'Hungry');

INSERT INTO Person VALUES ('600411/1212', 'Jeremy Clarkson', '+949494040393', 'Clark@GrandTour.com');
INSERT INTO Customer VALUES ('600411/1212', 'Jezza');

INSERT INTO Person VALUES ('630116/1213', 'James May', '+934234234234', 'May@GrandTour.com');
INSERT INTO Customer VALUES ('630116/1213', 'Captain Slow');

INSERT INTO Person VALUES ('691219/4242', 'Richard Hammond', '+90444555444', 'Hamm@GrandTour.com');
INSERT INTO Customer VALUES ('691219/4242', 'The Hamster');

-- Sequences
CREATE SEQUENCE lounge_num START WITH 1 INCREMENT BY 1;
INSERT INTO lounge VALUES (lounge_num.NEXTVAL, 10, 'VIP seating');
INSERT INTO lounge VALUES (lounge_num.NEXTVAL, 20, 'Live music');

CREATE SEQUENCE tTable_num START WITH 1 INCREMENT BY 1;
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 5);
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 2);
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 3);
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 5);
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 4);
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 4);
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 5);
INSERT INTO tTable VALUES (tTable_num.NEXTVAL, 5);

-- Menu: Products
INSERT INTO tProduct VALUES ('000000001', 'Grilled Cheese',  9.50);
INSERT INTO tProduct VALUES ('000000002', 'French Fries',    4.20);
INSERT INTO tProduct VALUES ('000000003', 'Cordon Bleu',     11.55);
INSERT INTO tProduct VALUES ('000000004', 'Lasagna',         10.50);
INSERT INTO tProduct VALUES ('000000005', 'French Pancakes', 7.20);
INSERT INTO tProduct VALUES ('000000006', 'Schnitzel',       12.10);
INSERT INTO tProduct VALUES ('000000007', 'Kofola',          2.10);
INSERT INTO tProduct VALUES ('000000008', 'Water',           120.99);

-- Tabs
-- CREATE SEQUENCE bill_num START WITH 1 INCREMENT BY 1;

INSERT INTO bill_tab (tab_id, tTable_id, lounge_id) 
VALUES (1, 1, NULL); -- bill for table 1

INSERT INTO bill_tab VALUES (2, 2, NULL); -- bill for table 2
INSERT INTO bill_tab VALUES (3, NULL, 1); -- bill for lounge 1  

-- Orders
INSERT INTO tOrder (tOrder_id, date_time, tab_id, employee_id)
VALUES (1, TO_DATE('2025-03-29 04:19:10', 'YYYY-MM-DD HH24:MI:SS'), 1, '921231/4343'); -- Jackie made an order for tab1

INSERT INTO tOrder 
VALUES (2, TO_DATE('2025-03-30 05:19:10', 'YYYY-MM-DD HH24:MI:SS'), 2, '670726/3232'); -- Nick made this one for tab2

INSERT INTO tOrder 
VALUES (3, TO_DATE('2025-03-30 06:19:10', 'YYYY-MM-DD HH24:MI:SS'), 3, '640107/5544'); -- Nick, tab3 (lounge)

-- Order items first order - tab1 - table1
INSERT INTO order_item (tOrder_id, product_id, quantity) VALUES (1, '000000004', 1); -- Lasagna 1x
INSERT INTO order_item VALUES (1, '000000007', 2); -- Kofola 2x
INSERT INTO order_item VALUES (1, '000000008', 1); -- Water 1x
-- INSERT INTO order_item VALUES (1, '000000007', 2); -- Kofola 2x would be weird, make new order or update

-- Order items second order - tab2 - table2
INSERT INTO order_item VALUES (2, '000000008', 1); -- Water 1x,

-- Order items third order - tab3 - lounge1
INSERT INTO order_item VALUES (3, '000000006', 3); -- Schnitzel 3x,
INSERT INTO order_item VALUES (3, '000000007', 3); -- Kofola 3x,

COMMIT;

SELECT * FROM Employee e JOIN Person p ON e.person_id = p.person_id;
SELECT * FROM Customer c JOIN Person p ON c.person_id = p.person_id;
SELECT * FROM tProduct;
SELECT * FROM tTable;
SELECT * FROM lounge;
SELECT * FROM bill_tab;

--- Specific tab
SELECT
    o.tOrder_id,
    o.date_time,
    p.name AS product_name,
    oi.quantity,
    tp.price,
    (oi.quantity * tp.price) AS total_price
FROM tOrder o
JOIN order_item oi ON o.tOrder_id = oi.tOrder_id
JOIN tProduct tp ON oi.product_id = tp.product_id
JOIN tProduct p ON tp.product_id = p.product_id
WHERE o.tab_id = 1;  -- Content of all orders in a single tab specified

--- Total sum of tab
SELECT
    o.tab_id,
    SUM(oi.quantity * tp.price) AS tab_total
FROM tOrder o
JOIN order_item oi ON o.tOrder_id = oi.tOrder_id
JOIN tProduct tp ON oi.product_id = tp.product_id
WHERE o.tab_id = 1 -- Desired tab
GROUP BY o.tab_id;

--- Orders for table
SELECT
    o.tOrder_id,
    o.date_time,
    o.employee_id,
    bt.tTable_id
FROM tOrder o
JOIN bill_tab bt ON o.tab_id = bt.tab_id
WHERE bt.tTable_id = 2;  -- Replace with your desired table ID

--- Orders for lounge
SELECT
    o.tOrder_id,
    o.date_time,
    o.employee_id,
    bt.lounge_id
FROM tOrder o
JOIN bill_tab bt ON o.tab_id = bt.tab_id
WHERE bt.lounge_id = 1;  -- Replace with your desired lounge ID
