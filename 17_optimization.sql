-- ================================================================
-- 模块十七：SQL优化
-- ================================================================

-- Q1: 如何使用EXPLAIN分析查询执行计划？

-- 【解答】
-- EXPLAIN：分析SQL语句的执行计划，显示MySQL如何执行查询
-- 关键列：type（访问类型）、key（使用的索引）、rows（扫描行数）、Extra（额外信息）

-- 【原理】
-- type性能排序（从好到差）：
-- system > const > eq_ref > ref > range > index > ALL
-- const：通过主键或唯一索引直接定位，单行
-- eq_ref：多表JOIN时，通过主键/唯一索引匹配
-- ref：通过普通索引匹配
-- range：索引范围扫描
-- index：全索引扫描
-- ALL：全表扫描（最差）

-- 【示例】
DROP DATABASE IF EXISTS optimization_demo;
CREATE DATABASE optimization_demo;
USE optimization_demo;

CREATE TABLE t_products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category VARCHAR(50),
    name VARCHAR(100),
    price DECIMAL(10,2),
    stock INT,
    create_time DATETIME
);
CREATE INDEX idx_category ON t_products(category);
CREATE INDEX idx_price ON t_products(price);

INSERT INTO t_products (category, name, price, stock)
SELECT
    CONCAT('Category_', CHAR_LENGTH(n)),
    CONCAT('Product_', n),
    (n * 10.5),
    FLOOR(RAND() * 1000)
FROM (
    SELECT a.n + b.n * 10 + c.n * 100 AS n FROM
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
) t;

-- EXPLAIN分析
EXPLAIN SELECT * FROM t_products WHERE id = 1;            -- type=const（主键查找）
EXPLAIN SELECT * FROM t_products WHERE category = 'Category_5';  -- type=ref（普通索引）
EXPLAIN SELECT * FROM t_products WHERE price > 100;      -- type=range（范围）
EXPLAIN SELECT * FROM t_products WHERE name = 'Product_100'; -- type=ALL（无索引）

-- 完整EXPLAIN输出解读
EXPLAIN SELECT category, COUNT(*) FROM t_products WHERE price > 50 GROUP BY category;
-- id: 1
-- select_type: SIMPLE
-- table: t_products
-- type: ALL（无索引可用）
-- possible_keys: NULL（没有可用索引）
-- key: NULL（实际使用的索引）
-- rows: 1000（预估扫描1000行）
-- Extra: Using where; Using temporary; Using filesort

-- ================================================================
-- Q2: 慢查询日志是什么？如何开启和分析？

-- 【解答】
-- 慢查询日志：记录执行时间超过阈值的SQL语句
-- 开启：slow_query_log=1，slow_query_log_file指定日志文件路径
-- 分析：mysqldumpslow工具或pt-query-digest

-- 【原理】
-- MySQL将慢SQL写入日志文件，方便后续分析优化。
-- long_query_time：设置慢查询阈值（默认10秒）
-- log_queries_not_using_indexes：记录未使用索引的查询
-- 注意：开启慢查询日志会影响性能，生产环境按需开启

-- 【示例】
USE optimization_demo;

-- 查看慢查询配置
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 临时开启慢查询日志（需要管理员权限）
-- SET GLOBAL slow_query_log = 1;
-- SET GLOBAL long_query_time = 1;  -- 超过1秒记录

-- 模拟慢查询
-- SELECT SLEEP(2);  -- 模拟执行2秒的查询

-- 实际生产环境使用mysqldumpslow分析
-- mysqldumpslow slow_query_log_file
-- 常见参数：
-- -s: 排序方式（c=执行次数，t=总时间，l=锁定时间）
-- -r: 倒序排列
-- -t: 只显示前N条

-- pt-query-digest（Percona工具）更强大
-- pt-query-digest slow_query_log_file

-- ================================================================
-- Q3: 为什么要避免SELECT *？

-- 【解答】
-- 1. 增加网络传输：传输不需要的列浪费带宽
-- 2. 无法利用覆盖索引：需要回表获取所有列
-- 3. 索引失效：某些优化器在SELECT * 时无法使用索引
-- 4. 维护困难：表结构变更后，可能返回不同列

-- 【原理】
-- SELECT * 会查询所有列，包括不需要的。
-- 如果只需要部分列，明确列出可以：
--   1. 减少网络传输量
--   2. 可能使用覆盖索引避免回表
--   3. 让EXPLAIN更清晰地显示查询计划

-- 【示例】
USE optimization_demo;

CREATE TABLE t_user_detail (
    id INT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200),
    create_time DATETIME
);
CREATE INDEX idx_username ON t_user_detail(username);

-- 差查询：SELECT *
EXPLAIN SELECT * FROM t_user_detail WHERE username = 'user_1';
-- type=ref, Using where

-- 好查询：只查需要的列
EXPLAIN SELECT username, email FROM t_user_detail WHERE username = 'user_1';
-- type=ref, Using index（覆盖索引，无需回表）

-- ================================================================
-- Q4: 分页查询如何优化？

-- 【解答】
-- 深度分页（OFFSET很大）会导致性能问题，因为要扫描并丢弃大量数据
-- 优化方案：延迟关联、游标分页、ID范围查询

-- 【原理】
-- LIMIT 10000, 10：MySQL先扫描前10010行，再丢弃前10000行返回10行。
-- 优化思路：不扫描已跳过的行，或直接定位起始位置。

-- 【示例】
USE optimization_demo;

CREATE TABLE t_article (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100),
    author_id INT,
    publish_date DATE
);
CREATE INDEX idx_publish_date ON t_article(publish_date);

INSERT INTO t_article (title, author_id, publish_date)
SELECT CONCAT('Article_', n), FLOOR(RAND() * 100), CURDATE()
FROM (
    SELECT a.n + b.n * 10 + c.n * 100 AS n FROM
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
) t;

-- 深度分页问题
EXPLAIN SELECT * FROM t_article ORDER BY id LIMIT 10000, 10;
-- rows=10010，需要扫描10010行

-- 优化方案1：延迟关联（先分页查ID，再关联获取完整数据）
EXPLAIN SELECT a.* FROM t_article a
INNER JOIN (SELECT id FROM t_article ORDER BY id LIMIT 10000, 10) AS b ON a.id = b.id;

-- 优化方案2：游标分页（记录上一页最后一条的ID）
-- 第一页
SELECT * FROM t_article ORDER BY id LIMIT 10;  -- 假设最后一页最后一条id=10
-- 第二页（基于上一页的最后ID）
SELECT * FROM t_article WHERE id > 10 ORDER BY id LIMIT 10;
-- 这种方式不走OFFSET，直接从ID位置开始

-- ================================================================
-- Q5: SQL优化的常见技巧有哪些？

-- 【解答】
-- 1. 合理创建索引
-- 2. 避免全表扫描
-- 3. 避免索引失效
-- 4. 减少JOIN，使用EXISTS替代IN
-- 5. 分批操作大数据
-- 6. 避免大事务
-- 7. 优化慢查询

-- 【原理】
-- 优化是一个综合工程，需要结合EXPLAIN和实际业务。
-- 优先优化最慢的查询（80/20法则）。
-- 不要过度优化，满足业务需求即可。

-- 【示例】
USE optimization_demo;

-- 技巧1：创建合适的索引
CREATE INDEX idx_composite ON t_products(category, price, stock);

-- 技巧2：避免全表扫描（添加WHERE条件）
-- 差：SELECT * FROM t_products
-- 好：SELECT * FROM t_products WHERE id > 0

-- 技巧3：避免索引失效（不在索引列上使用函数）
-- 差：WHERE YEAR(create_time) = 2024
-- 好：WHERE create_time >= '2024-01-01' AND create_time < '2025-01-01'

-- 技巧4：EXISTS替代IN（子查询返回大结果集时）
-- 差：SELECT * FROM t_products WHERE category IN (SELECT category FROM t_products GROUP BY category HAVING COUNT(*) > 10)
-- 好：SELECT * FROM t_products p WHERE EXISTS (SELECT 1 FROM t_categories c WHERE c.category = p.category AND c.cnt > 10)

-- 技巧5：分批操作大数据
-- 差：DELETE FROM t_products WHERE id < 10000
-- 好：循环分批删除，每次删除1000条
-- DELETE FROM t_products WHERE id < 1000;
-- DELETE FROM t_products WHERE id < 2000 AND id >= 1000;
-- ...

-- 技巧6：避免大事务
-- 差：一个事务插入10万条数据
-- 好：分批提交，每批1000条

-- 技巧7：使用EXPLAIN分析
EXPLAIN SELECT category, COUNT(*), AVG(price) FROM t_products GROUP BY category;

-- ================================================================
-- Q6: 如何优化INSERT语句的性能？

-- 【解答】
-- 批量插入比逐条插入快很多
-- 使用LOAD DATA INFILE是最高效的方式
-- 关闭自动提交、禁用索引可以提升性能

-- 【原理】
-- 逐条插入：每条记录都经过解析、日志、提交过程。
-- 批量插入：分摊固定开销，性能提升10-100倍。
-- LOAD DATA INFILE：绕过SQL层，直接读取文件写入，效率最高。

-- 【示例】
USE optimization_demo;

-- 批量INSERT优化
-- 差：逐条插入
INSERT INTO t_products (category, name, price, stock) VALUES ('C1', 'P1', 10, 100);
INSERT INTO t_products (category, name, price, stock) VALUES ('C2', 'P2', 20, 100);
INSERT INTO t_products (category, name, price, stock) VALUES ('C3', 'P3', 30, 100);

-- 好：批量插入
INSERT INTO t_products (category, name, price, stock) VALUES
    ('C1', 'P1', 10, 100),
    ('C2', 'P2', 20, 100),
    ('C3', 'P3', 30, 100);

-- 大量数据插入优化
-- 1. 禁用索引（插入后重建）
ALTER TABLE t_products DISABLE KEYS;
INSERT INTO t_products (category, name, price, stock) VALUES (...);
ALTER TABLE t_products ENABLE KEYS;

-- 2. 关闭自动提交
SET autocommit = 0;
INSERT INTO t_products ...;
INSERT INTO t_products ...;
COMMIT;
SET autocommit = 1;

-- 3. LOAD DATA INFILE（最快）
-- LOAD DATA INFILE '/tmp/products.csv'
-- INTO TABLE t_products
-- FIELDS TERMINATED BY ','
-- LINES TERMINATED BY '\n'
-- (category, name, price, stock);

-- ================================================================
-- Q7: MySQL 8.0的新特性对优化有什么帮助？

-- 【解答】
-- 1. 直方图（Histogram）：统计信息更精确，优化器决策更准确
-- 2. 索引隐藏（Invisible Indexes）：隐藏索引进行测试，不影响查询
-- 3. 资源组（Resource Groups）：控制查询占用的CPU资源
-- 4. CTE（公用表表达式）：简化复杂查询
-- 5. 窗口函数（Window Functions）：SQL2003标准窗口函数

-- 【原理】
-- 直方图：ANALYZE TABLE时生成，帮助优化器选择最优执行计划。
-- 隐藏索引：VISIBLE/INVISIBLE属性，可在不影响生产环境的情况下测试索引效果。
-- CTE：把复杂查询分解为可读的部分，支持递归查询。

-- 【示例】
USE optimization_demo;

-- 直方图（Histogram）
-- ANALYZE TABLE t_products UPDATE HISTOGRAM ON price WITH 100 BUCKETS;
-- SELECT * FROM information_schema.COLUMN_STATISTICS;

-- 索引隐藏
-- CREATE INDEX idx_test ON t_products(name) INVISIBLE;
-- SET optimizer_switch = 'use_invisible_indexes=off';  -- 会话级禁用
-- 测试完成后：DROP INDEX idx_test 或 ALTER INDEX idx_test VISIBLE;

-- 窗口函数
SELECT
    category,
    price,
    AVG(price) OVER (PARTITION BY category) AS category_avg,
    price - AVG(price) OVER (PARTITION BY category) AS diff_from_avg
FROM t_products;

-- CTE（公用表表达式）
WITH high_value_products AS (
    SELECT * FROM t_products WHERE price > 100
)
SELECT category, COUNT(*) FROM high_value_products GROUP BY category;

-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================
-- | 特性            | MySQL               | PostgreSQL           | Oracle              | SQLite              |
-- |---------------|---------------------|---------------------|---------------------|--------------------|
-- | 执行计划查看    | EXPLAIN             | EXPLAIN/EXPLAIN ANALYZE | EXPLAIN PLAN FOR   | EXPLAIN QUERY PLAN |
-- | EXPLAIN ANALYZE| 8.0.18+支持         | 支持                  | 不直接支持            | 不支持              |
-- | 慢查询日志      | slow_query_log      | log_min_duration_statement | 无（用AWR/ASH）  | 不支持              |
-- | 索引提示        | USE INDEX/FORCE INDEX | 不支持              | HINTS               | 不支持              |
-- | CTE(公用表表达式)| 8.0+支持           | 支持                  | 12c+支持             | 3.8+支持           |
-- | 窗口函数        | 8.0+支持            | 9.1+支持             | 支持                 | 3.25+支持           |
-- | 递归CTE        | 8.0+支持            | 支持                  | 11gR2+支持           | 3.8+支持           |
-- | 直方图          | 8.0+支持            | 支持                  | DBMS_STATS          | ANALYZE TABLE      |

-- PostgreSQL EXPLAIN ANALYZE（实际执行并显示真实时间）：
-- EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT * FROM t;

-- Oracle执行计划：
-- EXPLAIN PLAN FOR SELECT * FROM t WHERE id = 1;
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- SQLite执行计划：
-- EXPLAIN QUERY PLAN SELECT * FROM t WHERE id = 1;

-- PostgreSQL的日志配置：
-- ALTER SYSTEM SET log_min_duration_statement = 1000; -- 记录超过1秒的查询

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 用EXPLAIN分析以下查询计划的各个字段：
--    SELECT category, AVG(price) FROM t_products GROUP BY category。
--    解释type、possible_keys、key、rows、Extra各字段的含义。

-- 2. 创建一个10000行的表，实现深度分页：
--    (a) 直接用 LIMIT 9000, 10，观察扫描行数
--    (b) 改写为延迟关联：先LIMIT查ID，再JOIN查完整数据，观察行数变化

-- 3. 对比SELECT * vs SELECT具体列名 的EXPLAIN输出差异，
--    如果被查询的列有覆盖索引，验证Using index出现的位置。

-- 4. 模拟慢查询：用SELECT SLEEP(n) 或 让查询扫描大量数据，
--    开启慢查询日志（SET GLOBAL slow_query_log=1; SET GLOBAL long_query_time=1;），
--    执行慢SQL后，查看日志文件中的记录。

-- 5. 用EXPLAIN分析WHERE price > 100 和 WHERE YEAR(create_time) = 2024 两条查询，
--    找出索引失效的查询，并说明失效原因和改进方案。
