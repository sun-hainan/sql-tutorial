-- ================================================================
-- 模块十四：触发器
-- ================================================================

-- Q1: 什么是触发器？如何创建触发器？

-- 【解答】
-- 触发器（TRIGGER）：与表关联的自动执行的存储过程，当表发生特定事件（INSERT/UPDATE/DELETE）时自动触发
-- 创建：CREATE TRIGGER trigger_name BEFORE|AFTER event ON table_name FOR EACH ROW BEGIN ... END

-- 【原理】
-- 触发器与表绑定，表上的INSERT/UPDATE/DELETE事件会自动触发触发器。
-- BEFORE触发器在事件执行前触发，常用于数据验证和修改。
-- AFTER触发器在事件执行后触发，常用于审计日志。
-- FOR EACH ROW表示行级触发器，每行受影响都会触发。

-- 【示例】
DROP DATABASE IF EXISTS trigger_demo;
CREATE DATABASE trigger_demo;
USE trigger_demo;

CREATE TABLE t_product (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    price DECIMAL(10,2),
    stock INT
);
INSERT INTO t_product (name, price, stock) VALUES
    ('Laptop', 5000, 10), ('Mouse', 99, 100), ('Keyboard', 299, 50);

-- 创建触发器：插入订单时自动扣减库存
CREATE TABLE t_order_log (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    quantity INT,
    order_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER tr_after_order_insert
AFTER INSERT ON t_order_log
FOR EACH ROW
BEGIN
    UPDATE t_product SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
END//
DELIMITER ;

-- 插入订单，触发器自动扣减库存
INSERT INTO t_order_log (product_id, quantity) VALUES (1, 2);
SELECT * FROM t_product WHERE id = 1;  -- 库存从10变成8

-- ================================================================
-- Q2: NEW和OLD引用是什么？如何使用？

-- 【解答】
-- NEW：引用新插入或更新后的行（INSERT和UPDATE时可用）
-- OLD：引用被更新前或删除前的行（UPDATE和DELETE时可用）

-- 【原理】
-- INSERT触发器：NEW可用，OLD不可用
-- UPDATE触发器：NEW和OLD都可用（NEW是新值，OLD是旧值）
-- DELETE触发器：OLD可用，NEW不可用
-- BEFORE触发器可以修改NEW的值（影响最终写入的数据）

-- 【示例】
USE trigger_demo;

-- 审计日志表
CREATE TABLE t_audit_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    action VARCHAR(20),
    old_data TEXT,
    new_data TEXT,
    action_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- INSERT的审计触发器
DELIMITER //
CREATE TRIGGER tr_product_insert_audit
AFTER INSERT ON t_product
FOR EACH ROW
BEGIN
    INSERT INTO t_audit_log (table_name, action, new_data)
    VALUES ('t_product', 'INSERT', CONCAT('id=', NEW.id, ', name=', NEW.name, ', price=', NEW.price));
END//
DELIMITER ;

-- UPDATE的审计触发器
DELIMITER //
CREATE TRIGGER tr_product_update_audit
AFTER UPDATE ON t_product
FOR EACH ROW
BEGIN
    INSERT INTO t_audit_log (table_name, action, old_data, new_data)
    VALUES (
        't_product',
        'UPDATE',
        CONCAT('id=', OLD.id, ', price=', OLD.price, ', stock=', OLD.stock),
        CONCAT('id=', NEW.id, ', price=', NEW.price, ', stock=', NEW.stock)
    );
END//
DELIMITER ;

-- DELETE的审计触发器
DELIMITER //
CREATE TRIGGER tr_product_delete_audit
AFTER DELETE ON t_product
FOR EACH ROW
BEGIN
    INSERT INTO t_audit_log (table_name, action, old_data)
    VALUES ('t_product', 'DELETE', CONCAT('id=', OLD.id, ', name=', OLD.name));
END//
DELIMITER ;

-- 测试触发器
INSERT INTO t_product (name, price, stock) VALUES ('Monitor', 1299, 30);
UPDATE t_product SET price = 1199 WHERE id = 4;
DELETE FROM t_product WHERE id = 4;
SELECT * FROM t_audit_log;

-- ================================================================
-- Q3: 触发器在数据联动中的应用？

-- 【解答】
-- 典型应用：库存自动扣减、账户余额更新、订单状态同步、计数器维护

-- 【原理】
-- 触发器可以保证数据一致性，当某表变化时自动更新关联表。
-- 适合场景：需要跨表同步、但又不是简单的一对一关系。
-- 注意：触发器的事务在MySQL中和操作在同一事务中，失败会一起ROLLBACK。

-- 【示例】
USE trigger_demo;

-- 场景1：订单状态同步
CREATE TABLE t_order (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50),
    status VARCHAR(20),
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT INTO t_order (customer_name, status) VALUES
    ('Alice', 'pending'), ('Bob', 'pending');

CREATE TABLE t_order_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    change_time DATETIME
);

DELIMITER //
CREATE TRIGGER tr_order_status_change
AFTER UPDATE ON t_order
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO t_order_history (order_id, old_status, new_status, change_time)
        VALUES (NEW.order_id, OLD.status, NEW.status, NOW());
    END IF;
END//
DELIMITER ;

UPDATE t_order SET status = 'paid' WHERE order_id = 1;
UPDATE t_order SET status = 'shipped' WHERE order_id = 1;
SELECT * FROM t_order_history;

-- 场景2：多表联动（订单和订单明细）
CREATE TABLE t_order_main (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    total_amount DECIMAL(10,2)
);
CREATE TABLE t_order_detail (
    detail_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_name VARCHAR(50),
    quantity INT,
    subtotal DECIMAL(10,2)
);

CREATE TABLE t_stock (
    product_name VARCHAR(50) PRIMARY KEY,
    stock INT
);
INSERT INTO t_stock VALUES ('Laptop', 10), ('Mouse', 100);

DELIMITER //
CREATE TRIGGER tr_order_detail_insert
AFTER INSERT ON t_order_detail
FOR EACH ROW
BEGIN
    -- 更新库存
    UPDATE t_stock SET stock = stock - NEW.quantity WHERE product_name = NEW.product_name;
    -- 更新订单总金额
    UPDATE t_order_main SET total_amount = total_amount + NEW.subtotal WHERE order_id = NEW.order_id;
END//
DELIMITER ;

INSERT INTO t_order_main VALUES (1, 0);
INSERT INTO t_order_detail VALUES (1, 1, 'Laptop', 1, 5000);
INSERT INTO t_order_detail VALUES (2, 1, 'Mouse', 2, 198);
SELECT * FROM t_order_main;  -- total_amount = 5198
SELECT * FROM t_stock;        -- Laptop=9, Mouse=98

-- ================================================================
-- Q4: 触发器在审计中的应用？

-- 【解答】
-- 审计：记录谁在什么时候对什么数据做了什么修改
-- 触发器可以自动记录所有变更到审计表，实现数据可追溯

-- 【原理】
-- 审计触发器通常在AFTER INSERT/UPDATE/DELETE上绑定。
-- 审计表记录：操作类型、操作时间、操作者（从应用层传入或会话变量）、旧值和新值。
-- 可以通过JSON字段存储完整的变更前后数据。

-- 【示例】
USE trigger_demo;

-- 完整审计表设计
CREATE TABLE t_audit_full (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_pk VARCHAR(100),           -- 主键值（可能多列）
    action VARCHAR(20) NOT NULL,      -- INSERT/UPDATE/DELETE
    old_values JSON,
    new_values JSON,
    operation_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    operator VARCHAR(50)             -- 操作人（需要应用层设置）
);

-- 通用审计触发器函数（简化版）
DELIMITER //
CREATE TRIGGER tr_audit_product
AFTER INSERT ON t_product
FOR EACH ROW
BEGIN
    INSERT INTO t_audit_full (table_name, record_pk, action, new_values)
    VALUES ('t_product', NEW.id, 'INSERT', JSON_OBJECT('id', NEW.id, 'name', NEW.name, 'price', NEW.price));
END//

CREATE TRIGGER tr_audit_product_update
AFTER UPDATE ON t_product
FOR EACH ROW
BEGIN
    INSERT INTO t_audit_full (table_name, record_pk, action, old_values, new_values)
    VALUES (
        't_product',
        CAST(OLD.id AS CHAR),
        'UPDATE',
        JSON_OBJECT('price', OLD.price, 'stock', OLD.stock),
        JSON_OBJECT('price', NEW.price, 'stock', NEW.stock)
    );
END//

CREATE TRIGGER tr_audit_product_delete
AFTER DELETE ON t_product
FOR EACH ROW
BEGIN
    INSERT INTO t_audit_full (table_name, record_pk, action, old_values)
    VALUES ('t_product', OLD.id, 'DELETE', JSON_OBJECT('id', OLD.id, 'name', OLD.name));
END//
DELIMITER ;

-- 测试
INSERT INTO t_product (name, price, stock) VALUES ('Monitor', 1299, 20);
UPDATE t_product SET price = 1199 WHERE id = 5;
DELETE FROM t_product WHERE id = 5;

SELECT * FROM t_audit_full;

-- ================================================================
-- Q5: 触发器的性能影响和注意事项？

-- 【解答】
-- 性能影响：每个DML操作都会额外执行触发器，可能拖慢批量操作
-- 注意事项：递归触发、触发器顺序、异常处理、跨库触发器不支持

-- 【原理】
-- 触发器执行在DML的同一个事务中，如果触发器执行慢，整体操作就慢。
-- 递归触发：A触发B，B又触发A，可能导致死循环。
-- MySQL不支持跨数据库的触发器。
-- BEFORE触发器中可以修改NEW的值，但不能修改OLD。

-- 【示例】
USE trigger_demo;

-- 递归触发示例（错误演示）
-- CREATE TABLE t_counter (name VARCHAR(50) PRIMARY KEY, cnt INT);
-- INSERT INTO t_counter VALUES ('orders', 0);
-- CREATE TRIGGER tr_counter_insert AFTER INSERT ON t_order_log FOR EACH ROW
-- BEGIN
--     UPDATE t_counter SET cnt = cnt + 1 WHERE name = 'orders';
-- END;
-- 正常情况下不会递归，但要注意复杂的触发器链

-- BEFORE触发器修改数据
CREATE TABLE t_user_birth (
    id INT PRIMARY KEY,
    birth_year INT,
    birth_month INT,
    age INT
);

DELIMITER //
CREATE TRIGGER tr_before_user_insert
BEFORE INSERT ON t_user_birth
FOR EACH ROW
BEGIN
    -- 自动计算年龄（基于当前年份）
    SET NEW.age = YEAR(CURDATE()) - NEW.birth_year;
END//
DELIMITER ;

INSERT INTO t_user_birth (id, birth_year, birth_month) VALUES (1, 1990, 5);
SELECT * FROM t_user_birth;  -- age字段自动计算

-- ================================================================
-- Q6: 如何查看、修改和删除触发器？

-- 【解答】
-- 查看：SHOW CREATE TRIGGER trigger_name / SHOW TRIGGERS / INFORMATION_SCHEMA.TRIGGERS
-- 修改：先DROP再CREATE（或CREATE OR REPLACE MySQL 8.0+）
-- 删除：DROP TRIGGER [IF EXISTS] trigger_name

-- 【原理】
-- 触发器存放在 INFORMATION_SCHEMA.TRIGGERS 表中。
-- 修改触发器必须先DROP再CREATE，不能直接ALTER。
-- MySQL 8.0+支持CREATE OR REPLACE简化修改。
-- 删除表时，该表上的触发器也会自动删除。

-- 【示例】
USE trigger_demo;

-- 查看所有触发器
SHOW TRIGGERS;
SHOW TRIGGERS FROM trigger_demo;

-- 查看特定触发器定义
SHOW CREATE TRIGGER tr_product_insert_audit;

-- 从系统表查看
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_STATEMENT
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'trigger_demo';

-- 删除触发器
DROP TRIGGER IF EXISTS tr_product_insert_audit;
DROP TRIGGER IF EXISTS tr_product_update_audit;
DROP TRIGGER IF EXISTS tr_product_delete_audit;

-- 修改触发器（MySQL 8.0+）
DROP TRIGGER IF EXISTS tr_after_order_insert;
CREATE TRIGGER tr_after_order_insert
AFTER INSERT ON t_order_log
FOR EACH ROW
BEGIN
    UPDATE t_product SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
END//
DELIMITER ;

-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================
-- | 特性            | MySQL               | PostgreSQL           | Oracle              | SQLite              |
-- |---------------|---------------------|---------------------|---------------------|--------------------|
-- | 触发时机        | BEFORE/AFTER        | BEFORE/AFTER/INSTEAD OF | BEFORE/AFTER      | 不支持              |
-- | 触发事件        | INSERT/UPDATE/DELETE | INSERT/UPDATE/DELETE | INSERT/UPDATE/DELETE | 不支持              |
-- | FOR EACH ROW  | 支持                | 支持                  | 支持                 | 不支持              |
-- | 行级触发器      | FOR EACH ROW        | FOR EACH ROW          | FOR EACH ROW         | 不支持              |
-- | 语句级触发器    | 不支持（MySQL仅行级）| 支持                  | 支持                 | 不支持              |
-- | 跨库触发器      | 不支持              | 支持                   | 支持                 | 不支持              |
-- | 触发器内事务    | 与DML同一事务       | 同MySQL                | 同MySQL              | 不支持              |
-- | 递归触发        | 可能（需避免）        | 可控制                  | 可控制               | 不支持              |
-- | INSTEAD OF     | 不支持（仅MySQL 8.0+视图上支持） | 支持 | 支持 | 不支持 |

-- PostgreSQL语句级触发器（MySQL不支持）：
-- CREATE TRIGGER tr_test
-- FOR EACH STATEMENT  -- MySQL会报错
-- EXECUTE FUNCTION my_trigger_func();

-- Oracle INSTEAD OF触发器（用于可更新视图）：
-- CREATE OR REPLACE TRIGGER tr_v_emp
-- INSTEAD OF INSERT ON v_emp
-- FOR EACH ROW
-- BEGIN
--     INSERT INTO emp(id, name) VALUES(:NEW.id, :NEW.name);
-- END;

-- MySQL视图INSTEAD OF触发器（8.0.0+）：
-- CREATE TRIGGER tr_v_emp INSTEAD OF INSERT ON v_emp
-- FOR EACH ROW
-- BEGIN
--     INSERT INTO emp(id, name) VALUES(NEW.id, NEW.name);
-- END;

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 创建一张订单表和一张库存表，当插入订单时自动扣减对应商品的库存，
--    用触发器实现这一联动逻辑。

-- 2. 创建审计日志表，写一个INSERT的BEFORE触发器：
--    在插入用户表之前，自动将用户名转换为小写并记录操作时间。

-- 3. 创建UPDATE触发器，当员工工资变化时，自动向工资变更日志表插入一条记录，
--    包含旧工资、新工资、变更时间。

-- 4. 用SHOW TRIGGERS查看当前数据库的所有触发器，
--    并从INFORMATION_SCHEMA.TRIGGERS查询触发器的触发事件（INSERT/UPDATE/DELETE）和所属表。

-- 5. 删除已创建的触发器，再重建它（模拟修改触发器的过程），
--    验证删除和重建后触发器是否正常工作。
