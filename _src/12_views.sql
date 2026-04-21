-- ================================================================
-- 模块十二：视图
-- ================================================================

-- Q1: 什么是视图？如何创建和使用视图？

-- 【解答】
-- 视图（VIEW）：虚拟表，是预先定义好的SQL查询，不存储实际数据
-- 创建：CREATE VIEW view_name AS SELECT ...
-- 使用：SELECT * FROM view_name

-- 【原理】
-- 视图的SELECT查询在每次访问视图时实时执行（除非是物化视图）。
-- 视图不存储数据，数据来自基表，每次查询视图时重新计算结果。
-- 视图的好处：简化复杂查询、隐藏数据复杂性、提高安全性。

-- 【示例】
DROP DATABASE IF EXISTS view_demo;
CREATE DATABASE view_demo;
USE view_demo;

CREATE TABLE t_dept (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
CREATE TABLE t_emp (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    salary DECIMAL(10,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES t_dept(dept_id)
);
INSERT INTO t_dept VALUES (1, 'IT'), (2, 'HR'), (3, 'Finance');
INSERT INTO t_emp VALUES
    (1, 'Alice', 8000, 1), (2, 'Bob', 7000, 1), (3, 'Carol', 6000, 2),
    (4, 'David', 7500, 2), (5, 'Eve', 9000, 1), (6, 'Frank', 5500, 3);

-- 创建简单视图：IT部门员工
CREATE VIEW v_it_employees AS
SELECT emp_id, emp_name, salary
FROM t_emp
WHERE dept_id = 1;

-- 使用视图
SELECT * FROM v_it_employees;
SELECT emp_name, salary * 1.1 AS increased_salary FROM v_it_employees;

-- ================================================================
-- Q2: 视图的种类？可更新视图的条件？

-- 【解答】
-- 简单视图：基于单表、查询不含聚合函数/DISTINCT/GROUP BY/HAVING/UNION
-- 复杂视图：基于多表或包含聚合/分组等
-- 可更新视图：可以通过视图INSERT/UPDATE/DELETE基表数据

-- 【原理】
-- 可更新视图条件：
-- 1. 不含聚合函数、DISTINCT、GROUP BY、HAVING、UNION
-- 2. 不含子查询（MySQL 5.7+部分支持）
-- 3. 不含JOIN（MySQL 5.7+部分支持，但需要满足特定条件）
-- 4. 必须包含基表的所有NOT NULL列（除非有默认值）

-- 【示例】
USE view_demo;

-- 简单视图（可更新）
CREATE VIEW v_high_salary AS
SELECT emp_id, emp_name, salary
FROM t_emp
WHERE salary > 6000;

-- 通过视图更新数据（直接修改基表）
UPDATE v_high_salary SET salary = 8500 WHERE emp_id = 1;
SELECT * FROM v_emp_salaries WHERE emp_id = 1;  -- 视图结果同步更新

-- 通过视图删除数据
DELETE FROM v_high_salary WHERE emp_id = 6;  -- Frank薪资5500不在视图中，无影响
-- 实际可删除的记录是salary > 6000的部分

-- 复杂视图（通常不可更新）
CREATE VIEW v_dept_summary AS
SELECT dept_id, COUNT(*) AS emp_count, AVG(salary) AS avg_salary
FROM t_emp
GROUP BY dept_id;

-- 这个视图不能更新（含有聚合函数和GROUP BY）
-- INSERT INTO v_dept_summary VALUES (4, 10, 7000);  -- Error

-- ================================================================
-- Q3: WITH CHECK OPTION的作用？

-- 【解答】
-- WITH CHECK OPTION：防止通过视图插入或更新不符合视图定义条件的数据
-- 确保视图中的数据始终满足WHERE条件

-- 【原理】
-- 默认情况下，通过视图插入不符合视图WHERE条件的数据，实际会写入基表，只是查询视图时看不到。
-- WITH CHECK OPTION强制要求INSERT/UPDATE的数据必须满足视图的WHERE条件。

-- 【示例】
USE view_demo;

-- 不带CHECK OPTION的视图
CREATE VIEW v_it_staff AS
SELECT emp_id, emp_name, salary
FROM t_emp
WHERE dept_id = 1;

-- 插入一条IT部门以外的员工（虽然在视图中看不到，但实际写入了基表）
INSERT INTO v_it_staff VALUES (10, 'Test', 5000);  -- dept_id未指定，实际是NULL或其他
-- SELECT * FROM v_it_staff;  -- 看不到Test这条记录，因为它不在IT部门

-- 带WITH CHECK OPTION的视图
CREATE VIEW v_it_staff_checked AS
SELECT emp_id, emp_name, salary
FROM t_emp
WHERE dept_id = 1
WITH CHECK OPTION;

-- 尝试插入不符合dept_id=1的数据，会报错
-- INSERT INTO v_it_staff_checked VALUES (11, 'Test2', 5000);  -- Error: CHECK OPTION failed

-- 插入符合条件的数据，可以成功
INSERT INTO v_it_staff_checked VALUES (11, 'IT_New', 7000);
SELECT * FROM v_it_staff_checked;  -- IT_New在结果中

-- ================================================================
-- Q4: 视图在安全性和简化查询中的作用？

-- 【解答】
-- 安全性：隐藏基表结构和敏感列，只暴露必要数据
-- 简化查询：将复杂SQL封装为视图，后续直接SELECT * FROM view

-- 【原理】
-- 视图作为安全层：
-- 1. 可以限制用户只能访问特定列
-- 2. 可以隐藏敏感信息（如工资列）
-- 3. 可以限制只能通过视图操作，而不是直接操作基表

-- 简化查询：
-- 1. 封装复杂的多表JOIN
-- 2. 封装常用的过滤条件
-- 3. 使业务代码更简洁

-- 【示例】
USE view_demo;

-- 安全性示例：隐藏工资列，只暴露员工基本信息
CREATE VIEW v_emp_public AS
SELECT emp_id, emp_name, dept_id
FROM t_emp;

-- 用户只能看到emp_id, emp_name, dept_id，看不到salary
SELECT * FROM v_emp_public;

-- 简化查询示例：封装常用的部门统计
CREATE VIEW v_dept_stats AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS emp_count,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS avg_salary
FROM t_dept d
LEFT JOIN t_emp e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- 之前需要写复杂的JOIN+聚合，现在直接查询视图
SELECT * FROM v_dept_stats;
SELECT * FROM v_dept_stats WHERE dept_name = 'IT';

-- 应用层使用：把业务SQL封装在视图中
-- 之前：SELECT ... FROM orders o JOIN customers c ... JOIN products p ... WHERE ...
-- 现在：SELECT * FROM v_order_details WHERE order_date > '2024-01-01'

-- ================================================================
-- Q5: 视图的优缺点？

-- 【解答】
-- 优点：简化查询、增强安全性、提供逻辑独立性、代码复用
-- 缺点：性能开销、无索引、不支持全部SQL、依赖基表

-- 【原理】
-- 视图性能开销：每次查询视图时都要重新执行定义视图的SQL。
-- 视图无索引：视图本身不存储数据，无法在其上建索引。
-- 视图不支持：某些聚合、分组、UNION、JOIN的视图无法更新。
-- 依赖基表：基表删除或结构变更，视图会失效。

-- 【示例】
USE view_demo;

-- 缺点1：性能开销（复杂视图查询慢）
-- 定义一个复杂视图
CREATE VIEW v_complex AS
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    (SELECT AVG(salary) FROM t_emp WHERE dept_id = e.dept_id) AS dept_avg_salary,
    (SELECT COUNT(*) FROM t_emp WHERE dept_id = e.dept_id) AS dept_emp_count
FROM t_emp e
INNER JOIN t_dept d ON e.dept_id = d.dept_id;

-- EXPLAIN分析：视图查询会执行子查询
EXPLAIN SELECT * FROM v_complex WHERE dept_name = 'IT';

-- 缺点2：基表变更影响视图
-- 添加一列到基表
ALTER TABLE t_emp ADD COLUMN email VARCHAR(100);
-- 视图定义不变，但视图依赖的是原定义的列

-- 查看视图定义
SHOW CREATE VIEW v_complex;

-- ================================================================
-- Q6: 如何查看、修改和删除视图？

-- 【解答】
-- 查看：SHOW CREATE VIEW view_name / SHOW CREATE TABLE view_name
-- 修改：CREATE OR REPLACE VIEW / ALTER VIEW
-- 删除：DROP VIEW [IF EXISTS] view_name

-- 【原理】
-- MySQL同时支持CREATE OR REPLACE VIEW和ALTER VIEW两种修改方式。
-- DROP VIEW IF EXISTS安全删除，不存在的视图不会报错。
-- 修改视图定义会立即生效，之前依赖该视图的查询会自动使用新定义。

-- 【示例】
USE view_demo;

-- 查看视图定义
SHOW CREATE VIEW v_it_employees;
SHOW CREATE TABLE v_it_employees;  -- 也可以用SHOW CREATE TABLE

-- 查看当前数据库所有视图
SHOW TABLE STATUS WHERE Comment = 'VIEW';

-- 修改视图（方式1：CREATE OR REPLACE）
CREATE OR REPLACE VIEW v_it_employees AS
SELECT emp_id, emp_name, salary, dept_id
FROM t_emp
WHERE dept_id = 1
WITH CHECK OPTION;

-- 修改视图（方式2：ALTER）
ALTER VIEW v_it_employees AS
SELECT emp_id, emp_name, salary
FROM t_emp
WHERE dept_id = 1;

-- 删除视图
DROP VIEW IF EXISTS v_it_employees;
DROP VIEW IF EXISTS v_dept_summary;

-- 批量删除视图（存储过程或脚本中常用）
-- SELECT CONCAT('DROP VIEW IF EXISTS ', TABLE_NAME, ';')
-- FROM INFORMATION_SCHEMA.VIEWS
-- WHERE TABLE_SCHEMA = 'view_demo';

SHOW TABLES;  -- 视图不显示在表列表中
SHOW FULL TABLES WHERE Table_type = 'VIEW';  -- 显示视图

-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================
-- | 特性            | MySQL               | PostgreSQL           | Oracle              | SQLite              |
-- |---------------|---------------------|---------------------|---------------------|--------------------|
-- | 物化视图        | 不支持              | 支持（可物化）        | 支持                 | 不支持              |
-- | 可更新视图      | 有限支持            | 支持                  | 支持                 | 支持                |
-- | CHECK OPTION   | 支持                | 支持                  | 支持                 | 支持                |
-- | 视图算法        | MERGE/UNDEFINED/TEMPTABLE | 无（总是合并）  | 无                    | 无                  |
-- | WITH CHECK OPTION | 支持（MySQL特有命名） | 同MySQL           | 同MySQL              | 同MySQL              |
-- | 视图上的索引    | 无法创建            | 可在物化视图建索引      | 可在视图建索引        | 无法创建              |
-- | 递归视图        | 不支持              | 支持RECURSIVE          | 支持CONNECT BY        | 不支持              |

-- PostgreSQL物化视图：
-- CREATE MATERIALIZED VIEW mv_sales AS SELECT ...;
-- REFRESH MATERIALIZED VIEW mv_sales; -- 刷新数据

-- Oracle递归查询（MySQL不支持，需用递归CTE 8.0+）：
-- SELECT * FROM employees START WITH id = 1 CONNECT BY PRIOR id = manager_id;

-- MySQL 8.0+递归CTE替代Oracle CONNECT BY：
-- WITH RECURSIVE emp_tree AS (
--     SELECT id, name, manager_id FROM employees WHERE id = 1
--     UNION ALL
--     SELECT e.id, e.name, e.manager_id FROM employees e
--     INNER JOIN emp_tree ON e.manager_id = emp_tree.id
-- )
-- SELECT * FROM emp_tree;

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 创建一个视图v_emp_salaries，显示员工姓名和薪资，
--    通过该视图更新某员工的薪资，验证更新是否反映到基表。

-- 2. 创建两个视图：简单视图（不含聚合）和复杂视图（含GROUP BY），
--    尝试对复杂视图执行INSERT/UPDATE，验证哪些操作会失败并说明原因。

-- 3. 创建带WITH CHECK OPTION的视图：只显示IT部门的员工，
--    尝试插入一个非IT部门的员工，验证WITH CHECK OPTION如何阻止操作。

-- 4. 用视图封装一个多表JOIN查询（部门+员工+职位），
--    后续只需SELECT * FROM v_complex_emp即可查询，不需要每次写复杂JOIN。

-- 5. 查询INFORMATION_SCHEMA.VIEWS，列出当前数据库中所有视图的名称和定义。
