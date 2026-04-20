-- ================================================================
-- 模块十六：索引
-- ================================================================

-- Q1: 索引是什么？为什么需要索引？

-- 【解答】
-- 索引：数据结构，帮助数据库快速定位数据，类似书的目录
-- 为什么需要：全表扫描O(n)，索引查询O(log n)，大幅提升查询性能

-- 【原理】
-- 索引是在存储层面构建的数据结构，用于加速查询。
-- 没有索引时，查询需要扫描全表（逐行检查）。
-- 有索引时，通过索引树快速定位到数据所在的页，再读取数据。
-- 索引的代价：占用存储空间、增删改变慢（需要维护索引结构）。

-- 【示例】
DROP DATABASE IF EXISTS index_demo;
CREATE DATABASE index_demo;
USE index_demo;

CREATE TABLE t_user (
    id INT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    age INT
);
-- 插入大量测试数据
INSERT INTO t_user (id, username, email, phone, age)
SELECT
    n,
    CONCAT('user_', n),
    CONCAT('user_', n, '@example.com'),
    CONCAT('138', LPAD(n, 8, '0')),
    FLOOR(18 + RAND() * 40)
FROM (
    SELECT a.n + b.n * 100 + c.n * 1000 AS n FROM
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
     SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
) t;

-- 没有索引的查询（全表扫描）
EXPLAIN SELECT * FROM t_user WHERE username = 'user_5000';
-- type=ALL 表示全表扫描

-- 创建索引
CREATE INDEX idx_username ON t_user(username);
CREATE INDEX idx_phone ON t_user(phone);

-- 有索引的查询
EXPLAIN SELECT * FROM t_user WHERE username = 'user_5000';
-- type=ref 表示索引查找

-- ================================================================
-- Q2: 索引的分类有哪些？

-- 【解答】
-- 主键索引（PRIMARY）：唯一且非空，每个表一个
-- 唯一索引（UNIQUE）：值唯一，可为空
-- 普通索引（INDEX）：普通索引，无唯一性限制
-- 全文索引（FULLTEXT）：大文本搜索
-- 复合索引（Composite）：多列组合的索引

-- 【原理】
-- 主键索引和唯一索引都是B+树结构，但主键索引是聚簇索引，唯一索引是辅助索引。
-- 复合索引：索引列是(col1, col2, col3)，查询时需要遵循最左前缀原则。
-- 全文索引用于MATCH AGAINST搜索，比LIKE %xxx%高效。

-- 【示例】
USE index_demo;

CREATE TABLE t_employee (
    id INT PRIMARY KEY,                    -- 主键索引
    emp_code VARCHAR(20) UNIQUE,          -- 唯一索引
    emp_name VARCHAR(50),
    dept_id INT,
    email VARCHAR(100),
    resume TEXT,
    INDEX idx_name (emp_name),             -- 普通索引
    INDEX idx_dept (dept_id),              -- 普通索引
    FULLTEXT INDEX idx_resume (resume)     -- 全文索引
);

-- 复合索引
CREATE TABLE t_order (
    id INT PRIMARY KEY,
    order_date DATE,
    customer_id INT,
    status VARCHAR(20),
    INDEX idx_order_composite (order_date, customer_id, status)
);
INSERT INTO t_order VALUES
    (1, '2024-01-15', 101, 'paid'),
    (2, '2024-01-15', 102, 'pending'),
    (3, '2024-01-16', 101, 'shipped');

-- 复合索引生效情况
EXPLAIN SELECT * FROM t_order WHERE order_date = '2024-01-15';           -- 使用索引
EXPLAIN SELECT * FROM t_order WHERE order_date = '2024-01-15' AND customer_id = 101;  -- 使用索引
EXPLAIN SELECT * FROM t_order WHERE customer_id = 101;                  -- 不使用索引（跳过第一列）

-- ================================================================
-- Q3: InnoDB的聚簇索引和非聚簇索引有什么区别？

-- 【解答】
-- 聚簇索引：数据行直接存储在索引叶子节点（主键作为索引）
-- 非聚簇索引（辅助索引）：索引叶子节点存储主键值，需要"回表"查找数据

-- 【原理】
-- InnoDB表必须有主键，主键自动作为聚簇索引。
-- 数据行按主键顺序存储在B+树的叶子节点。
-- 普通索引叶子节点存储主键值，不是数据行位置。
-- 查询过程：先在普通索引找到主键，再在聚簇索引通过主键找到完整数据（回表）。

-- 【示例】
USE index_demo;

-- 主键是聚簇索引
CREATE TABLE t_goods (
    id INT PRIMARY KEY,          -- id是聚簇索引，数据按id顺序存储
    name VARCHAR(50),
    price DECIMAL(10,2)
);
INSERT INTO t_goods VALUES (3, 'Mouse', 99), (1, 'Laptop', 5000), (2, 'Keyboard', 299);
-- 数据按主键id排序：1(Laptop), 2(Keyboard), 3(Mouse)

-- 普通索引是非聚簇索引
CREATE INDEX idx_name ON t_goods(name);

-- 执行 SELECT * FROM t_goods WHERE name = 'Mouse'
-- 1. 在idx_name索引中查找'Mouse'，得到主键id=3
-- 2. 在聚簇索引中通过id=3找到完整数据行

-- 覆盖索引：查询的列都在索引中，不需要回表
SELECT name FROM t_goods WHERE name = 'Mouse';
-- EXPLAIN显示 Using index，表示覆盖索引

-- ================================================================
-- Q4: B+树是什么？为什么适合做索引？

-- 【解答】
-- B+树：自平衡的多路搜索树，所有叶子节点在同一层级
-- InnoDB使用B+树作为索引结构，时间复杂度O(log n)

-- 【原理】
-- B+树特点：
-- 1. 每个节点可存储多个键值（页），扇出大，树层数少（3层可存千万级数据）
-- 2. 叶子节点存储所有数据，叶子节点之间用链表连接（适合范围查询）
-- 3. 非叶子节点只存储键值，不存储数据（每次读取可加载更多索引项）
-- 4. 插入/删除通过分裂合并保持平衡

-- B+树 vs 二叉树：
-- 二叉树：每个节点最多2个子节点，树高=O(log n)
-- B+树：每个节点可有100+个子节点，树高=log_{fanout}(n)，通常3-4层

-- 磁盘读写优化：
-- 每次I/O读取一个页（16KB），B+树一个页可存储更多键值，减少I/O次数

-- ================================================================
-- Q5: 最左前缀原则是什么？

-- 【解答】
-- 复合索引(col1, col2, col3)，查询必须使用col1或col1+col2或col1+col2+col3才能生效

-- 【原理】
-- 复合索引的B+树按创建顺序排列各列。
-- 跳过前面列，后面的列无法有效定位数据。
-- 如果查询条件包含第一列但用OR连接所有列，可能无法使用索引。

-- 【示例】
USE index_demo;

CREATE TABLE t_test_leftmost (
    id INT PRIMARY KEY,
    col1 INT,
    col2 INT,
    col3 INT,
    INDEX idx_composite (col1, col2, col3)
);
INSERT INTO t_test_leftmost VALUES (1, 1, 1, 1), (2, 1, 2, 2), (3, 2, 2, 3), (4, 2, 3, 4);

-- 索引生效情况
EXPLAIN SELECT * FROM t_test_leftmost WHERE col1 = 1;               -- 生效（使用col1）
EXPLAIN SELECT * FROM t_test_leftmost WHERE col1 = 1 AND col2 = 2;   -- 生效（col1+col2）
EXPLAIN SELECT * FROM t_test_leftmost WHERE col1 = 1 AND col2 = 2 AND col3 = 3;  -- 生效（col1+col2+col3）

-- 索引不生效
EXPLAIN SELECT * FROM t_test_leftmost WHERE col2 = 2;               -- 不生效（跳过col1）
EXPLAIN SELECT * FROM t_test_leftmost WHERE col3 = 3;               -- 不生效（跳过col1,col2）

-- 范围查询后的列无法使用索引
EXPLAIN SELECT * FROM t_test_leftmost WHERE col1 = 1 AND col2 > 2 AND col3 = 3;
-- col3的索引无法生效，因为col2是范围查询

-- ================================================================
-- Q6: 什么是回表？如何避免回表？

-- 【解答】
-- 回表：通过普通索引找到主键后，再去聚簇索引查找完整数据
-- 避免回表：使用覆盖索引，查询的列都在索引中

-- 【原理】
-- 每次回表需要两次索引查找（普通索引+聚簇索引）。
-- 覆盖索引：将需要查询的列包含在索引中，一次查找即可获得所有数据。
-- 适合场景：查询列较少且有索引可以覆盖的情况。

-- 【示例】
USE index_demo;

CREATE TABLE t_sales_record (
    id INT PRIMARY KEY,
    sale_date DATE,
    product_name VARCHAR(50),
    amount DECIMAL(10,2)
);
CREATE INDEX idx_sale_date ON t_sales_record(sale_date);

-- 需要回表的查询
EXPLAIN SELECT * FROM t_sales_record WHERE sale_date = '2024-01-15';
-- 需要回表获取product_name和amount

-- 覆盖索引：包含所有需要的列
CREATE INDEX idx_sale_date_cover ON t_sales_record(sale_date, product_name, amount);

EXPLAIN SELECT sale_date, product_name, amount FROM t_sales_record WHERE sale_date = '2024-01-15';
-- Using index，表示覆盖索引，无需回表

-- ================================================================
-- Q7: 哪些场景会导致索引失效？

-- 【解答】
-- 1. 列参与计算（WHERE age + 1 = 30）
-- 2. 使用函数（WHERE YEAR(create_time) = 2024）
-- 3. 类型转换（列是字符串，查询用数字）
-- 4. LIKE以%开头（WHERE name LIKE '%xxx%'）
-- 5. OR连接非索引列（WHERE col1 = 'a' OR col2 = 'b'，col2无索引）
-- 6. NOT/IS NULL可能在某些优化器下失效
-- 7. 使用复合索引时不满足最左前缀

-- 【示例】
USE index_demo;

CREATE TABLE t_idx_test (
    id INT PRIMARY KEY,
    code VARCHAR(20),    -- 字符串类型，有索引
    amount INT,         -- 有索引
    create_time DATETIME  -- 有索引
);
CREATE INDEX idx_code ON t_idx_test(code);
CREATE INDEX idx_amount ON t_idx_test(amount);
CREATE INDEX idx_create_time ON t_idx_test(create_time);

-- 索引失效场景

-- 场景1：列参与计算
EXPLAIN SELECT * FROM t_idx_test WHERE amount + 1 = 100;  -- Using where, Using index（有些优化器会自动处理）

-- 场景2：使用函数
EXPLAIN SELECT * FROM t_idx_test WHERE YEAR(create_time) = 2024;  -- 不使用索引

-- 场景3：类型转换
EXPLAIN SELECT * FROM t_idx_test WHERE code = 123;  -- code是VARCHAR，查询用INT，可能类型转换

-- 场景4：LIKE以%开头
EXPLAIN SELECT * FROM t_idx_test WHERE code LIKE '%123%';  -- 不使用索引
EXPLAIN SELECT * FROM t_idx_test WHERE code LIKE '123%';   -- 使用索引

-- 场景5：OR连接非索引列
EXPLAIN SELECT * FROM t_idx_test WHERE code = 'A001' OR amount = 100;  -- amount有索引但code无索引时可能全表扫描

-- 场景7：不满足最左前缀（已在前文演示）

-- ================================================================
-- Q8: 如何查看和优化索引？

-- 【解答】
-- 查看：SHOW INDEX FROM table_name / EXPLAIN
-- 优化：添加/删除/修改索引，分析查询计划

-- 【原理】
-- EXPLAIN可以分析SQL的执行计划，包括访问类型、索引使用、扫描行数。
-- EXPLAIN ANALYZE（MySQL 8.0+）实际执行并显示实际开销。
-- 优化方向：减少回表、使用覆盖索引、避免全表扫描。

-- 【示例】
USE index_demo;

-- 查看表的所有索引
SHOW INDEX FROM t_user;
SHOW INDEX FROM t_employee;

-- EXPLAIN分析查询计划
EXPLAIN SELECT * FROM t_user WHERE username = 'user_5000';
-- type: const（常量查找，最优）
-- key: idx_username（使用的索引）
-- rows: 1（预估扫描行数）

EXPLAIN SELECT * FROM t_user WHERE phone LIKE '138%';
-- type: range（范围查找）
-- key: idx_phone（使用的索引）

EXPLAIN SELECT * FROM t_user WHERE age > 30;
-- type: ALL（无索引可用，全表扫描）

-- 优化建议
-- 1. 为高频查询条件创建索引
-- 2. 删除不使用的索引（DROP INDEX）
-- 3. 使用复合索引代替单列索引（如果多个列经常一起查询）
