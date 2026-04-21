# 模块十七：SQL 优化

## 学习目标

- 掌握 EXPLAIN 分析查询执行计划
- 理解慢查询日志的使用
- 掌握避免 SELECT * 的原因
- 掌握分页查询优化方法
- 掌握常见的 SQL 优化技巧
- 理解 MySQL 8.0 新特性对优化的帮助

---

## 1. EXPLAIN 分析查询执行计划

### 🏠 生活类比

> **EXPLAIN** = GPS 导航：告诉你走哪条路、预计多少时间、有没有堵车

### 📖 概念讲解

**type 性能排序**（从好到差）：

```
system > const > eq_ref > ref > range > index > ALL
```

| type | 说明 | 场景 |
|------|------|------|
| system | 系统表，只有1行 | 极少 |
| const | 主键/唯一索引直接定位 | PRIMARY KEY 或 UNIQUE |
| eq_ref | 多表 JOIN，主键/唯一索引匹配 | 完美 JOIN |
| ref | 普通索引匹配 | 非唯一索引 |
| range | 索引范围扫描 | BETWEEN / IN / > |
| index | 全索引扫描 | 只需索引列 |
| ALL | 全表扫描 | 最差 |

### 💻 SQL 代码示例

```sql
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

-- EXPLAIN 分析
EXPLAIN SELECT * FROM t_products WHERE id = 1;              -- type=const（主键查找）
EXPLAIN SELECT * FROM t_products WHERE category = 'Category_5'; -- type=ref
EXPLAIN SELECT * FROM t_products WHERE price > 100;          -- type=range
EXPLAIN SELECT * FROM t_products WHERE name = 'Product_100';  -- type=ALL（无索引）

-- 完整 EXPLAIN 输出解读
EXPLAIN SELECT category, COUNT(*) FROM t_products WHERE price > 50 GROUP BY category;
-- type=ALL：无索引可用
-- rows=1000：预估扫描1000行
-- Extra: Using where; Using temporary; Using filesort
```

### ❌ 常见错误

- ❌ 以为 type=ALL 一定慢 → 小表或需要返回大部分行时，ALL 可能比 index 更快

---

## 2. 慢查询日志

### 📖 概念讲解

| 配置项 | 说明 |
|--------|------|
| slow_query_log | 是否开启慢查询日志 |
| slow_query_log_file | 日志文件路径 |
| long_query_time | 慢查询阈值（默认10秒） |
| log_queries_not_using_indexes | 记录未使用索引的查询 |

### 💻 SQL 代码示例

```sql
USE optimization_demo;

-- 查看慢查询配置
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 临时开启慢查询日志
-- SET GLOBAL slow_query_log = 1;
-- SET GLOBAL long_query_time = 1;

-- mysqldumpslow 分析日志
-- mysqldumpslow slow_query_log_file
-- 常用参数：-s c（按次数排序）、-t 10（显示前10条）
```

### ❌ 常见错误

- ❌ 生产环境全开慢查询日志 → 性能影响，应按需开启

---

## 3. 为什么要避免 SELECT *

### 📖 概念讲解

**SELECT * 的问题**：

1. 增加网络传输（传输不需要的列）
2. 无法利用覆盖索引（需要回表）
3. 索引失效（某些优化器场景下）
4. 维护困难（表结构变更后返回不同列）

### 💻 SQL 代码示例

```sql
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

-- 差：SELECT *
EXPLAIN SELECT * FROM t_user_detail WHERE username = 'user_1';

-- 好：只查需要的列（可能是覆盖索引）
EXPLAIN SELECT username, email FROM t_user_detail WHERE username = 'user_1';
-- type=ref, Using index（覆盖索引）
```

### ❌ 常见错误

- ❌ 无论什么场景都用 SELECT * → 应该明确列出需要的列

---

## 4. 分页查询优化

### 🏠 生活类比

> **深度分页** = 从书第 1000 页开始读 10 页：要翻过前面 1000 页才能开始读

### 📖 概念讲解

**深度分页问题**：
`LIMIT 10000, 10` → MySQL 先扫描前 10010 行，再丢弃前 10000 行返回 10 行

**优化方案**：
1. 延迟关联：先分页查 ID，再关联获取完整数据
2. 游标分页：记录上一页最后一条的 ID，用 WHERE id > last_id
3. ID 范围查询：基于上一页最后 ID 定位

### 💻 SQL 代码示例

```sql
USE optimization_demo;

CREATE TABLE t_article (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100),
    author_id INT,
    publish_date DATE
);
CREATE INDEX idx_publish_date ON t_article(publish_date);

-- 深度分页问题
EXPLAIN SELECT * FROM t_article ORDER BY id LIMIT 10000, 10;
-- rows=10010，需要扫描 10010 行

-- 优化方案1：延迟关联
EXPLAIN
SELECT a.* FROM t_article a
INNER JOIN (
    SELECT id FROM t_article ORDER BY id LIMIT 10000, 10
) AS b ON a.id = b.id;

-- 优化方案2：游标分页
-- 第一页
SELECT * FROM t_article ORDER BY id LIMIT 10;  -- 假设最后 id=10
-- 第二页（基于上一页最后 ID）
SELECT * FROM t_article WHERE id > 10 ORDER BY id LIMIT 10;
-- 不走 OFFSET，直接从 ID 位置开始
```

### ❌ 常见错误

- ❌ 直接用 LIMIT large_offset, small_count → 大 OFFSET 时性能极差

---

## 5. SQL 优化常见技巧

### 💻 SQL 代码示例

```sql
USE optimization_demo;

-- 技巧1：创建合适的复合索引
CREATE INDEX idx_composite ON t_products(category, price, stock);

-- 技巧2：避免全表扫描（添加 WHERE 条件）
-- 差：SELECT * FROM t_products
-- 好：SELECT * FROM t_products WHERE id > 0

-- 技巧3：避免索引列上使用函数
-- 差：WHERE YEAR(create_time) = 2024
-- 好：WHERE create_time >= '2024-01-01' AND create_time < '2025-01-01'

-- 技巧4：EXISTS 替代 IN（子查询返回大结果集时）
-- 差：WHERE category IN (SELECT category FROM t_products GROUP BY category HAVING COUNT(*) > 10)
-- 好：WHERE EXISTS (SELECT 1 FROM t_categories c WHERE c.category = p.category AND c.cnt > 10)

-- 技巧5：分批操作大数据
-- 差：DELETE FROM t_products WHERE id < 10000
-- 好：分批删除，每批 1000 条

-- 技巧6：避免大事务
-- 差：一个事务插入 10 万条数据
-- 好：每批 1000 条，分批提交
```

### ❌ 常见错误

- ❌ 过度优化 → 满足业务需求即可，不要为了 1ms 优化牺牲可读性

---

## 6. INSERT 性能优化

### 📖 概念讲解

| 优化方法 | 说明 |
|---------|------|
| 批量 INSERT | VALUES (...), (...) 比逐条 INSERT 快 10-100 倍 |
| LOAD DATA INFILE | 绕过 SQL 层，直接读取文件，最快 |
| DISABLE KEYS / ENABLE KEYS | 禁用索引，插入后重建 |
| SET autocommit = 0 | 关闭自动提交，最后统一 COMMIT |

### 💻 SQL 代码示例

```sql
USE optimization_demo;

-- 批量 INSERT
-- 好：批量插入
INSERT INTO t_products (category, name, price, stock) VALUES
    ('C1', 'P1', 10, 100),
    ('C2', 'P2', 20, 100),
    ('C3', 'P3', 30, 100);

-- 大量数据插入优化
-- 1. 禁用索引
-- ALTER TABLE t_products DISABLE KEYS;
-- INSERT INTO t_products ...;
-- ALTER TABLE t_products ENABLE KEYS;

-- 2. 关闭自动提交
-- SET autocommit = 0;
-- INSERT INTO t_products ...;
-- INSERT INTO t_products ...;
-- COMMIT;
-- SET autocommit = 1;

-- 3. LOAD DATA INFILE（最快）
-- LOAD DATA INFILE '/tmp/products.csv'
-- INTO TABLE t_products
-- FIELDS TERMINATED BY ','
-- LINES TERMINATED BY '\n'
-- (category, name, price, stock);
```

---

## 7. MySQL 8.0 新特性

### 📖 概念讲解

| 特性 | 说明 |
|------|------|
| 直方图（Histogram） | 统计信息更精确，优化器决策更准 |
| 隐藏索引 | 隐藏索引测试，不影响查询 |
| CTE | 公用表表达式，简化复杂查询 |
| 窗口函数 | SQL2003 标准窗口函数 |
| 索引降序 | 支持 DESC 索引 |

### 💻 SQL 代码示例

```sql
USE optimization_demo;

-- 窗口函数（MySQL 8.0+）
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

-- 直方图（MySQL 8.0+）
-- ANALYZE TABLE t_products UPDATE HISTOGRAM ON price WITH 100 BUCKETS;
```

---

## 本章小结

```
┌─────────────────────────────────────────────────────────┐
│                    SQL 优化核心                           │
├─────────────────────────────────────────────────────────┤
│ EXPLAIN 关键字段：                                     │
│   type: const > eq_ref > ref > range > index > ALL   │
│   key: 实际使用的索引                                  │
│   rows: 预估扫描行数                                  │
│   Extra: Using filesort / Using temporary / Using index │
│                                                          │
│ 避免 SELECT * → 减少网络传输，利用覆盖索引            │
│ 深度分页优化 → 延迟关联 / 游标分页 / ID范围          │
│                                                          │
│ 优化技巧：                                             │
│   创建合适的索引（复合索引）                          │
│   避免索引失效（函数/类型转换/LIKE %开头）           │
│   EXISTS 替代 IN（子查询结果大时）                   │
│   分批操作大数据 / 避免大事务                        │
│   批量 INSERT / LOAD DATA INFILE                      │
│                                                          │
│ MySQL 8.0 新特性：直方图/隐藏索引/CTE/窗口函数      │
└─────────────────────────────────────────────────────────┘
```

---

## 课后练习

**练习 1：EXPLAIN 分析**
用 EXPLAIN 分析 SELECT category, AVG(price) FROM t_products GROUP BY category 的各个字段含义。

**练习 2：深度分页优化**
创建 10000 行的表，(a) 直接用 LIMIT 9000, 10，观察扫描行数 (b) 改写为延迟关联，观察行数变化。

**练习 3：SELECT * vs 具体列名**
对比 SELECT * vs SELECT 具体列名的 EXPLAIN 输出差异，如果有覆盖索引，验证 Using index 出现。

**练习 4：慢查询日志**
模拟慢查询，开启慢查询日志，执行慢 SQL 后查看日志文件中的记录。

**练习 5：索引失效分析**
用 EXPLAIN 分析 WHERE price > 100 和 WHERE YEAR(create_time) = 2024，找出索引失效的查询，并说明原因和改进方案。
