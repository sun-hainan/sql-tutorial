-- ================================================================
-- 模块四：数据表操作
-- ================================================================

-- Q1: 如何创建、查看、删除数据表？

-- 【解答】
-- CREATE TABLE：创建表
-- SHOW TABLES：查看当前数据库所有表
-- DESC / DESCRIBE：查看表结构
-- DROP TABLE：删除表

-- 【原理】
-- CREATE TABLE需要指定：表名、列名、列类型、约束、存储引擎、字符集
-- 表创建后，MySQL会生成对应的.frm文件（MyISAM）或在系统表空间中（InnoDB）
-- DESC显示列信息：Field（列名）、Type（类型）、Null（是否允许NULL）、Key（索引）、Default（默认值）、Extra（扩展）

-- 【示例】
DROP DATABASE IF EXISTS table_ops_demo;
CREATE DATABASE table_ops_demo;
USE table_ops_demo;

-- 创建表（完整语法）
CREATE TABLE t_employee (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    salary DECIMAL(10,2) DEFAULT 0.00,
    dept_id INT,
    hiredate DATE,
    status TINYINT DEFAULT 1
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- 查看当前数据库所有表
SHOW TABLES;

-- 查看表结构
DESC t_employee;
DESCRIBE t_employee;

-- 查看建表语句（包含完整DDL）
SHOW CREATE TABLE t_employee;

-- 插入测试数据
INSERT INTO t_employee (name, email, salary, dept_id, hiredate) VALUES
    ('Alice', 'alice@example.com', 8000.00, 1, '2023-01-15'),
    ('Bob', 'bob@example.com', 9000.00, 1, '2023-03-20'),
    ('Carol', 'carol@example.com', 7500.00, 2, '2023-06-01');

-- 删除表（危险！数据永久丢失）
DROP TABLE IF EXISTS t_employee;

-- ================================================================
-- Q2: ALTER TABLE可以实现哪些操作？

-- 【解答】
-- 添加列、修改列（类型/默认值）、删除列、重命名列、添加/删除索引、添加/删除外键、修改表名

-- 【原理】
-- ALTER TABLE是修改已存在表的结构，不影响已有数据（但大表改列会有性能问题）。
-- MySQL 5.6+支持在线DDL（ALGORITHM=INPLACE减少锁表时间）。
-- 每次ALTER都会修改.frm和.ibd文件，是比较重的操作。

-- 【示例】
USE table_ops_demo;

CREATE TABLE t_product (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

-- 添加列
ALTER TABLE t_product ADD COLUMN price DECIMAL(10,2) AFTER name;
ALTER TABLE t_product ADD COLUMN category VARCHAR(50) FIRST;
-- 添加多个列（MySQL 5.6+支持）
ALTER TABLE t_product
    ADD COLUMN brand VARCHAR(50),
    ADD COLUMN stock INT DEFAULT 0;

-- 修改列（类型、默认值）
ALTER TABLE t_product MODIFY COLUMN name VARCHAR(100);
ALTER TABLE t_product MODIFY COLUMN name VARCHAR(100) DEFAULT 'Unknown';

-- 重命名列
ALTER TABLE t_product CHANGE COLUMN brand manufacturer VARCHAR(50);

-- 删除列
ALTER TABLE t_product DROP COLUMN stock;

-- 添加索引
ALTER TABLE t_product ADD INDEX idx_category (category);
ALTER TABLE t_product ADD UNIQUE INDEX idx_name (name);

-- 添加外键（需要先有主键表）
CREATE TABLE t_category (
    cat_id INT PRIMARY KEY,
    cat_name VARCHAR(50)
);
ALTER TABLE t_product ADD FOREIGN KEY (category) REFERENCES t_category(cat_id);

-- 修改表名
ALTER TABLE t_product RENAME TO t_goods;

SHOW TABLES;

-- ================================================================
-- Q3: 如何复制表结构？复制表数据？

-- 【解答】
-- 复制表结构：CREATE TABLE new_table LIKE old_table
-- 复制表数据：INSERT INTO new_table SELECT * FROM old_table
-- 完整复制（含数据）：CREATE TABLE new_table AS SELECT * FROM old_table

-- 【原理】
-- CREATE TABLE ... LIKE：只复制结构，不复制数据，约束/索引/外键一并复制
-- CREATE TABLE ... AS SELECT：复制结构和数据，但不复制索引/外键/自增属性
-- INSERT INTO ... SELECT：需要在表已存在的情况下复制数据

-- 【示例】
USE table_ops_demo;

CREATE TABLE t_orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50),
    amount DECIMAL(10,2),
    order_date DATE
);
INSERT INTO t_orders (customer_name, amount, order_date) VALUES
    ('Alice', 299.00, '2024-01-15'),
    ('Bob', 599.00, '2024-01-20'),
    ('Alice', 899.00, '2024-02-01');

-- 方法1：复制表结构（不复制数据）
CREATE TABLE t_orders_backup LIKE t_orders;
SHOW CREATE TABLE t_orders_backup;  -- 约束和索引都复制过来了
DESC t_orders_backup;
INSERT INTO t_orders_backup SELECT * FROM t_orders;  -- 再单独复制数据

-- 方法2：完整复制（含数据，索引/外键不复制）
CREATE TABLE t_orders_copy AS SELECT * FROM t_orders;
SHOW CREATE TABLE t_orders_copy;  -- 没有AUTO_INCREMENT等属性
DESC t_orders_copy;

-- 方法3：只复制部分列
CREATE TABLE t_orders_partial AS SELECT order_id, customer_name FROM t_orders;
DESC t_orders_partial;

-- 方法4：复制符合条件的部分数据
CREATE TABLE t_orders_alice AS SELECT * FROM t_orders WHERE customer_name = 'Alice';

-- ================================================================
-- Q4: TRUNCATE和DELETE的区别是什么？何时使用？

-- 【解答】
-- DELETE：逐行删除，受事务控制，可ROLLBACK，支持WHERE条件
-- TRUNCATE：整表释放，不记录逐行日志，不支持事务回滚，高效但危险

-- 【原理】
-- DELETE过程：扫描每行 → 记录undo日志 → 执行删除 → 触发触发器 → 等待purge清理
-- TRUNCATE过程：释放数据页 → 重置AUTO_INCREMENT → 不记录逐行日志 → 不触发触发器
-- 大数据量时TRUNCATE比DELETE快10-100倍，但数据无法恢复

-- 【示例】
USE table_ops_demo;

CREATE TABLE t_truncate_test (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(50)
);
INSERT INTO t_truncate_test (data) VALUES ('A'), ('B'), ('C');
SELECT * FROM t_truncate_test;  -- 3条，AUTO_INCREMENT=3

-- DELETE：可回滚，不重置AUTO_INCREMENT
START TRANSACTION;
DELETE FROM t_truncate_test;
ROLLBACK;
SELECT MAX(id) FROM t_truncate_test;  -- 仍是3

-- TRUNCATE：不可回滚，重置AUTO_INCREMENT
TRUNCATE TABLE t_truncate_test;
INSERT INTO t_truncate_test (data) VALUES ('X');
SELECT * FROM t_truncate_test;  -- id=1（重置了）

-- 何时用DELETE：需要条件删除、可能需要回滚、小数据量
-- 何时用TRUNCATE：清空测试数据、清空临时表、不需要保留数据

-- ================================================================
-- Q5: 如何选择合适的数据类型（整数、浮点数、字符串）？

-- 【解答】
-- 整数：TINYINT（1字节）< SMALLINT（2）< MEDIUMINT（3）< INT（4）< BIGINT（8）
-- 浮点数：DECIMAL（精确，适合金额）vs FLOAT/DOUBLE（近似值）
-- 字符串：CHAR（固定长度）vs VARCHAR（可变长度）vs TEXT（大文本）

-- 【原理】
-- 整数选择原则：够用就行，选小不选大（省存储空间）
--   TINYINT: -128~127 或 0~255
--   SMALLINT: 约-3万~3万
--   INT: 约-21亿~21亿，适合ID、年龄
--   BIGINT: 极大数值

-- VARCHAR vs CHAR：
--   CHAR(n)：固定占用n个字符，不足的用空格填充。适合固定长度（性别、邮编、MD5值）
--   VARCHAR(n)：实际占用 = 实际长度 + 1~2字节长度前缀。适合可变长度。
--   VARCHAR最大65535字节（utf8mb4下一个字符最多4字节，所以最多约16000字符）

-- DECIMAL vs FLOAT：
--   DECIMAL(10,2)：精确存储10位数字，2位小数。适合货币。
--   FLOAT/DOUBLE：近似值，有精度丢失风险，不适合金融计算。

-- 【示例】
USE table_ops_demo;

CREATE TABLE t_data_type_selection (
    -- 整数选择
    id INT PRIMARY KEY,
    age TINYINT UNSIGNED,           -- 年龄0-255足够，用TINYINT
    user_level SMALLINT DEFAULT 1,  -- 用户等级，不会太多，用SMALLINT

    -- 字符串选择
    code CHAR(6) NOT NULL,          -- 固定6位编码，如ABC001
    phone VARCHAR(20),              -- 可变长度手机号
    bio TEXT,                       -- 个人简介，可能很长

    -- 数值选择
    price DECIMAL(10,2),            -- 商品价格，必须精确
    latitude DOUBLE,               -- 经纬度，DOUBLE足够
    ratio FLOAT,                    -- 比例，近似值即可

    -- 日期时间
    birth_date DATE,
    create_time DATETIME
);

INSERT INTO t_data_type_selection VALUES (
    1,                           -- id
    25,                          -- age
    5,                           -- user_level
    'A001B',                     -- code（实际存' A001B '，CHAR用空格填充）
    '13800138000',               -- phone
    '这是一段很长的个人简介...',  -- bio
    999.99,                      -- price
    39.9042,                     -- latitude
    0.75,                        -- ratio
    '1999-06-15',                -- birth_date
    '2024-01-15 10:30:00'        -- create_time
);

-- CHAR vs VARCHAR 对比
CREATE TABLE t_string_compare (
    fixed CHAR(10),
    variable VARCHAR(10)
);
INSERT INTO t_string_compare VALUES ('ABC', 'ABC');
SELECT LENGTH(fixed), LENGTH(variable) FROM t_string_compare;
-- CHAR(10) 固定占10字节，VARCHAR(10)只占实际3字节+长度前缀

-- ================================================================
-- Q6: 临时表是什么？什么时候使用临时表？

-- 【解答】
-- 临时表：只在当前连接存在，连接断开后自动删除的表
-- 使用场景：复杂查询的中间结果、临时的数据处理、报表计算的分步结果

-- 【原理】
-- MySQL临时表使用TEMPORARY关键字创建。
-- 临时表在TEMPORARY关键字，只对当前会话可见，会话结束时自动删除。
-- 可以与普通表同名（当前会话优先使用临时表）。
-- 临时表可以创建索引和约束，但不支持外键（FOREIGN KEY）。

-- 【示例】
USE table_ops_demo;

-- 创建临时表（当前连接可用，断开连接后自动删除）
CREATE TEMPORARY TABLE t_temp_monthly_sales AS
SELECT
    MONTH(order_date) AS month_num,
    SUM(amount) AS total_sales
FROM t_orders
GROUP BY MONTH(order_date);

SELECT * FROM t_temp_monthly_sales;

-- 临时表与普通表同名时，当前会话优先使用临时表
CREATE TEMPORARY TABLE t_orders AS SELECT * FROM t_orders WHERE 1=0;
-- 此时 t_orders 指的是临时表，不是真实的订单表

-- 临时表创建普通表的结构（用于数据迁移测试）
CREATE TEMPORARY TABLE t_orders_staging AS
SELECT * FROM t_orders LIMIT 0;  -- 只复制结构

INSERT INTO t_orders_staging SELECT * FROM t_orders WHERE customer_name = 'Alice';

-- 查看临时表
SHOW TEMPORARY TABLES;  -- 只显示当前数据库的临时表

-- ================================================================
-- Q7: 表的存储引擎如何选择？MyISAM和InnoDB各自适用场景？

-- 【解答】
-- MySQL 5.5+默认InnoDB，InnoDB是通用场景的首选。
-- MyISAM适用于读多写少、数据静态的场景（如日志表、历史数据）。

-- 【原理】
-- InnoDB核心优势：事务、行级锁、外键、崩溃恢复
-- MyISAM核心优势：全文索引、占用空间小、COUNT(*)快（优化过）
-- 如果表需要FULLTEXT索引，仍需用MyISAM；否则强烈建议InnoDB

-- 【示例】
USE table_ops_demo;

-- 创建InnoDB表（默认）
CREATE TABLE t_innodb_demo (
    id INT PRIMARY KEY,
    name VARCHAR(50)
) ENGINE = InnoDB;

-- 创建MyISAM表
CREATE TABLE t_myisam_demo (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    FULLTEXT INDEX ft_name (name)
) ENGINE = MyISAM;

INSERT INTO t_innodb_demo VALUES (1, 'InnoDB特性：事务+行锁');
INSERT INTO t_myisam_demo VALUES (1, 'MyISAM特性：支持FULLTEXT');

-- 查看表存储引擎
SHOW TABLE STATUS LIKE 't_%';

-- COUNT(*)性能对比（MyISAM更快，因为存储了精确行数）
-- InnoDB需要实时扫描统计，MyISAM从元数据读取

-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================
-- | 特性              | MySQL               | PostgreSQL           | Oracle              | SQLite            |
-- |-----------------|---------------------|---------------------|--------------------|------------------|
-- | 创建表语法        | CREATE TABLE        | CREATE TABLE         | CREATE TABLE        | CREATE TABLE      |
-- | 表复制            | CREATE TABLE LIKE    | CREATE TABLE AS      | CREATE TABLE AS     | CREATE TABLE AS   |
-- | 临时表            | CREATE TEMPORARY     | CREATE TEMP TABLE    | GLOBAL TEMP TABLE   | TEMP TABLE        |
-- | 修改表结构        | ALTER TABLE          | ALTER TABLE          | ALTER TABLE         | ALTER TABLE       |
-- | 删除表            | DROP TABLE           | DROP TABLE           | DROP TABLE          | DROP TABLE        |
-- | 清空表            | TRUNCATE TABLE       | TRUNCATE TABLE       | TRUNCATE TABLE      | DELETE FROM       |
-- | 自增ID语法        | AUTO_INCREMENT        | SERIAL/BIGSERIAL     | SEQUENCE            | AUTOINCREMENT     |
-- | 截断外键表        | 先删外键再TRUNCATE   | CASCADE TRUNCATE     | CASCADE PURGE       | 不支持TRUNCATE    |

-- PostgreSQL的表复制语法差异：
-- CREATE TABLE t_new AS SELECT * FROM t_old [WITH NO DATA];  -- 可选是否复制数据
-- PostgreSQL没有TRUNCATE的CASCADE选项，需要: TRUNCATE t1, t2, ... CASCADE;

-- Oracle的临时表：
-- CREATE GLOBAL TEMPORARY TABLE t_temp (id INT, name VARCHAR2(50))
-- ON COMMIT DELETE ROWS;  -- 事务级
-- ON COMMIT PRESERVE ROWS; -- 会话级

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 用CREATE TABLE ... LIKE复制一个表的结构（不复制数据），
--    再用CREATE TABLE ... AS SELECT复制完整数据，分别对比两种方式复制的结果有何不同。

-- 2. 创建一个临时表，插入数据后执行SHOW TABLES，
--    验证临时表在断开连接后是否自动消失（可通过新会话连接后查询验证）。

-- 3. 用ALTER TABLE分别实现以下操作（基于同一张表）：
--    添加一个新列、修改某列的数据类型、删除刚添加的列、重命名表。

-- 4. 比较TRUNCATE和DELETE在以下场景的表现：
--    （a）对100万行数据的清空速度（可用EXPLAIN分析或观察执行时间）
--    （b）AUTO_INCREMENT的差异
--    （c）ROLLBACK的效果差异

-- 5. 设计一个表，要求：id为主键自增，name非空且唯一，email非空，
--    age在0-150之间，created_at默认为当前时间。用SHOW CREATE TABLE验证所有约束。
