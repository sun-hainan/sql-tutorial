# 模块二：SQL 五大语言分类

## 学习目标

- 理解 SQL 的五大分类：DDL / DML / DQL / DCL / TCL
- 掌握每类语言的核心关键字和作用
- 理解 DDL 与 DML 的本质区别（DDL 自动提交，无法 ROLLBACK）
- 理解 DELETE vs TRUNCATE 的核心差异

---

## 1. SQL 五大分类概述

### 🏠 生活类比

> 把数据库当作一个大型写字楼：
> - **DDL** = 装修队：拆墙、建墙、改格局（**改变结构**）
> - **DML** = 搬运工：搬东西进来、扔东西出去（**改变数据**）
> - **DQL** = 访客：查看、搜索（**只读数据**）
> - **DCL** = 保安：决定谁可以进、出示证件（**权限控制**）
> - **TCL** = 物业管理员：开始/结束工作、交接记录（**事务管理**）

### 📖 概念讲解

| 分类 | 全称 | 中文名 | 核心操作 | 关键字 |
|------|------|--------|----------|--------|
| **DDL** | Data Definition Language | 数据定义语言 | 定义/修改数据库对象结构 | CREATE / ALTER / DROP / TRUNCATE |
| **DML** | Data Manipulation Language | 数据操作语言 | 增删改数据 | INSERT / UPDATE / DELETE / REPLACE |
| **DQL** | Data Query Language | 数据查询语言 | 查询数据 | SELECT |
| **DCL** | Data Control Language | 数据控制语言 | 控制权限和安全 | GRANT / REVOKE |
| **TCL** | Transaction Control Language | 事务控制语言 | 管理事务 | START TRANSACTION / COMMIT / ROLLBACK / SAVEPOINT |

### 💻 SQL 代码示例

```sql
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

-- DML：插入、更新、删除数据
CREATE TABLE t_product (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    price DECIMAL(10,2)
);
INSERT INTO t_product VALUES (1, 'Laptop', 5000.00);
INSERT INTO t_product (id, name, price) VALUES (2, 'Mouse', 99.00);
UPDATE t_product SET price = 89.00 WHERE id = 2;     -- DML
DELETE FROM t_product WHERE id = 1;                   -- DML

-- DQL：查询数据（只读，不改变数据）
INSERT INTO t_product VALUES (1, 'Laptop', 5000.00);
INSERT INTO t_product VALUES (2, 'Mouse', 99.00);
INSERT INTO t_product VALUES (3, 'Keyboard', 299.00);
SELECT * FROM t_product WHERE price > 100 ORDER BY price DESC;

-- DCL：授权（需要管理员权限）
-- GRANT SELECT ON sql分类_demo.t_product TO 'username'@'host';

-- TCL：事务控制
START TRANSACTION;
DELETE FROM t_product WHERE id = 2;
COMMIT;  -- 提交后删除生效

-- 测试 ROLLBACK
START TRANSACTION;
INSERT INTO t_product VALUES (4, 'Monitor', 1299.00);
ROLLBACK;  -- 回滚，插入无效
SELECT * FROM t_product;  -- Monitor 未插入
```

### ❌ 常见错误

- ❌ 以为 DDL 可以回滚 → DDL 自动提交，TRUNCATE 和 DROP 不可恢复
- ❌ DELETE 误用不带 WHERE → 全表删除，可以 ROLLBACK

---

## 2. DDL 详解

### 📖 概念讲解

DDL（Data Definition Language）用于定义和修改数据库对象结构，包括：
- `CREATE` - 创建数据库/表/视图/索引
- `ALTER` - 修改表结构
- `DROP` - 删除数据库/表/视图/索引
- `TRUNCATE` - 清空表数据（保留结构，速度快）

**核心特性：DDL 自动提交，无法回滚！**

### 💻 SQL 代码示例

```sql
USE sql分类_demo;

-- CREATE：创建数据库
CREATE DATABASE ddl_test;

-- CREATE：创建表
CREATE TABLE t_employee (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,   -- NOT NULL 约束
    salary DECIMAL(10,2),
    dept_id INT
);

-- ALTER：添加列
ALTER TABLE t_employee ADD COLUMN email VARCHAR(100);

-- ALTER：修改列
ALTER TABLE t_employee MODIFY COLUMN name VARCHAR(100);

-- ALTER：删除列
ALTER TABLE t_employee DROP COLUMN email;

-- ALTER：添加外键（需要先有被引用表）
CREATE TABLE t_department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
ALTER TABLE t_employee ADD FOREIGN KEY (dept_id) REFERENCES t_department(dept_id);

-- TRUNCATE：清空表（速度极快，不可回滚）
INSERT INTO t_department VALUES (1, 'IT');
INSERT INTO t_employee VALUES (1, 'Alice', 5000, 1);
INSERT INTO t_employee VALUES (2, 'Bob', 6000, 1);
SELECT COUNT(*) FROM t_employee;  -- 2条
TRUNCATE TABLE t_employee;       -- 清空数据，结构保留
SELECT COUNT(*) FROM t_employee;  -- 0条

-- DROP：删除表（彻底删除）
DROP TABLE t_employee;
DROP TABLE t_department;
DROP DATABASE ddl_test;
```

### 📊 DDL vs DML 核心区别

```
┌─────────────────────────────────────────────────────────┐
│                    DDL vs DML                           │
├─────────────────────────────────────────────────────────┤
│ DDL（CREATE/ALTER/DROP/TRUNCATE）                       │
│   → 自动提交，无法 ROLLBACK                              │
│   → 作用对象：结构（表、视图、索引）                     │
│                                                          │
│ DML（INSERT/UPDATE/DELETE）                            │
│   → 可回滚（在事务中）                                   │
│   → 作用对象：数据本身                                   │
└─────────────────────────────────────────────────────────┘
```

### ❌ 常见错误

- ❌ DROP TABLE 误操作 → 数据永久丢失，无法恢复
- ❌ TRUNCATE 在事务中回滚 → TRUNCATE 是 DDL，无法回滚

---

## 3. DML 详解

### 📖 概念讲解

DML（Data Manipulation Language）用于增删改数据：

| 操作 | 关键字 | 是否支持 WHERE | 是否支持事务 |
|------|--------|---------------|-------------|
| 插入 | INSERT | 否（整行） | 可回滚 |
| 更新 | UPDATE | ✅ 是 | 可回滚 |
| 删除 | DELETE | ✅ 是 | 可回滚 |
| 替换 | REPLACE | 否 | 可回滚 |

### 💻 SQL 代码示例

```sql
USE sql分类_demo;

CREATE TABLE t_order (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50),
    amount DECIMAL(10,2),
    status VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 单行插入
INSERT INTO t_order (customer_name, amount, status) VALUES ('Alice', 299.00, 'paid');

-- 多行插入（一次插入多条，效率高）
INSERT INTO t_order (customer_name, amount, status) VALUES
    ('Bob', 599.00, 'paid'),
    ('Carol', 1299.00, 'pending'),
    ('David', 99.00, 'cancelled');

-- 省略列（使用默认值）
INSERT INTO t_order (customer_name, amount) VALUES ('Eve', 399.00);
-- created_at 自动使用 CURRENT_TIMESTAMP

-- UPDATE：更新数据
UPDATE t_order SET status = 'completed', amount = 319.00 WHERE order_id = 1;

-- 批量更新
UPDATE t_order SET amount = amount * 0.9 WHERE status = 'pending';

-- DELETE：删除数据
DELETE FROM t_order WHERE status = 'cancelled';

-- REPLACE：若 order_id 存在则先删后插
CREATE TABLE t_session (
    session_id VARCHAR(50) PRIMARY KEY,
    user_id INT,
    last_active DATETIME
);
REPLACE INTO t_session VALUES ('ABC123', 1, NOW());
REPLACE INTO t_session VALUES ('ABC123', 2, NOW());  -- 覆盖原有记录
SELECT * FROM t_session;  -- 只有1条，user_id=2
```

### ❌ 常见错误

- ❌ UPDATE 不带 WHERE → 更新整表，非常危险！
- ❌ REPLACE 误用 → 会删除旧记录，可能导致自增 ID 变化

---

## 4. DQL 详解

### 🏠 生活类比

> DQL 就像博物馆的导览系统：你可以随意查看、搜索、排序，但**不能带走任何东西**（不改变数据）。

### 📖 概念讲解

DQL（Data Query Language）核心是 `SELECT`，不改变原始数据，是 SQL 中最复杂的部分。

**SELECT 执行顺序**（重要！）

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

### 💻 SQL 代码示例

```sql
USE sql分类_demo;

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

-- 基础查询
SELECT * FROM t_sales;
SELECT region, product, amount FROM t_sales;

-- 条件过滤
SELECT * FROM t_sales WHERE region = 'North';

-- 分组聚合
SELECT region, COUNT(*) AS cnt, SUM(amount) AS total_amount
FROM t_sales GROUP BY region;

-- 排序
SELECT region, SUM(amount) AS total
FROM t_sales
GROUP BY region
ORDER BY total DESC;

-- 分页
SELECT * FROM t_sales LIMIT 3 OFFSET 2;

-- DISTINCT 去重
SELECT DISTINCT region, product FROM t_sales;
```

### ❌ 常见错误

- ❌ SELECT * 滥用 → 应该只查需要的列，减少网络传输
- ❌ WHERE 中使用聚合函数 → 应该用 HAVING（在 GROUP BY 之后）

---

## 5. TCL 详解

### 🏠 生活类比

> 就像编辑文档时的**保存/撤销**操作：
> - BEGIN = 开始编辑
> - COMMIT = 保存文档（永久生效）
> - ROLLBACK = 撤销所有修改（回到保存前）

### 📖 概念讲解

**事务必须满足 ACID 四大特性：**

| 特性 | 说明 |
|------|------|
| Atomicity（原子性） | 事务是最小执行单元，要么全成功，要么全失败 |
| Consistency（一致性） | 事务前后数据状态保持一致 |
| Isolation（隔离性） | 并发事务之间相互隔离 |
| Durability（持久性） | 提交后的修改永久保存 |

### 💻 SQL 代码示例

```sql
USE sql分类_demo;

CREATE TABLE t_account (
    account_id INT PRIMARY KEY,
    account_name VARCHAR(50),
    balance DECIMAL(10,2)
);
INSERT INTO t_account VALUES (1, 'Alice', 10000.00);
INSERT INTO t_account VALUES (2, 'Bob', 5000.00);

-- 转账场景（原子性）
START TRANSACTION;
UPDATE t_account SET balance = balance - 3000 WHERE account_id = 1;
UPDATE t_account SET balance = balance + 3000 WHERE account_id = 2;
COMMIT;  -- 提交

-- 测试回滚
START TRANSACTION;
UPDATE t_account SET balance = balance - 2000 WHERE account_id = 1;
ROLLBACK;  -- 回滚，余额未变

-- SAVEPOINT：部分回滚
START TRANSACTION;
INSERT INTO t_account VALUES (3, 'Carol', 8000.00);
SAVEPOINT sp1;
INSERT INTO t_account VALUES (4, 'David', 3000.00);
ROLLBACK TO SAVEPOINT sp1;  -- 回滚到 sp1，David 被撤销
COMMIT;

SELECT * FROM t_account;  -- Carol 在，David 不在
```

### ❌ 常见错误

- ❌ 忘记 COMMIT → 断开连接后数据丢失
- ❌ 嵌套事务 → MySQL 不支持嵌套事务，应该用 SAVEPOINT

---

## 6. DCL 详解

### 📖 概念讲解

DCL（Data Control Language）用于权限管理：

| 操作 | 关键字 | 作用 |
|------|--------|------|
| 授权 | GRANT | 授予用户权限 |
| 撤销 | REVOKE | 收回用户权限 |

**最小权限原则**：只授予完成任务所需的最小权限。

### 💻 SQL 代码示例（语法演示）

```sql
-- -- 创建用户
-- CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'StrongPwd123!';
-- CREATE USER 'report_user'@'%' IDENTIFIED BY 'ReadOnlyPwd456!';
--
-- -- 授予全局权限（所有数据库）
-- GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'localhost';
-- GRANT SELECT ON *.* TO 'report_user'@'%';
--
-- -- 授予数据库级权限
-- GRANT SELECT, INSERT, UPDATE, DELETE ON sql分类_demo.* TO 'app_user'@'localhost';
--
-- -- 授予表级权限
-- GRANT SELECT ON sql分类_demo.t_order TO 'report_user'@'%';
--
-- -- 撤销权限
-- REVOKE DELETE ON sql分类_demo.* FROM 'app_user'@'localhost';
--
-- -- 查看权限
-- SHOW GRANTS FOR 'app_user'@'localhost';
--
-- -- 删除用户
-- DROP USER 'app_user'@'localhost';
```

### ❌ 常见错误

- ❌ 用 root 用户做应用连接 → 风险极大，应创建专用用户
- ❌ 授予 ALL PRIVILEGES 给所有用户 → 违反最小权限原则

---

## 7. DELETE vs TRUNCATE 核心对比

### 📖 概念讲解

| 特性 | DELETE | TRUNCATE |
|------|--------|----------|
| 类型 | DML（可回滚） | DDL（自动提交） |
| 速度 | 逐行删除，慢 | 直接释放数据页，快 |
| WHERE | 支持条件删除 | 不支持（全表清空） |
| AUTO_INCREMENT | 保留计数器 | 重置为 1 |
| 触发器 | 触发 DELETE 触发器 | 不触发 |
| 日志 | 记录每行删除日志 | 不记录逐行日志 |

### 💻 SQL 代码示例

```sql
USE sql分类_demo;

CREATE TABLE t_compare (
    id INT PRIMARY KEY AUTO_INCREMENT,
    val VARCHAR(50)
);
INSERT INTO t_compare VALUES (1, 'A'), (2, 'B'), (3, 'C');

-- DELETE：可回滚，AUTO_INCREMENT 不重置
START TRANSACTION;
DELETE FROM t_compare;
ROLLBACK;
INSERT INTO t_compare VALUES (4, 'D');
SELECT * FROM t_compare;  -- id=4（AUTO_INCREMENT=3）

-- TRUNCATE：不可回滚，AUTO_INCREMENT 重置
TRUNCATE TABLE t_compare;
INSERT INTO t_compare VALUES (5, 'E');
SELECT * FROM t_compare;  -- id=1（AUTO_INCREMENT 重置）
```

### ❌ 常见错误

- ❌ 在事务中 TRUNCATE 以为能回滚 → TRUNCATE 是 DDL，自动提交
- ❌ 清空大表用 DELETE → 速度慢，应该用 TRUNCATE（但需确认不需要回滚）

---

## 本章小结

```
┌─────────────────────────────────────────────────────────┐
│                   SQL 五大语言分类                       │
├─────────────────────────────────────────────────────────┤
│ DDL（数据定义）→ CREATE/ALTER/DROP/TRUNCATE           │
│   → 自动提交，无法回滚，作用于结构                      │
│                                                          │
│ DML（数据操作）→ INSERT/UPDATE/DELETE/REPLACE          │
│   → 受事务控制，可回滚，作用于数据                      │
│                                                          │
│ DQL（数据查询）→ SELECT                                 │
│   → 只读，不改变数据，60-80% 的业务场景                 │
│                                                          │
│ DCL（数据控制）→ GRANT/REVOKE                          │
│   → 权限管理，遵循最小权限原则                          │
│                                                          │
│ TCL（事务控制）→ COMMIT/ROLLBACK/SAVEPOINT             │
│   → 保证 ACID 特性，支持部分回滚                        │
└─────────────────────────────────────────────────────────┘

执行顺序：FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

---

## 课后练习

**练习 1：五大分类识别**
分别写出属于 DDL、DML、DQL、DCL、TCL 的 SQL 语句各 2 条，说明分类依据。

**练习 2：事务中的 SAVEPOINT**
在事务中执行以下操作：INSERT 一条记录 → 设置 SAVEPOINT → 再 INSERT 一条记录 → ROLLBACK TO SAVEPOINT → COMMIT。验证哪些记录被持久化。

**练习 3：DELETE vs TRUNCATE 对比**
(a) DELETE 可加 WHERE 条件，TRUNCATE 不能
(b) DELETE 是 DML（可 ROLLBACK），TRUNCATE 是 DDL（不可 ROLLBACK）
(c) DELETE 保留 AUTO_INCREMENT，TRUNCATE 重置 AUTO_INCREMENT

**练习 4：PostgreSQL/Oracle Upsert 等效写法**
查找 PostgreSQL/Oracle 中 MySQL REPLACE INTO 语句的等效写法，用 MERGE INTO（Oracle）或 INSERT...ON CONFLICT（PostgreSQL）实现。

**练习 5：验证 SAVEPOINT 回滚行为**
在一个事务中设置多个 SAVEPOINT，多次 ROLLBACK TO SAVEPOINT 到不同点，观察数据状态变化。
