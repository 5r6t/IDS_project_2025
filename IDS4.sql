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
DROP SEQUENCE order_seq;

---------------------------------------------------------------------------------
--======================= CREATE TABLES FOR OBJECTS =============================
---------------------------------------------------------------------------------

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
    position VARCHAR(20)
);

CREATE TABLE tTable (
    table_id INT PRIMARY KEY,
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
    duration INTEGER, -- minutes
    customer_id VARCHAR(11),
    table_id INT,
    lounge_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(person_id),
    FOREIGN KEY (table_id) REFERENCES tTable(table_id),
    FOREIGN KEY (lounge_id) REFERENCES lounge(lounge_id),
    CHECK (
        (table_id IS NOT NULL AND lounge_id IS NULL) OR
        (table_id IS NULL AND lounge_id IS NOT NULL)
    )
);

CREATE TABLE bill_tab (
    tab_id INT PRIMARY KEY,
    table_id INT,
    lounge_id INT,
    sum DECIMAL(10, 2) DEFAULT 0,
    FOREIGN KEY (table_id) REFERENCES tTable(table_id),
    FOREIGN KEY (lounge_id) REFERENCES lounge(lounge_id),
    CHECK (
        (table_id IS NOT NULL AND lounge_id IS NULL) OR
        (table_id IS NULL AND lounge_id IS NOT NULL)
    )
);
--- Automatic PK generation if none provided
--- start
CREATE SEQUENCE order_seq
START WITH 1
INCREMENT BY 1;

CREATE TABLE tOrder (
    "order_id" INT PRIMARY KEY,
    date_time DATE,
    tab_id INT NOT NULL,
    employee_id VARCHAR(11),
    FOREIGN KEY (tab_id) REFERENCES bill_tab(tab_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(person_id)
);

CREATE TABLE tProduct (
    product_id VARCHAR(9) PRIMARY KEY,
    name VARCHAR(20),
    price DECIMAL(10, 2)
);

CREATE TABLE order_item (
    "order_id" INTEGER,
    product_id VARCHAR(50),
    quantity INTEGER NOT NULL,
    PRIMARY KEY ("order_id", product_id),
    FOREIGN KEY ("order_id") REFERENCES tOrder("order_id"),
    FOREIGN KEY (product_id) REFERENCES tProduct(product_id)
);


---------------------------------------------------------------------------------
--======================= RIGHTS TO TABLES (and wrongs)==========================
---------------------------------------------------------------------------------
GRANT ALL ON Customer TO xhajekj00; 

---------------------------------------------------------------------------------
--=============================== TRIGGERS ======================================
---------------------------------------------------------------------------------
/**
 * @brief inserts an valid order id, had it not been provided
*/
CREATE OR REPLACE TRIGGER trg_order_id
BEFORE INSERT ON tOrder
FOR EACH ROW
WHEN (NEW."order_id" IS NULL)
BEGIN
    SELECT order_seq.NEXTVAL INTO :NEW."order_id" FROM dual;
END;
/

/**
 * @brief checks for an already existing/conflicting reservation 
*/
CREATE OR REPLACE TRIGGER trg_reservation_id
BEFORE INSERT ON reservation
FOR EACH ROW
DECLARE
    v_exists number;
BEGIN
    IF :NEW.table_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists
        FROM reservation
        WHERE table_id = :NEW.table_id
        AND :NEW.date_time BETWEEN date_time AND (date_time + (duration / 1440)); -- 1440 min in day

        IF v_exists > 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'Table is already reserved this time');
        END IF; 
    END IF;

    IF :NEW.lounge_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists
        FROM reservation
        WHERE lounge_id = :NEW.lounge_id
        AND :NEW.date_time BETWEEN date_time AND (date_time + (duration / 1440)); -- 1440 min in day

        IF v_exists > 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'Lounge is already reserved for this time');
        END IF; 
    END IF;

END;
/

/**
 * @brief updates tabs sum when order_item is updated/created for an order related to 
 the tab
*/
CREATE OR REPLACE TRIGGER trg_order_sum_to_tab
BEFORE INSERT ON order_item
FOR EACH ROW
DECLARE
    v_price tProduct.price%TYPE;
BEGIN
    SELECT price INTO v_price
    FROM tProduct tp
    WHERE product_id = :NEW.product_id;
    

    UPDATE bill_tab
    SET sum = sum + (v_price * :NEW.quantity)
    WHERE tab_id = (SELECT tab_id FROM tOrder WHERE "order_id" = :NEW."order_id");
END;
/

---------------------------------------------------------------------------------
--============================== PROCEDURES =====================================
---------------------------------------------------------------------------------
/**
 * @brief inserts both person and employee into the system
 * Does not handle already existing peolpe
*/
CREATE OR REPLACE PROCEDURE insert_employee (
    p_person_id IN VARCHAR2,
    p_name IN VARCHAR2,
    p_tel IN VARCHAR2,
    p_email IN VARCHAR2,
    p_position IN VARCHAR2
) AS
BEGIN
    INSERT INTO Person (person_id, name, tel, email)
    VALUES (p_person_id, p_name, p_tel, p_email);

    INSERT INTO Employee (person_id, position)
    VALUES (p_person_id, p_position);
END;
/

/**
 * @brief inserts both person and customer into the system
 * Does not handle already existing people !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/
CREATE OR REPLACE PROCEDURE insert_customer (
    p_person_id IN VARCHAR2,
    p_name IN VARCHAR2,
    p_tel IN VARCHAR2,
    p_email IN VARCHAR2,
    p_loyalty_tier IN VARCHAR2
) AS
BEGIN
    INSERT INTO Person (person_id, name, tel, email)
    VALUES (p_person_id, p_name, p_tel, p_email);

    INSERT INTO Customer (person_id, loyalty_tier)
    VALUES (p_person_id, p_loyalty_tier);
END;
/

/**
 * @brief this procedure deletes all orders that belong to a specific tab
 * Possible use-case is for when the tab is paid, the information about it's
 * contents are no longer needed.
*/
CREATE OR REPLACE PROCEDURE proc_delete_orders(
    p_tab_id IN bill_tab.tab_id%TYPE) 
    AS
    v_order tOrder%ROWTYPE;

    CURSOR c_orders IS
        SELECT * FROM tOrder WHERE tab_id = p_tab_id;
BEGIN
    FOR v_order IN c_orders LOOP
        DELETE FROM order_item WHERE "order_id" = v_order."order_id";
        DELETE FROM tOrder WHERE "order_id" = v_order."order_id";
    END LOOP;

    DBMS_OUTPUT.put_line('Orders for tab_id : ' || p_tab_id);
END;
/

---------------------------------------------------------------------------------
--=========================== INSERT TEST DATA ==================================
---------------------------------------------------------------------------------
BEGIN
    insert_employee('921231/4343', 'Jackie Welles', '+420934929422', 'JackWels@arasaka.com', 'Head Cheff');
    insert_employee('640902/6646', 'Keanu Reeves', '+903303429443', 'KenRev@matrix.com','Security');
    insert_employee('640107/5544', 'Nicolas Cage', '+934111089999', 'NicCage@holywood.com', 'Waiter');
    insert_employee('670726/3232', 'Jason Statham', '+944030333944', 'J.StatHam@Crank.com', 'Waiter');
    --
    insert_customer('001131/0000', 'Henry of Skalitz', '+000000000001', 'Henry@Skalitz.com', 'Hungry');
    insert_customer('600411/1212', 'Jeremy Clarkson', '+949494040393', 'Clark@GrandTour.com', 'Jezza');
    insert_customer('630116/1213', 'James May', '+934234234234', 'May@GrandTour.com', 'Captain Slow');
    insert_customer('691219/4242', 'Richard Hammond', '+90444555444', 'Hamm@GrandTour.com', 'The Hamster');
END;
/

-- Menu: Products
INSERT INTO tProduct VALUES ('000000001', 'Grilled Cheese',  9.50);
INSERT INTO tProduct VALUES ('000000002', 'French Fries',    4.20);
INSERT INTO tProduct VALUES ('000000003', 'Cordon Bleu',     11.55);
INSERT INTO tProduct VALUES ('000000004', 'Lasagna',         10.50);
INSERT INTO tProduct VALUES ('000000005', 'French Pancakes', 7.20);
INSERT INTO tProduct VALUES ('000000006', 'Schnitzel',       12.10);
INSERT INTO tProduct VALUES ('000000007', 'Kofola',          2.10);
INSERT INTO tProduct VALUES ('000000008', 'Water',           120.99);

-- Lounges and tables
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

-- Reservations
INSERT INTO reservation (
    reservation_id,
    date_time,
    number_of_persons,
    duration,
    customer_id,
    table_id,
    lounge_id
) VALUES (
    1,
    TO_DATE('2025-03-30 19:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    2,
    120,  -- minutes (2 hours)
    '600411/1212',  -- Jeremy
    1, -- Table 1
    NULL
);

INSERT INTO reservation VALUES (
    2, TO_DATE('2025-04-30 16:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    2, 120, '630116/1213',  3, NULL
);

INSERT INTO reservation VALUES (
    3, TO_DATE('2025-04-01 20:30:00', 'YYYY-MM-DD HH24:MI:SS'),
    8, 180, '691219/4242',  NULL, 2
);

INSERT INTO reservation VALUES (
    4, TO_DATE('2025-06-01 20:30:00', 'YYYY-MM-DD HH24:MI:SS'),
    8, 180, '691219/4242',  NULL, 2  -- lounge 2
);

-- Tabs
CREATE SEQUENCE bill_num START WITH 1 INCREMENT BY 1;

INSERT INTO bill_tab (tab_id, table_id, lounge_id) 
VALUES (bill_num.NEXTVAL, 1, NULL); -- bill for table 1

INSERT INTO bill_tab (tab_id, table_id, lounge_id) VALUES (bill_num.NEXTVAL, 2, NULL); -- bill for table 2
INSERT INTO bill_tab (tab_id, table_id, lounge_id) VALUES (bill_num.NEXTVAL, NULL, 1); -- bill for lounge 1  

-- Orders
INSERT INTO tOrder (date_time, tab_id, employee_id)
VALUES (TO_DATE('2025-03-29 04:19:10', 'YYYY-MM-DD HH24:MI:SS'), 1, '921231/4343'); -- Jackie made an order for tab1

INSERT INTO tOrder (date_time, tab_id, employee_id)
VALUES (TO_DATE('2025-03-29 05:19:10', 'YYYY-MM-DD HH24:MI:SS'), 2, '640107/5544'); -- Nick made this one for tab2

INSERT INTO tOrder (date_time, tab_id, employee_id)
VALUES (TO_DATE('2025-03-30 06:19:10', 'YYYY-MM-DD HH24:MI:SS'), 3, '640107/5544'); -- Nick, tab3 (lounge)

INSERT INTO tOrder (date_time, tab_id, employee_id)
VALUES (TO_DATE('2025-03-30 06:40:10', 'YYYY-MM-DD HH24:MI:SS'), 3, '670726/3232'); -- Jason, tab3 (lounge)

INSERT INTO tOrder ("order_id", date_time, tab_id, employee_id)
VALUES (200, TO_DATE('2025-03-31 06:46:40', 'YYYY-MM-DD HH24:MI:SS'), 3, '640107/5544'); -- Nick, tab3 (lounge)

-- Order items first order - tab1 - table1
INSERT INTO order_item ("order_id", product_id, quantity) 
VALUES (1, '000000004', 1); -- Lasagna 1x

---------------------------------------------------------------------------------
--================== trg_order_sum_to_tab - DEMONSTRATION =======================
---------------------------------------------------------------------------------
SELECT * FROM bill_tab
WHERE tab_id = 1;

INSERT INTO order_item VALUES (1, '000000007', 2); -- Kofola 2x
INSERT INTO order_item VALUES (1, '000000008', 1); -- Water 1x

SELECT * FROM bill_tab
WHERE tab_id = 1;

-- Order items second order - tab2 - table2
INSERT INTO order_item VALUES (2, '000000008', 1); -- Water 1x,

-- Order items third order - tab3 - lounge1
INSERT INTO order_item VALUES (3, '000000006', 3); -- Schnitzel 3x,
INSERT INTO order_item VALUES (3, '000000007', 3); -- Kofola 3x,
-- lounge1 makes new order
INSERT INTO order_item VALUES (4, '000000004', 2); -- Lasagna 3x,
INSERT INTO order_item VALUES (4, '000000007', 6); -- Kofola 6x,

---------------------------------------------------------------------------------
--====================== delete_orders -- DEMNOSTRATION =========================
---------------------------------------------------------------------------------
SELECT
    o.tab_id,
    SUM(oi.quantity * tp.price) AS "SUM",
    bt.table_id,
    bt.lounge_id
FROM tOrder o
JOIN order_item oi ON o."order_id" = oi."order_id"
JOIN tProduct tp ON oi.product_id = tp.product_id
JOIN bill_tab bt ON o.tab_id = bt.tab_id
GROUP BY o.tab_id, bt.table_id, bt.lounge_id;


BEGIN
    proc_delete_orders(2);
END;
/

SELECT
    o.tab_id,
    SUM(oi.quantity * tp.price) AS "SUM",
    bt.table_id,
    bt.lounge_id
FROM tOrder o
JOIN order_item oi ON o."order_id" = oi."order_id"
JOIN tProduct tp ON oi.product_id = tp.product_id
JOIN bill_tab bt ON o.tab_id = bt.tab_id
GROUP BY o.tab_id, bt.table_id, bt.lounge_id;

COMMIT;

---------------------------------------------------------------------------------
--======================== EXPLAIN PLAN DEMNOSTRATION ===========================
---------------------------------------------------------------------------------
EXPLAIN PLAN FOR
SELECT * FROM reservation WHERE table_id = 1 AND date_time > SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

CREATE INDEX idx_res_table_date ON reservation(table_id, date_time);

EXPLAIN PLAN FOR
SELECT * FROM reservation WHERE table_id = 1 AND date_time > SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/* PLAN_TABLE_OUTPUT
---------------------------------------------------------------------------------
| Id  | Operation         | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |             |     1 |    81 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| RESERVATION |     1 |    81 |     3   (0)| 00:00:01 |
---------------------------------------------------------------------------------
 
PLAN_TABLE_OUTPUT
----------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                    |     1 |    81 |     0   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| RESERVATION        |     1 |    81 |     0   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_RES_TABLE_DATE |     1 |       |     0   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------
-- CPU cost has been reduced
*/