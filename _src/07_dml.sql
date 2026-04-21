-- ================================================================
-- 模块七：增删改数据
-- ================================================================

-- Q1: INSERT的几种语法和用法？

-- 【解答】
-- 单行插入：INSERT INTO tbl (cols) VALUES (vals)
-- 多行插入：INSERT INTO tbl (cols) VALUES (vals1), (vals2), ...
-- 插入查询结果：INSERT INTO tbl SELECT ...
-- REPLACE INTO：若唯一键冲突则先删后插

-- 【原理】
-- INSERT需要考虑：列的顺序、默认值、是否允许NULL、自增列的处理
-- MySQL中INSERT可以配合ON DUPLICATE KEY UPDATE实现"有则更新，无则插入"

-- 【示例】
DROP DATABASE IF EXISTS dml_demo;
CREATE DATABASE dml_demo;
USE dml_demo;

CREATE TABLE t_student (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    age INT DEFAULT 18,
    email VARCHAR(100) UNIQUE,
    status VARCHAR(20) DEFAULT 'active',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 1. 标准单行插入（指定所有列）
INSERT INTO t_student (name, age, email, status) VALUES ('Alice', 20, 'alice@example.com', 'active');

-- 2. 省略列（使用默认值）
INSERT INTO t_student (name, email) VALUES ('Bob', 'bob@example.com');
-- age使用DEFAULT=18, status使用DEFAULT='active'

-- 3. 多行插入（一次插入多条，高效）
INSERT INTO t_student (name, age, email) VALUES
    ('Carol', 22, 'carol@example.com'),
    ('David', 19, 'david@example.com'),
    ('Eve', 25, 'eve@example.com');

-- 4. 插入查询结果（INSERT SELECT）
CREATE TABLE t_student_backup LIKE t_student;
INSERT INTO t_student_backup SELECT * FROM t_student WHERE status = 'active';

-- 5. SET语法（列名=值的形式，更清晰）
INSERT INTO t_student SET name='Frank', email='frank@example.com', age=30;

-- 6. REPLACE INTO（若唯一键冲突则先删后插）
CREATE TABLE t_session (
    session_id VARCHAR(50) PRIMARY KEY,
    user_id INT,
    last_active DATETIME
);
REPLACE INTO t_session VALUES ('ABC123', 1, NOW());
REPLACE INTO t_session VALUES ('ABC123', 2, NOW());  -- 先删除session_id='ABC123'的记录，再插入新记录
SELECT * FROM t_session;  -- 只有1条记录，user_id=2

-- 7. INSERT IGNORE（若唯一键冲突则忽略，不报错）
INSERT IGNORE INTO t_student (name, email) VALUES ('Alice2', 'alice@example.com');
-- email重复，忽略这条插入

SELECT * FROM t_student;

-- ================================================================
-- Q2: UPDATE语句的用法和注意事项？

-- 【解答】
-- UPDATE tbl SET col1=val1, col2=val2 WHERE condition
-- 可以同时更新多个列，用逗号分隔
-- 可以使用表达式、函数、运算

-- 【原理】
-- UPDATE受事务控制，可以用ROLLBACK回滚。
-- 如果不带WHERE条件，会更新表中所有行（非常危险！）。
-- 可以配合ORDER BY和LIMIT实现部分更新。
-- 不要在UPDATE的SET子句中直接引用被更新的同一行（避免微妙的副作用）。

-- 【示例】
USE dml_demo;

CREATE TABLE t_product (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    price DECIMAL(10,2),
    stock INT,
    status VARCHAR(20)
);
INSERT INTO t_product (name, price, stock, status) VALUES
    ('Laptop', 5000.00, 100, 'active'),
    ('Mouse', 99.00, 500, 'active'),
    ('Keyboard', 299.00, 200, 'discontinued'),
    ('Monitor', 1299.00, 50, 'active');

-- 基础更新
UPDATE t_product SET price = 4799.00 WHERE id = 1;

-- 批量更新（使用表达式）
UPDATE t_product SET price = price * 0.9 WHERE status = 'active' AND price > 500;

-- 同时更新多个列
UPDATE t_product SET price = 1099.00, stock = stock - 10 WHERE id = 4;

-- 使用LIMIT限制更新行数（MySQL特有）
UPDATE t_product SET status = 'pending_review' WHERE status = 'active' ORDER BY price ASC LIMIT 2;

-- 子查询更新
UPDATE t_product
SET price = (SELECT MAX(price) * 0.8 FROM t_product)
WHERE id = 3;

-- 多表更新（UPDATE t1, t2 JOIN形式）
CREATE TABLE t_sales (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    quantity INT
);
INSERT INTO t_sales VALUES (1, 1, 2), (2, 2, 5), (3, 3, 1);

UPDATE t_product p
INNER JOIN t_sales s ON p.id = s.product_id
SET p.stock = p.stock - s.quantity
WHERE s.id = 2;

SELECT * FROM t_product;

-- 测试回滚
START TRANSACTION;
UPDATE t_product SET price = price * 1.1;
ROLLBACK;
SELECT price FROM t_product WHERE id = 1;  -- 价格未变

-- ================================================================
-- Q3: DELETE语句的用法和与TRUNCATE的区别？

-- 【解答】
-- DELETE FROM tbl WHERE condition
-- 可以带WHERE条件、带ORDER BY和LIMIT
-- 受事务控制，支持触发器

-- 【原理】
-- DELETE逐行删除，记录undo日志，可以ROLLBACK。
-- TRUNCATE是DDL，不记录逐行日志，不能ROLLBACK，速度更快。
-- DELETE后AUTO_INCREMENT不会重置，TRUNCATE会重置。

-- 【示例】
USE dml_demo;

CREATE TABLE t_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    action VARCHAR(50),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO t_log (action) VALUES ('login'), ('page_view'), ('click'), ('purchase'), ('logout');

-- 带WHERE条件删除
DELETE FROM t_log WHERE action = 'page_view';

-- 删除满足条件的多行
DELETE FROM t_log WHERE action IN ('login', 'logout');

-- 按时间排序后删除最早的几条
DELETE FROM t_log ORDER BY log_time ASC LIMIT 1;

-- 全表删除（危险！）
DELETE FROM t_log;  -- 删除所有数据，可以ROLLBACK

-- DELETE vs TRUNCATE 对比
CREATE TABLE t_compare (
    id INT PRIMARY KEY AUTO_INCREMENT,
    val VARCHAR(50)
);
INSERT INTO t_compare VALUES (1, 'A'), (2, 'B'), (3, 'C');

-- DELETE测试
DELETE FROM t_compare;
ROLLBACK;  -- 可以回滚
INSERT INTO t_compare VALUES (4, 'D');
SELECT * FROM t_compare;  -- id=4，说明AUTO_INCREMENT没有被重置

-- TRUNCATE测试
TRUNCATE TABLE t_compare;
-- ROLLBACK无效（TRUNCATE是DDL）
INSERT INTO t_compare VALUES (5, 'E');
SELECT * FROM t_compare;  -- id=5，但AUTO_INCREMENT重置为1

-- ================================================================
-- Q4: 什么是批量插入？如何高效批量插入大量数据？

-- 【解答】
-- 批量插入：一条INSERT语句插入多条记录
-- 效率对比：逐条INSERT 1000次 vs 批量INSERT 1次，后者快10-50倍

-- 【原理】
-- MySQL插入开销：解析SQL → 记录日志 → 提交事务
-- 批量插入可以分摊这些开销，显著提升性能。
-- 大量数据（百万级）推荐使用 LOAD DATA INFILE 或分批提交。

-- 【示例】
USE dml_demo;

-- 场景：插入10000条订单数据
CREATE TABLE t_order_batch (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50),
    product_name VARCHAR(50),
    amount DECIMAL(10,2),
    order_date DATE
);

-- 低效方式：循环逐条插入（实际不推荐，演示用）
-- 假设需要在存储过程中逐条插入
DELIMITER //
CREATE PROCEDURE p_insert_batch_slow()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 100 DO
        INSERT INTO t_order_batch (customer_name, product_name, amount, order_date)
        VALUES (CONCAT('Customer', i), CONCAT('Product', i), i * 10.00, CURDATE());
        SET i = i + 1;
    END WHILE;
END//
DELIMITER ;

CALL p_insert_batch_slow();
SELECT COUNT(*) FROM t_order_batch;  -- 100条

-- 高效方式：单条SQL批量插入
TRUNCATE TABLE t_order_batch;
INSERT INTO t_order_batch (customer_name, product_name, amount, order_date)
SELECT
    CONCAT('Customer', n),
    CONCAT('Product', n),
    n * 10.00,
    CURDATE()
FROM (
    SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
    SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION
    SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15 UNION
    SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
) t;

SELECT COUNT(*) FROM t_order_batch;  -- 20条

-- 更大批量：1000条
TRUNCATE TABLE t_order_batch;
INSERT INTO t_order_batch (customer_name, product_name, amount, order_date)
SELECT
    CONCAT('Customer', n),
    CONCAT('Product', n),
    n * 10.00,
    CURDATE()
FROM (
    SELECT a.n + b.n * 10 AS n FROM
    (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
     SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a,
    (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
     SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) b
) t;

SELECT COUNT(*) FROM t_order_batch;  -- 100条（10x10）

-- ================================================================
-- Q5: 什么是逻辑删除？为什么优先选择逻辑删除？

-- 【解答】
-- 逻辑删除：给表加一个is_deleted标记，删除时标记为1而非真正删除数据
-- 物理删除：真正的DELETE语句，数据从表中移除
-- 逻辑删除保留数据，可追溯、可恢复，是实际业务中更常用的"删除"方式

-- 【原理】
-- 逻辑删除优点：
-- 1. 数据可恢复（is_deleted=0即可恢复）
-- 2. 保留历史数据，用于审计和分析
-- 3. 避免误删除导致的业务问题
-- 4. 分表归档前可以作为临时方案

-- 逻辑删除缺点：
-- 1. 查询时必须加is_deleted条件，容易遗漏
-- 2. 索引需要包含is_deleted字段
-- 3. 唯一约束需要考虑is_deleted状态

-- 【示例】
USE dml_demo;

CREATE TABLE t_user_logic_del (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    is_deleted TINYINT DEFAULT 0,          -- 0=未删除，1=已删除
    delete_time DATETIME DEFAULT NULL
);

INSERT INTO t_user_logic_del (username, email) VALUES
    ('alice', 'alice@example.com'),
    ('bob', 'bob@example.com'),
    ('carol', 'carol@example.com');

-- 逻辑删除：UPDATE而非DELETE
UPDATE t_user_logic_del
SET is_deleted = 1, delete_time = NOW()
WHERE id = 2;

-- 查询有效数据（必须加is_deleted条件）
SELECT * FROM t_user_logic_del WHERE is_deleted = 0;

-- 恢复数据
UPDATE t_user_logic_del SET is_deleted = 0, delete_time = NULL WHERE id = 2;
SELECT * FROM t_user_logic_del WHERE is_deleted = 0;  -- Bob恢复

-- 唯一约束与逻辑删除的冲突（解决：唯一约束包含is_deleted）
CREATE TABLE t_code_logic_del (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(50),
    is_deleted TINYINT DEFAULT 0
);
-- 给已删除记录的code留出插入空间的方法：唯一约束不包含is_deleted时冲突
INSERT INTO t_code_logic_del (code, name, is_deleted) VALUES ('ABC', 'First', 0);
-- 软删除
UPDATE t_code_logic_del SET is_deleted = 1 WHERE id = 1;
-- 重新插入相同code（因为之前的is_deleted=1，视为"不同"记录）
INSERT INTO t_code_logic_del (code, name, is_deleted) VALUES ('ABC', 'New First', 0);

SELECT * FROM t_code_logic_del;

-- ================================================================
-- Q6: INSERT ON DUPLICATE KEY UPDATE（Upsert）是什么？

-- 【解答】
-- 当插入时唯一键冲突，执行UPDATE而不是报错
-- 语法：INSERT ... VALUES ... ON DUPLICATE KEY UPDATE col=val

-- 【原理】
-- MySQL特有语法，用于"有则更新，无则插入"场景（Upsert）。
-- 冲突判定：PRIMARY KEY或UNIQUE索引冲突
-- 配合VALUES(col)可以引用待插入的值

-- 【示例】
USE dml_demo;

CREATE TABLE t_stock (
    product_code VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(50),
    stock INT DEFAULT 0,
    last_update DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO t_stock (product_code, product_name, stock) VALUES
    ('P001', 'Laptop', 100),
    ('P002', 'Mouse', 500);

-- 场景1：新增库存记录
INSERT INTO t_stock (product_code, product_name, stock)
VALUES ('P003', 'Keyboard', 200)
ON DUPLICATE KEY UPDATE stock = stock + 200;

-- 场景2：更新已存在的库存（库存+50）
INSERT INTO t_stock (product_code, product_name, stock)
VALUES ('P001', 'Laptop', 50)
ON DUPLICATE KEY UPDATE stock = stock + VALUES(stock), last_update = NOW();

SELECT * FROM t_stock;

-- 使用VALUES()函数引用新值
INSERT INTO t_stock (product_code, product_name, stock)
VALUES ('P002', 'Mouse', 100)
ON DUPLICATE KEY UPDATE
    stock = stock + VALUES(stock),
    last_update = NOW();

SELECT * FROM t_stock;  -- P002的stock从500变成600

-- affected_rows返回值判断：
-- 1 = 新插入，2 = 更新（MySQL协议层定义）

-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================
-- | 特性            | MySQL               | PostgreSQL           | Oracle              | SQLite              |
-- |---------------|---------------------|---------------------|---------------------|--------------------|
-- | 批量插入语法      | INSERT...VALUES(),(),() | 同MySQL           | 同MySQL              | 同MySQL              |
-- | UPSERT语法       | INSERT...ONDUPLICATE KEY UPDATE | INSERT...ON CONFLICT | MERGE INTO          | INSERT OR REPLACE |
-- | IGNORE语法       | INSERT IGNORE INTO   | ON CONFLICT DO NOTHING | 不支持              | INSERT OR IGNORE    |
-- | REPLACE语义      | REPLACE INTO（先删后插） | INSERT...ON CONFLICT | MERGE               | INSERT OR REPLACE   |
-- | 子查询插入        | INSERT...SELECT      | INSERT...SELECT      | INSERT...SELECT      | INSERT...SELECT     |
-- | 逻辑删除实现      | is_deleted标志位      | is_deleted标志位       | is_deleted标志位      | is_deleted标志位     |
-- | DELETE LIMIT    | 支持                  | 支持                  | 不支持(rownum)       | 支持                |
-- | UPDATE ORDER BY | 支持                  | 支持                  | 不支持               | 支持                |

-- PostgreSQL UPSERT（9.5+）：
-- INSERT INTO t_stock (product_code, stock)
-- VALUES ('P001', 100)
-- ON CONFLICT (product_code) DO UPDATE SET stock = t_stock.stock + EXCLUDED.stock;

-- Oracle MERGE（标准UPSERT）：
-- MERGE INTO t_target t
-- USING t_source s
-- ON (t.id = s.id)
-- WHEN MATCHED THEN UPDATE SET t.value = s.value
-- WHEN NOT MATCHED THEN INSERT (id, value) VALUES (s.id, s.value);

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 用INSERT ... VALUES (...), (...), (...) 批量插入10条学生记录，
--    再用INSERT INTO ... SELECT插入10条，用COUNT(*)验证总条数。

-- 2. 实现Upsert功能（订单库存表，product_code为主键）：
--    第一次插入新记录，再次插入时更新库存数量。用ON DUPLICATE KEY UPDATE实现。

-- 3. 对一张有AUTO_INCREMENT主键的表，分别执行DELETE全表、TRUNCATE全表，
--    之后各插入一条新记录，对比AUTO_INCREMENT的起始值差异。

-- 4. 用INSERT IGNORE插入一条与唯一键冲突的记录，
--    再用INSERT插入冲突记录后用ON DUPLICATE KEY UPDATE处理，对比两者行为差异。

-- 5. 设计一个逻辑删除方案：用户表，用is_deleted=0/1标记删除状态，
--    实现（a）查询在职员工、（b）恢复已删除员工、（c）统计删除率。
