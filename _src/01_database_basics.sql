-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================

-- Q8: 常见关系型数据库（MySQL / PostgreSQL / Oracle / SQLite）核心差异是什么？

-- 【解答】
-- MySQL：开源免费，轻量级，Web应用首选；PostgreSQL：功能最丰富，学术/企业级；
-- Oracle：商业数据库，功能最全但昂贵；SQLite：嵌入式零配置，轻量高效

-- 【对比速查表】
-- | 特性         | MySQL          | PostgreSQL       | Oracle           | SQLite          |
-- |-------------|---------------|-----------------|-----------------|----------------|
-- | License     | GPL/商业       | PostgreSQL BSD   | 商业             | 共有领域(Public Domain)|
-- | 主打场景     | Web应用        | 企业级/学术       | 金融/大型企业     | 嵌入式/移动/测试 |
-- | ACID       | InnoDB完整支持  | 完整支持         | 完整支持          | 完整支持         |
-- | 并发        | 行级锁        | MVCC+行级锁      | 行级锁+多版本     | 读并发好写串行   |
-- | JSON支持    | 5.7+ JSON函数  | 9.2+ JSONB+JSON  | 12c+ JSON       | 原生支持         |
-- | 数组类型    | 不支持        | 支持             | 不支持           | 不支持           |
-- | 范围类型    | 不支持        | 支持             | 不支持           | 不支持           |
-- | 递归CTE     | 8.0+支持       | 9.1+支持         | 11gR2+支持       | 3.8.9+支持       |
-- | 窗口函数    | 8.0+支持       | 9.1+支持         | 支持             | 3.25+支持        |
-- | 分页语法    | LIMIT          | LIMIT/OFFSET     | FETCH FIRST      | LIMIT           |
-- | 自增ID语法  | AUTO_INCREMENT  | SERIAL/BIGSERIAL | SEQUENCE         | AUTOINCREMENT   |
-- | 批量插入    | INSERT...VALUES(...),(...) | 同MySQL | 同MySQL | 同MySQL |

-- 【语法差异示例】
-- 自增ID语法差异：
-- MySQL:    CREATE TABLE t(id INT PRIMARY KEY AUTO_INCREMENT);
-- PostgreSQL: CREATE TABLE t(id SERIAL PRIMARY KEY); 或 BIGSERIAL
-- Oracle:   需要CREATE SEQUENCE + 触发器，或12c的IDENTITY
-- SQLite:   CREATE TABLE t(id INTEGER PRIMARY KEY AUTOINCREMENT);

-- 分页语法差异：
-- MySQL:    SELECT * FROM t ORDER BY id LIMIT 10 OFFSET 20;
-- PostgreSQL: SELECT * FROM t ORDER BY id LIMIT 10 OFFSET 20;
-- Oracle:   SELECT * FROM t ORDER BY id OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
-- SQLite:   SELECT * FROM t ORDER BY id LIMIT 10 OFFSET 20;

-- Upsert语法差异：
-- MySQL:    INSERT ... ON DUPLICATE KEY UPDATE col=val;
-- PostgreSQL: INSERT ... ON CONFLICT(col) DO UPDATE SET col=val;
-- Oracle:   MERGE INTO t USING s ON (t.id=s.id) WHEN MATCHED THEN UPDATE SET ...;
-- SQLite:   INSERT OR REPLACE INTO t VALUES(...);

-- 判断NULL语法（NVL vs IFNULL vs COALESCE）：
-- MySQL:    SELECT IFNULL(col, 'default') FROM t;
-- PostgreSQL: SELECT COALESCE(col, 'default') FROM t;
-- Oracle:   SELECT NVL(col, 'default') FROM t;
-- SQLite:   SELECT IFNULL(col, 'default') FROM t;

-- 字符串拼接差异：
-- MySQL:    SELECT CONCAT('Hello', ' ', 'World'); 或 SELECT 'Hello' || ' ' || 'World' (SQL_MODE开启PIPES_AS_CONCAT)
-- PostgreSQL: SELECT 'Hello' || ' ' || 'World';
-- Oracle:   SELECT 'Hello' || ' ' || 'World' 或 CONCAT('Hello', 'World')
-- SQLite:   SELECT 'Hello' || ' ' || 'World';

-- ================================================================
-- 模块一：数据库基础认知
-- ================================================================

-- Q1: 数据库和普通文件有什么本质区别？为什么不用文件夹代替数据库？

-- 【解答】
-- 文件存储数据靠程序自己解析，数据库用DBMS统一管理，支持并发、事务、安全。
-- 文件 → 程序自己解析 → 并发冲突、数据一致性全靠应用层代码
-- 数据库 → DBMS管理 → ACID保障、并发控制、SQL查询、权限管理

-- 【原理】
-- 数据库本质是"有结构的数据集合 + 管理它的软件系统"。
-- 同一时刻允许多用户访问同一份数据，由DBMS协调，不会像文件那样覆盖。

-- 【示例】
-- 想象Excel文件（单文件）和数据库（多用户同时读写）的区别
DROP DATABASE IF EXISTS db_vs_file;
CREATE DATABASE db_vs_file;

USE db_vs_file;

-- 用文件方式存储：把所有数据写进一个文本文件
-- 文件名: user_data.txt，内容是 JSON，需要代码解析
-- 局限性：无法并发写，无法做事务，无法用SQL查询

-- 用数据库方式存储
CREATE TABLE t_user (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    email VARCHAR(100)
);
INSERT INTO t_user VALUES (1, 'Alice', 'alice@example.com');
INSERT INTO t_user VALUES (2, 'Bob', 'bob@example.com');
-- 查询语句直接筛选，无需加载整个文件到内存
SELECT * FROM t_user WHERE id = 1;

-- ================================================================
-- Q2: 关系型数据库（RDBMS）和非关系型数据库（NoSQL）核心区别是什么？

-- 【解答】
-- 关系型：用表和行列组织数据，表与表之间通过外键关联，数据高度结构化，支持SQL
-- 非关系型：键值/文档/列族/图等多种模型，数据结构灵活，扩展性强

-- 【原理】
-- 关系型：ACID强一致性，适合银行、订单等需要精确数据的场景
-- 非关系型：最终一致性优先，适合大数据、高并发、灵活Schema的场景

-- 【示例】
DROP DATABASE IF EXISTS rdbms_vs_nosql;
CREATE DATABASE rdbms_vs_nosql;

USE rdbms_vs_nosql;

-- 关系型：结构化表，通过外键建立关系
CREATE TABLE t_department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
CREATE TABLE t_employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES t_department(dept_id)
);
INSERT INTO t_department VALUES (1, 'IT'), (2, 'HR');
INSERT INTO t_employee VALUES (1, 'Alice', 1), (2, 'Bob', 1), (3, 'Carol', 2);

-- 通过JOIN关联查询，体现"关系"二字
SELECT e.emp_name, d.dept_name
FROM t_employee e
INNER JOIN t_department d ON e.dept_id = d.dept_id;

-- 关系型的特点：
-- 1. 数据以行列形式存储，每列有固定类型
-- 2. 表之间通过外键形成关系
-- 3. 支持复杂的多表关联查询
-- 4. 事务保证ACID

-- ================================================================
-- Q3: SQL到底是什么？它用来做什么？

-- 【解答】
-- SQL（Structured Query Language）是用于操作关系型数据库的标准编程语言。
-- 可以实现：数据查询、数据定义、数据操纵、数据控制

-- 【原理】
-- SQL不是程序设计语言，而是声明式语言——你告诉数据库"要什么"，不必写"怎么找"。
-- 类似自然语言：SELECT name FROM users WHERE age > 18;

-- 【示例】
DROP DATABASE IF EXISTS sql_demo;
CREATE DATABASE sql_demo;

USE sql_demo;

CREATE TABLE t_products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    stock INT,
    category VARCHAR(50)
);
INSERT INTO t_products (product_name, price, stock, category) VALUES
    ('iPhone', 6999.00, 100, 'Electronics'),
    ('MacBook Pro', 12999.00, 50, 'Electronics'),
    ('Desk Chair', 599.00, 200, 'Furniture'),
    ('Standing Desk', 1299.00, 80, 'Furniture'),
    ('Wireless Mouse', 129.00, 500, 'Electronics');

-- 查询：SELECT ... FROM ... WHERE ...
SELECT product_name, price FROM t_products WHERE category = 'Electronics' AND price < 5000;

-- 统计：聚合函数
SELECT category, COUNT(*) AS product_count, AVG(price) AS avg_price
FROM t_products GROUP BY category;

-- ================================================================
-- Q4: 主键（Primary Key）和外键（Foreign Key）分别是什么？有什么作用？

-- 【解答】
-- 主键：唯一标识表中每一条记录的一列或多列，不允许重复和空值
-- 外键：引用另一张表的主键，用于建立表与表之间的关联关系

-- 【原理】
-- 主键 → 确保记录唯一性，作为表的"身份证号"
-- 外键 → 确保引用完整性，防止创建孤立的引用记录

-- 【示例】
DROP DATABASE IF EXISTS pk_fk_demo;
CREATE DATABASE pk_fk_demo;

USE pk_fk_demo;

-- 班级表：dept_id是主键
CREATE TABLE t_department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

-- 学生表：emp_id是主键，dept_id是外键，引用t_department的dept_id
CREATE TABLE t_student (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES t_department(dept_id)
);

INSERT INTO t_department VALUES (1, 'Computer Science'), (2, 'Mathematics');
INSERT INTO t_student VALUES (1, 'Alice', 1), (2, 'Bob', 1), (3, 'Carol', 2);

-- 主键作用：student_id 唯一标识每个学生，无法插入重复ID
-- 外键作用：dept_id 只能引用 t_department 中存在的 dept_id，无法指向不存在的班级
-- 下面的INSERT会失败，因为 dept_id = 99 不存在
-- INSERT INTO t_student VALUES (4, 'David', 99);  -- Error: foreign key constraint

-- ================================================================
-- Q5: 数据库设计的三大范式（1NF/2NF/3NF）分别是什么意思？

-- 【解答】
-- 1NF：每个字段都是不可分的原子值（不可再拆分）
-- 2NF：在满足1NF的基础上，非主键字段完全依赖于主键（不能部分依赖）
-- 3NF：在满足2NF的基础上，非主键字段只依赖于主键，不传递依赖

-- 【原理】
-- 范式是为了消除数据冗余、避免更新异常。
-- 范式化程度越高，数据越零散（可能影响查询性能），需要权衡。

-- 【示例】
DROP DATABASE IF EXISTS normalization_demo;
CREATE DATABASE normalization_demo;

USE normalization_demo;

-- 违反1NF的表：address字段可拆分
-- CREATE TABLE t_bad1 (
--     id INT PRIMARY KEY,
--     name VARCHAR(50),
--     address VARCHAR(200)  -- "省-市-区" 可拆分，违反1NF
-- );

-- 满足1NF的设计
CREATE TABLE t_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    province VARCHAR(50),
    city VARCHAR(50),
    district VARCHAR(50)
);
INSERT INTO t_customer VALUES (1, 'Alice', 'Guangdong', 'Shenzhen', 'Nanshan');

-- 违反2NF的表：(student_id, course_id)是联合主键，teacher_name只依赖于course_id（部分依赖）
-- CREATE TABLE t_bad2 (
--     student_id INT,
--     course_id INT,
--     teacher_name VARCHAR(50),  -- 只依赖course_id，违反2NF
--     PRIMARY KEY (student_id, course_id)
-- );

-- 满足2NF：拆分为两张表
CREATE TABLE t_course (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50),
    teacher_name VARCHAR(50)
);
CREATE TABLE t_student_course (
    student_id INT,
    course_id INT,
    PRIMARY KEY (student_id, course_id)
);

-- 违反3NF的表：student_id → class_id → class_name（class_name传递依赖于student_id）
-- CREATE TABLE t_bad3 (
--     student_id INT PRIMARY KEY,
--     class_id INT,
--     class_name VARCHAR(50)  -- 传递依赖class_id，违反3NF
-- );

-- 满足3NF：class_name应放在独立的班级表
CREATE TABLE t_class (
    class_id INT PRIMARY KEY,
    class_name VARCHAR(50)
);
CREATE TABLE t_student2 (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50),
    class_id INT
);

-- ================================================================
-- Q6: 什么是反范式？为什么有时候需要反范式设计？

-- 【解答】
-- 反范式是有意违反范式规则，通过冗余数据来提升查询性能。
-- 核心思想：用空间换时间

-- 【原理】
-- 范式化：更新快，查询需多次JOIN
-- 反范式：查询快（数据在同一表），更新需同步多处
-- 场景：大数据报表、高频读取的系统，需要减少JOIN提升性能

-- 【示例】
DROP DATABASE IF EXISTS denormalization_demo;
CREATE DATABASE denormalization_demo;

USE denormalization_demo;

-- 范式化设计：订单表只存user_id，用户信息在用户表
CREATE TABLE t_user_norm (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(50)
);
CREATE TABLE t_order_norm (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_amount DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES t_user_norm(user_id)
);

-- 反范式化设计：订单表冗余存储user_name，避免JOIN查询
CREATE TABLE t_order_denorm (
    order_id INT PRIMARY KEY,
    user_id INT,
    user_name VARCHAR(50),         -- 冗余字段：避免JOIN
    order_amount DECIMAL(10,2)
);

INSERT INTO t_user_norm VALUES (1, 'Alice');
INSERT INTO t_order_norm VALUES (1, 1, 299.00);
INSERT INTO t_order_denorm VALUES (1, 1, 'Alice', 299.00);

-- 查询用户订单：范式化需要JOIN，反范式直接查
-- 范式查询（需JOIN）：
SELECT u.user_name, o.order_amount
FROM t_user_norm u INNER JOIN t_order_norm o ON u.user_id = o.user_id;

-- 反范式查询（无需JOIN）：
SELECT user_name, order_amount FROM t_order_denorm;

-- ================================================================
-- Q7: 常见的关系型数据库有哪些？MySQL有什么特点？

-- 【解答】
-- 关系型数据库：Oracle（商业，功能最强）、MySQL（开源，轻量）、PostgreSQL（开源，功能丰富）、
--              SQL Server（微软）、SQLite（嵌入式）、DB2（IBM）

-- 【原理】
-- MySQL特点：
-- 1. 开源免费，社区活跃
-- 2. 轻量级，安装配置简单
-- 3. 支持多种存储引擎（InnoDB/MyISAM/MEMORY等）
-- 4. 默认存储引擎InnoDB支持事务和行级锁
-- 5. 适合Web应用，是LAMP架构的核心组件

-- 【示例】
SHOW ENGINES;  -- 查看MySQL支持的存储引擎

-- MySQL默认使用InnoDB引擎，具备以下特性：
-- 1. 支持事务（ACID）
-- 2. 支持行级锁
-- 3. 支持外键
-- 4. 支持MVCC
-- 5. 崩溃恢复

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 创建两个表：t_department（dept_id INT主键, dept_name VARCHAR(50)）和
--    t_employee（emp_id INT主键, emp_name VARCHAR(50), dept_id INT外键），
--    并插入测试数据，然后通过JOIN查询显示每个员工所属的部门名称。

-- 2. 设计一个满足3NF的学生选课数据库：包含学生表、课程表、选课表（成绩），
--    说明每张表的字段和主键/外键关系。

-- 3. 写一条SQL查询，证明"SELECT的别名不能在WHERE中使用"：
--    分别展示（a）用别名排序成功；（b）用别名在WHERE中过滤报错的现象。

-- 4. 创建一个反范式设计的例子：在订单表t_order中冗余存储customer_name，
--    避免每次查询订单时都要JOIN客户表。对比范式化和反范式的查询写法。

-- 5. 查询INFORMATION_SCHEMA，列出当前MySQL服务器中所有数据库的名称和默认字符集。
