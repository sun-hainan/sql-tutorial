-- ================================================================
-- 模块九：聚合与分组
-- ================================================================

-- Q1: 聚合函数有哪些？各自的作用和使用场景？

-- 【解答】
-- COUNT：统计数量
-- SUM：求和
-- AVG：求平均值
-- MAX：最大值
-- MIN：最小值

-- 【原理】
-- 聚合函数对一组值进行计算，返回单个值。
-- COUNT(*)统计行数，COUNT(col)统计非NULL值数量。
-- SUM/AVG只对数值类型有效，MAX/MIN对数值、字符串、日期都有效。

-- 【示例】
DROP DATABASE IF EXISTS aggregation_demo;
CREATE DATABASE aggregation_demo;
USE aggregation_demo;

CREATE TABLE t_sales (
    id INT PRIMARY KEY AUTO_INCREMENT,
    region VARCHAR(20),
    product VARCHAR(50),
    amount DECIMAL(10,2),
    sale_date DATE
);
INSERT INTO t_sales (region, product, amount, sale_date) VALUES
    ('North', 'Laptop', 5000.00, '2024-01-15'),
    ('North', 'Mouse', 99.00, '2024-01-16'),
    ('South', 'Laptop', 4800.00, '2024-01-17'),
    ('South', 'Keyboard', 299.00, '2024-01-18'),
    ('East', 'Laptop', 5200.00, '2024-01-19'),
    ('West', 'Mouse', 89.00, '2024-01-20');

-- COUNT
SELECT COUNT(*) AS total_records FROM t_sales;        -- 总行数
SELECT COUNT(DISTINCT region) AS region_count FROM t_sales;  -- 去重后的区域数
SELECT COUNT(amount) AS records_with_amount FROM t_sales;  -- amount非NULL的行数

-- SUM
SELECT SUM(amount) AS total_amount FROM t_sales;
SELECT region, SUM(amount) AS region_total FROM t_sales GROUP BY region;

-- AVG
SELECT AVG(amount) AS average_amount FROM t_sales;
SELECT region, AVG(amount) AS region_avg FROM t_sales GROUP BY region;

-- MAX/MIN
SELECT MAX(sale_date) AS latest_sale, MIN(sale_date) AS earliest_sale FROM t_sales;
SELECT MAX(amount) AS max_amount, MIN(amount) AS min_amount FROM t_sales;

-- 组合使用
SELECT
    COUNT(*) AS record_count,
    SUM(amount) AS total,
    AVG(amount) AS average,
    MAX(amount) AS maximum,
    MIN(amount) AS minimum
FROM t_sales;

-- ================================================================
-- Q2: GROUP BY的使用方法和注意事项？

-- 【解答】
-- GROUP BY：按一个或多个列分组，使聚合函数作用于每个组
-- SELECT的非聚合列必须出现在GROUP BY中（MySQL5.7+默认开启严格检查）

-- 【原理】
-- GROUP BY后，SELECT只能包含分组列和聚合函数（MySQL 5.7+）。
-- 分组列值相同的记录被合并为一组。
-- NULL值会归为同一组。
-- GROUP BY的列会自动按该列排序（可以用ORDER BY覆盖）。

-- 【示例】
USE aggregation_demo;

-- 基础GROUP BY
SELECT region, COUNT(*) AS cnt FROM t_sales GROUP BY region;

-- 多列分组
SELECT region, product, SUM(amount) AS total
FROM t_sales
GROUP BY region, product
ORDER BY region, product;

-- GROUP BY + 聚合函数组合
SELECT
    region,
    COUNT(*) AS order_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    MAX(amount) AS max_order,
    MIN(amount) AS min_order
FROM t_sales
GROUP BY region;

-- GROUP BY + WHERE + ORDER BY
SELECT region, SUM(amount) AS total
FROM t_sales
WHERE amount > 100
GROUP BY region
ORDER BY total DESC;

-- GROUP BY的列会自动排序
EXPLAIN SELECT region, SUM(amount) FROM t_sales GROUP BY region;
-- Extra列显示 "Using filesort" 因为GROUP BY隐含排序

-- 多列分组时NULL值处理
INSERT INTO t_sales VALUES (7, NULL, 'Mouse', 50.00, '2024-01-21');
SELECT region, product, SUM(amount) FROM t_sales GROUP BY region, product;
-- region=NULL的记录被归为一组

-- ================================================================
-- Q3: HAVING和WHERE的区别？为什么需要HAVING？

-- 【解答】
-- WHERE：在GROUP BY之前过滤，针对单条记录
-- HAVING：在GROUP BY之后过滤，针对分组结果

-- 【原理】
-- WHERE过滤发生在分组之前，所以不能使用聚合函数。
-- HAVING过滤发生在分组之后，可以使用聚合函数。
-- 如果需要过滤分组后的聚合结果，必须用HAVING。

-- 【示例】
USE aggregation_demo;

-- 场景：筛选销售额超过1000元的区域
-- 错误做法：用WHERE过滤聚合结果
-- SELECT region, SUM(amount) FROM t_sales WHERE SUM(amount) > 1000 GROUP BY region;  -- Error

-- 正确做法：用HAVING
SELECT region, SUM(amount) AS total_amount
FROM t_sales
GROUP BY region
HAVING SUM(amount) > 1000;

-- WHERE和HAVING组合
SELECT region, product, SUM(amount) AS total
FROM t_sales
WHERE product IN ('Laptop', 'Mouse')   -- 第一步：WHERE过滤单条记录
GROUP BY region, product              -- 第二步：分组
HAVING SUM(amount) > 100               -- 第三步：HAVING过滤分组
ORDER BY total DESC;                  -- 第四步：排序

-- HAVING vs WHERE 时间顺序
-- FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
-- 所以WHERE在过滤时还不知道分组，HAVING在分组后才过滤

-- 典型场景：平均成绩大于80的学生
CREATE TABLE t_student_score (
    student_id INT,
    student_name VARCHAR(50),
    subject VARCHAR(20),
    score INT
);
INSERT INTO t_student_score VALUES
    (1, 'Alice', 'Math', 85),
    (1, 'Alice', 'English', 90),
    (2, 'Bob', 'Math', 70),
    (2, 'Bob', 'English', 75),
    (3, 'Carol', 'Math', 92),
    (3, 'Carol', 'English', 88);

SELECT student_name, AVG(score) AS avg_score
FROM t_student_score
GROUP BY student_name
HAVING AVG(score) > 80
ORDER BY avg_score DESC;

-- ================================================================
-- Q4: 分组后排序和分页的实现？

-- 【解答】
-- ORDER BY：对最终结果排序（分组的聚合结果可排序）
-- LIMIT：配合ORDER BY实现分组后的分页

-- 【原理】
-- 分组后排序：用ORDER BY对聚合结果排序，是最常见的需求。
-- 分页语法：LIMIT n OFFSET m 或 LIMIT m, n。
-- 分页计算：(page-1) * page_size, page_size

-- 【示例】
USE aggregation_demo;

-- 按总销售额降序排列区域
SELECT region, SUM(amount) AS total
FROM t_sales
GROUP BY region
ORDER BY total DESC;

-- 分页（Top N）
SELECT region, SUM(amount) AS total
FROM t_sales
GROUP BY region
ORDER BY total DESC
LIMIT 2 OFFSET 0;  -- 前2名区域

-- 每页显示2条，查询第2页
SELECT region, SUM(amount) AS total
FROM t_sales
GROUP BY region
ORDER BY total DESC
LIMIT 2 OFFSET 2;  -- 第3-4名区域

-- 综合示例：分组统计、过滤、排序、分页
SELECT
    region,
    product,
    COUNT(*) AS order_count,
    SUM(amount) AS total_amount
FROM t_sales
WHERE sale_date >= '2024-01-01'
GROUP BY region, product
HAVING SUM(amount) > 100
ORDER BY total_amount DESC
LIMIT 10;

-- ================================================================
-- Q5: COUNT(*) vs COUNT(column)的区别？

-- 【解答】
-- COUNT(*)：统计所有行数，包括NULL
-- COUNT(column)：统计该列中非NULL值的数量

-- 【原理】
-- COUNT(*)：InnoDB会优化为常量COUNT，不读取实际数据，只统计行数
-- COUNT(column)：需要检查该列是否为NULL，只有非NULL才计数
-- COUNT(主键列) 等价于 COUNT(*)

-- 【示例】
USE aggregation_demo;

CREATE TABLE t_count_test (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    email VARCHAR(100)
);
INSERT INTO t_count_test (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', NULL),
    ('Carol', 'carol@example.com');

SELECT
    COUNT(*) AS count_all,           -- 3（所有行）
    COUNT(name) AS count_name,       -- 3（name没有NULL）
    COUNT(email) AS count_email,     -- 2（email有1个NULL）
    COUNT(DISTINCT name) AS count_distinct_name  -- 3
FROM t_count_test;

-- 实际场景：统计有邮箱的用户数 vs 所有用户数
-- 有邮箱用户数（COUNT(email)）
-- 所有用户数（COUNT(*)）

-- COUNT(DISTINCT) 去重统计
SELECT COUNT(DISTINCT region) AS region_num FROM t_sales;
SELECT COUNT(DISTINCT product) AS product_num FROM t_sales;

-- ================================================================
-- Q6: 窗口函数（Window Functions）是什么？与聚合函数的区别？

-- 【解答】
-- 窗口函数：对一组行计算，但不会像GROUP BY那样将行合并成一行
-- 关键区别：聚合函数返回单值，窗口函数返回每一行的计算结果

-- 【原理】
-- 窗口函数语法：function() OVER (PARTITION BY col ORDER BY col)
-- 常用窗口函数：ROW_NUMBER() / RANK() / DENSE_RANK() / LEAD() / LAG()
-- PARTITION BY：分区（类似GROUP BY，但不合并行）
-- ORDER BY：区内排序

-- 【示例】
USE aggregation_demo;

-- 场景：每个区域内，按销售额排名
SELECT
    region,
    product,
    amount,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY amount DESC) AS rank_in_region
FROM t_sales;

-- RANK vs DENSE_RANK（处理并列排名）
INSERT INTO t_sales VALUES (8, 'East', 'Laptop', 5200.00, '2024-01-22');
SELECT
    region,
    product,
    amount,
    RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS rank,
    DENSE_RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY amount DESC) AS row_num
FROM t_sales;

-- 累计求和（窗口函数配合聚合函数）
SELECT
    id,
    amount,
    SUM(amount) OVER (ORDER BY id) AS cumulative_sum,
    AVG(amount) OVER (ORDER BY id) AS cumulative_avg
FROM t_sales;

-- LAG/LEAD（访问前一行/后一行）
SELECT
    id,
    amount,
    LAG(amount) OVER (ORDER BY id) AS prev_amount,
    amount - LAG(amount) OVER (ORDER BY id) AS amount_diff,
    LEAD(amount) OVER (ORDER BY id) AS next_amount
FROM t_sales;

-- 分组后组内排名
SELECT
    region,
    product,
    amount,
    RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS regional_rank
FROM t_sales
ORDER BY region, regional_rank;
