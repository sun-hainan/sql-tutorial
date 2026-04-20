-- ================================================================
-- 模块二：SQL五大语言分类
-- ================================================================

-- Q1: SQL分为哪五大类？它们分别负责什么？

-- 【解答】
-- DDL（Data Definition Language）：数据定义语言 → 定义/修改数据库对象结构
-- DML（Data Manipulation Language）：数据操作语言 → 增删改数据
-- DQL（Data Query Language）：数据查询语言 → 查询数据
-- DCL（Data Control Language）：数据控制语言 → 控制权限和安全
-- TCL（Transaction Control Language）：事务控制语言 → 管理事务

-- 【原理】
-- DDL操作的是"结构"（表、视图、索引），不涉及数据内容
-- DML操作的是"数据"本身
-- 事务控制确保一批DML语句作为一个整体执行

-- 【示例】
DROP DATABASE IF EXISTS sql分类_demo;
CREATE DATABASE sql分类_demo;

USE sql分类_demo;

-- DDL：创建表（定义结构）
CREATE TABLE t_product (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    price DECIMAL(10,2)
);
-- DDL：修改表结构（添加列）
ALTER TABLE t_product ADD COLUMN category VARCHAR(50);
-- DDL：删除表
DROP TABLE t_product;

-- DML：插入数据
CREATE TABLE t_product (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    price DECIMAL(10,2)
);
INSERT INTO t_product VALUES (1, 'Laptop', 5000.00);
INSERT INTO t_product (id, name, price) VALUES (2, 'Mouse', 99.00);
UPDATE t_product SET price = 89.00 WHERE id = 2;
DELETE FROM t_product WHERE id = 1;

-- DQL：查询数据
INSERT INTO t_product VALUES (1, 'Laptop', 5000.00);
INSERT INTO t_product VALUES (2, 'Mouse', 99.00);
INSERT INTO t_product VALUES (3, 'Keyboard', 299.00);
SELECT * FROM t_product WHERE price > 100 ORDER BY price DESC;

-- DCL：授权（注意：需要管理员权限，实际环境执行）
-- GRANT SELECT ON sql分类_demo.t_product TO 'username'@'host';
-- REVOKE SELECT ON sql分类_demo.t_product FROM 'username'@'host';

-- TCL：事务控制
START TRANSACTION;
DELETE FROM t_product WHERE id = 2;
COMMIT;  -- 提交后删除生效

-- 测试ROLLBACK
START TRANSACTION;
INSERT INTO t_product VALUES (4, 'Monitor', 1299.00);
ROLLBACK;  -- 回滚，插入无效
SELECT * FROM t_product;  -- 只有3条数据，Monitor未插入

-- ================================================================
-- Q2: DDL的常用关键字有哪些？它们的作用是什么？

-- 【解答】
-- CREATE：创建数据库对象（数据库、表、视图、索引等）
-- ALTER：修改已存在的数据库对象结构
-- DROP：删除数据库对象（彻底删除，不可恢复）
-- TRUNCATE：清空表数据（保留结构，速度快）

-- 【原理】
-- DDL操作自动提交（MySQL中DDL是隐式提交的），无法回滚。
-- TRUNCATE是DDL不是DML，所以不受事务控制，不能ROLLBACK。

-- 【示例】
DROP DATABASE IF EXISTS ddl_demo;
CREATE DATABASE ddl_demo;

USE ddl_demo;

-- CREATE：创建数据库
CREATE DATABASE ddl_test;

-- CREATE：创建表
CREATE TABLE t_employee (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2),
    dept_id INT
);

-- ALTER：添加列
ALTER TABLE t_employee ADD COLUMN email VARCHAR(100);
-- ALTER：修改列
ALTER TABLE t_employee MODIFY COLUMN name VARCHAR(100);
-- ALTER：删除列
ALTER TABLE t_employee DROP COLUMN email;
-- ALTER：添加索引
ALTER TABLE t_employee ADD INDEX idx_dept (dept_id);
-- ALTER：添加外键
CREATE TABLE t_department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
ALTER TABLE t_employee ADD FOREIGN KEY (dept_id) REFERENCES t_department(dept_id);

-- TRUNCATE：清空表（速度比DELETE快，不记录日志，不可回滚）
INSERT INTO t_department VALUES (1, 'IT');
INSERT INTO t_employee VALUES (1, 'Alice', 5000, 1);
INSERT INTO t_employee VALUES (2, 'Bob', 6000, 1);
SELECT COUNT(*) FROM t_employee;  -- 2条
TRUNCATE TABLE t_employee;  -- 清空数据，结构保留
SELECT COUNT(*) FROM t_employee;  -- 0条

-- DROP：删除表（彻底删除）
DROP TABLE t_employee;
DROP TABLE t_department;
DROP DATABASE ddl_test;

-- ================================================================
-- Q3: DML的常用关键字有哪些？它们的特点是什么？

-- 【解答】
-- INSERT：插入数据（单行/批量）
-- UPDATE：更新数据
-- DELETE：删除数据
-- REPLACE：替换（若唯一键冲突则先删后插）

-- 【原理】
-- DML受事务控制，可以用COMMIT提交，也可以ROLLBACK回滚。
-- DELETE可以带WHERE条件删除部分数据，TRUNCATE是清空整表。
-- UPDATE和DELETE操作前建议先SELECT确认范围，避免误操作。

-- 【示例】
DROP DATABASE IF EXISTS dml_demo;
CREATE DATABASE dml_demo;

USE dml_demo;

CREATE TABLE t_order (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50),
    amount DECIMAL(10,2),
    status VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- INSERT：单行插入
INSERT INTO t_order (customer_name, amount, status) VALUES ('Alice', 299.00, 'paid');

-- INSERT：多行插入
INSERT INTO t_order (customer_name, amount, status) VALUES
    ('Bob', 599.00, 'paid'),
    ('Carol', 1299.00, 'pending'),
    ('David', 99.00, 'cancelled');

-- INSERT：省略列（使用默认值）
INSERT INTO t_order (customer_name, amount) VALUES ('Eve', 399.00);
-- created_at 会自动使用 CURRENT_TIMESTAMP

-- UPDATE：更新数据
UPDATE t_order SET status = 'completed', amount = 319.00 WHERE order_id = 1;
-- 更新多个字段用逗号分隔
UPDATE t_order SET status = 'paid', amount = amount * 0.9 WHERE status = 'pending';

-- DELETE：删除数据
DELETE FROM t_order WHERE status = 'cancelled';

-- REPLACE：替换（如果order_id=1存在则先删除后插入）
REPLACE INTO t_order (order_id, customer_name, amount, status) VALUES (1, 'Alice', 399.00, 'paid');

-- 查看最终数据
SELECT * FROM t_order;

-- ================================================================
-- Q4: DQL和DML的核心区别是什么？DQL单独分类的意义？

-- 【解答】
-- DML（INSERT/UPDATE/DELETE）：修改数据，涉及数据变更
-- DQL（SELECT）：查询数据，不改变原始数据
-- DQL单独分类是因为查询是最高频的操作，需要精细化学习

-- 【原理】
-- SQL语句中，查询占了业务场景的60-80%。
-- SELECT有最复杂的子句组合（WHERE/GROUP BY/HAVING/ORDER BY/LIMIT等）。
-- 理解SELECT执行顺序是掌握SQL查询的核心。

-- 【示例】
DROP DATABASE IF EXISTS dql_demo;
CREATE DATABASE dql_demo;

USE dql_demo;

CREATE TABLE t_sales (
    id INT PRIMARY KEY AUTO_INCREMENT,
    region VARCHAR(50),
    product VARCHAR(50),
    amount DECIMAL(10,2),
    sale_date DATE
);
INSERT INTO t_sales (region, product, amount, sale_date) VALUES
    ('North', 'Laptop', 5000.00, '2024-01-01'),
    ('North', 'Mouse', 99.00, '2024-01-02'),
    ('South', 'Laptop', 4800.00, '2024-01-03'),
    ('South', 'Keyboard', 299.00, '2024-01-04'),
    ('East', 'Laptop', 5200.00, '2024-01-05');

-- DQL核心操作：SELECT
-- 基础查询
SELECT * FROM t_sales;
SELECT region, product, amount FROM t_sales;

-- 条件过滤
SELECT * FROM t_sales WHERE region = 'North';

-- 分组聚合
SELECT region, COUNT(*) AS cnt, SUM(amount) AS total_amount
FROM t_sales GROUP BY region;

-- 排序
SELECT region, SUM(amount) AS total FROM t_sales GROUP BY region ORDER BY total DESC;

-- 分页
SELECT * FROM t_sales LIMIT 3 OFFSET 2;

-- DISTINCT去重
SELECT DISTINCT region, product FROM t_sales;

-- ================================================================
-- Q5: TCL的常用关键字及事务的核心特性是什么？

-- 【解答】
-- START TRANSACTION / BEGIN：开启事务
-- COMMIT：提交事务（使修改永久化）
-- ROLLBACK：回滚事务（撤销所有修改）
-- SAVEPOINT：设置保存点（支持部分回滚）

-- 【原理】
-- 事务必须满足ACID特性：
-- Atomicity（原子性）：事务是最小执行单元，要么全部成功，要么全部失败
-- Consistency（一致性）：事务前后数据状态保持一致
-- Isolation（隔离性）：并发事务之间相互隔离，互不干扰
-- Durability（持久性）：提交后的修改永久保存，即使系统崩溃也不丢失

-- 【示例】
DROP DATABASE IF EXISTS transaction_demo;
CREATE DATABASE transaction_demo;

USE transaction_demo;

CREATE TABLE t_account (
    account_id INT PRIMARY KEY,
    account_name VARCHAR(50),
    balance DECIMAL(10,2)
);
INSERT INTO t_account VALUES (1, 'Alice', 10000.00);
INSERT INTO t_account VALUES (2, 'Bob', 5000.00);

-- 转账场景：Alice转给Bob 3000元（需要原子性）
START TRANSACTION;
UPDATE t_account SET balance = balance - 3000 WHERE account_id = 1;
UPDATE t_account SET balance = balance + 3000 WHERE account_id = 2;
COMMIT;

-- 验证结果
SELECT * FROM t_account;

-- 测试回滚：模拟中途出错
START TRANSACTION;
UPDATE t_account SET balance = balance - 2000 WHERE account_id = 1;
UPDATE t_account SET balance = balance + 2000 WHERE account_id = 2;
-- 模拟出错，回滚
ROLLBACK;

-- 验证余额未变
SELECT * FROM t_account;

-- SAVEPOINT示例：部分回滚
START TRANSACTION;
INSERT INTO t_account VALUES (3, 'Carol', 8000.00);
SAVEPOINT sp1;
INSERT INTO t_account VALUES (4, 'David', 3000.00);
SAVEPOINT sp2;
-- 回滚到sp1保存点，sp2之后的操作被撤销
ROLLBACK TO SAVEPOINT sp1;
COMMIT;

-- 查看结果：Carol插入成功，David被回滚
SELECT * FROM t_account;

-- ================================================================
-- Q6: DCL的常用关键字及权限管理的核心概念是什么？

-- 【解答】
-- GRANT：授予权限
-- REVOKE：撤销权限
-- 核心概念：用户账号 + 主机来源 + 权限级别（全局/数据库/表/列）

-- 【原理】
-- MySQL的权限系统：user表存储账号，db表存储数据库级权限，tables_priv存储表级权限。
-- 权限检查顺序：列级别 → 表级别 → 数据库级别 → 全局级别
-- 最小权限原则：只授予完成任务所需的最小权限集。

-- 【示例】
-- 实际环境需要管理员权限，这里是语法演示
-- -- 创建用户
-- CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'StrongPwd123';
-- CREATE USER 'report_user'@'%' IDENTIFIED BY 'ReadOnlyPwd456';

-- -- 授予全局权限（所有数据库）
-- GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'localhost';
-- GRANT SELECT ON *.* TO 'report_user'@'%';

-- -- 授予数据库级权限
-- GRANT SELECT, INSERT, UPDATE, DELETE ON sql分类_demo.* TO 'app_user'@'localhost';

-- -- 授予表级权限
-- GRANT SELECT ON sql分类_demo.t_order TO 'report_user'@'%';

-- -- 撤销权限
-- REVOKE DELETE ON sql分类_demo.* FROM 'app_user'@'localhost';

-- -- 查看权限
-- SHOW GRANTS FOR 'app_user'@'localhost';
-- SHOW GRANTS FOR 'report_user'@'%';

-- -- 删除用户
-- DROP USER 'app_user'@'localhost';
-- DROP USER 'report_user'@'%';

-- ================================================================
-- Q7: 为什么TRUNCATE比DELETE快？为什么TRUNCATE不能ROLLBACK？

-- 【解答】
-- DELETE：逐行删除，记录每条删除日志，支持事务和触发器，可配合WHERE条件
-- TRUNCATE：直接释放数据页，不记录逐行日志，不支持事务回滚

-- 【原理】
-- DELETE过程：
-- 1. 逐行扫描数据页
-- 2. 每条DELETE记录到redo log和undo log
-- 3. 触发DELETE触发器
-- 4. 数据标记为已删除（不是立即释放空间）
-- 5. 需要时收缩表空间

-- TRUNCATE过程：
-- 1. 直接释放整个数据页
-- 2. 不记录逐行日志（只记录表结构变更）
-- 3. 不触发任何触发器
-- 4. 高效但危险——数据无法恢复

-- 【示例】
DROP DATABASE IF EXISTS truncate_vs_delete;
CREATE DATABASE truncate_vs_delete;

USE truncate_vs_delete;

CREATE TABLE t_large (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100)
);
-- 插入1000条测试数据
INSERT INTO t_large (data) VALUES (REPEAT('x', 100)) FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t;

SELECT COUNT(*) FROM t_large;

-- DELETE：逐行删除，日志记录，可回滚
START TRANSACTION;
DELETE FROM t_large;
ROLLBACK;
SELECT COUNT(*) FROM t_large;  -- 数据回滚，仍有1000条

-- TRUNCATE：立即清空，无法回滚
TRUNCATE TABLE t_large;
SELECT COUNT(*) FROM t_large;  -- 直接清空，0条
