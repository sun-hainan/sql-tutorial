-- ================================================================
-- 模块六：六大约束
-- ================================================================

-- Q1: 主键约束（PRIMARY KEY）是什么？有哪几种类型？

-- 【解答】
-- PRIMARY KEY：唯一标识表中每条记录的一列或多列，不允许重复和NULL
-- 单列主键：一列作为主键
-- 联合主键：多列组合作为主键，确保组合唯一

-- 【原理】
-- 一张表只能有一个PRIMARY KEY约束。
-- 主键自动创建唯一索引（UNIQUE INDEX）。
-- InnoDB表中，主键就是聚簇索引，数据行按主键排序存储。
-- 建议使用自增INT作为主键（查询快、占用空间小、插入快）。

-- 【示例】
DROP DATABASE IF EXISTS constraints_demo;
CREATE DATABASE constraints_demo;
USE constraints_demo;

-- 单列主键
CREATE TABLE t_user_single_pk (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100)
);
INSERT INTO t_user_single_pk VALUES (1, 'alice', 'alice@example.com');
-- 重复主键会报错
-- INSERT INTO t_user_single_pk VALUES (1, 'bob', 'bob@example.com');  -- Error: Duplicate entry
-- NULL主键会报错
-- INSERT INTO t_user_single_pk VALUES (NULL, 'charlie', 'charlie@example.com');  -- Error

-- 自增主键（AUTO_INCREMENT，需要配合PRIMARY KEY或UNIQUE约束）
CREATE TABLE t_order (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50),
    amount DECIMAL(10,2)
);
INSERT INTO t_order (customer_name, amount) VALUES ('Alice', 299.00);
INSERT INTO t_order (customer_name, amount) VALUES ('Bob', 599.00);
SELECT * FROM t_order;  -- order_id自动为1,2,3...

-- 联合主键（复合主键）
CREATE TABLE t_enrollment (
    student_id INT,
    course_id INT,
    enroll_date DATE,
    grade DECIMAL(4,1),
    PRIMARY KEY (student_id, course_id)  -- 联合主键：student_id+course_id组合唯一
);
INSERT INTO t_enrollment VALUES (1, 101, '2024-01-01', 85.5);
INSERT INTO t_enrollment VALUES (1, 102, '2024-01-02', 90.0);
INSERT INTO t_enrollment VALUES (2, 101, '2024-01-01', 78.0);
-- 同一学生不能重复选修同一课程
-- INSERT INTO t_enrollment VALUES (1, 101, '2024-02-01', 88.0);  -- Error: Duplicate entry

-- ================================================================
-- Q2: 唯一约束（UNIQUE）和主键约束有什么区别？

-- 【解答】
-- 主键：每表只能一个，不允许NULL，自动创建聚簇索引
-- 唯一约束：每表可以有多个，允许单个NULL（多个NULL也不违反唯一性）

-- 【原理】
-- 主键和唯一约束都会创建唯一索引，但：
-- 1. 主键用于标识记录，唯一约束用于确保某列值不重复
-- 2. 主键不允许NULL，唯一约束允许NULL
-- 3. InnoDB中，主键是聚簇索引，数据按主键排序存储；唯一约束是辅助索引
-- 4. 主键通常用INT自增，唯一约束可以是VARCHAR等

-- 【示例】
USE constraints_demo;

-- 主键约束
CREATE TABLE t_employee (
    emp_id INT PRIMARY KEY,           -- 主键：唯一且非空
    emp_code VARCHAR(20) UNIQUE,      -- 唯一约束：工号唯一
    emp_name VARCHAR(50)
);
INSERT INTO t_employee VALUES (1, 'E001', 'Alice');
INSERT INTO t_employee VALUES (2, 'E002', 'Bob');
-- emp_id重复报错，emp_code重复也报错
-- INSERT INTO t_employee VALUES (1, 'E003', 'Carol');  -- Error: Duplicate entry
-- INSERT INTO t_employee VALUES (3, 'E001', 'Carol');  -- Error: Duplicate entry

-- NULL的情况
CREATE TABLE t_unique_null (
    id INT PRIMARY KEY,
    code VARCHAR(20) UNIQUE
);
INSERT INTO t_unique_null VALUES (1, NULL);     -- OK
INSERT INTO t_unique_null VALUES (2, NULL);     -- OK：多个NULL互不冲突（SQL标准）
-- 注意：某些数据库实现可能只允许一个NULL，需确认MySQL版本

SELECT * FROM t_unique_null;  -- 两条记录，code都是NULL

-- ================================================================
-- Q3: 非空约束（NOT NULL）和检查约束（CHECK）是什么？

-- 【解答】
-- NOT NULL：字段值不能为NULL
-- CHECK：MySQL 8.0.16+支持，限制字段值必须满足条件（之前版本忽略但不报错）

-- 【原理】
-- NOT NULL：强制字段必须有值，不提供值时会报错（除非有DEFAULT）
-- CHECK：在MySQL 8.0.16之前被忽略（不报错但不强制），8.0.16+正式支持
-- 约束是数据完整性的第一道防线，在数据库层面强制比应用层更安全

-- 【示例】
USE constraints_demo;

-- NOT NULL约束
CREATE TABLE t_member (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,    -- 必须提供用户名
    email VARCHAR(100) NOT NULL,      -- 必须提供邮箱
    phone VARCHAR(20) NULL,            -- 可选填
    age INT                           -- 可选，默认NULL
);
INSERT INTO t_member (username, email, phone, age) VALUES ('alice', 'alice@example.com', '13800138000', 25);
INSERT INTO t_member (username, email) VALUES ('bob', 'bob@example.com');  -- phone和age可省略
-- INSERT INTO t_member (username) VALUES ('charlie');  -- Error: email cannot be NULL

-- CHECK约束（MySQL 8.0.16+）
CREATE TABLE t_product_check (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),           -- 价格必须大于0
    quantity INT NOT NULL CHECK (quantity >= 0),               -- 数量非负
    rating DECIMAL(2,1) CHECK (rating >= 1.0 AND rating <= 5.0) -- 评分1-5
);
INSERT INTO t_product_check (name, price, quantity, rating) VALUES ('Laptop', 5000.00, 10, 4.5);
-- INSERT INTO t_product_check (name, price, quantity, rating) VALUES ('Book', -10.00, 5, 4.0);  -- Error: CHECK violation

-- CHECK约束也可以命名，便于维护
CREATE TABLE t_order_check (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    total_amount DECIMAL(10,2),
    paid_amount DECIMAL(10,2),
    CONSTRAINT chk_paid_positive CHECK (paid_amount >= 0),
    CONSTRAINT chk_paid_not_exceed CHECK (paid_amount <= total_amount)
);
INSERT INTO t_order_check (customer_id, total_amount, paid_amount) VALUES (1, 1000.00, 500.00);
-- INSERT INTO t_order_check VALUES (2, 1000.00, 1200.00);  -- Error: paid_amount > total_amount

-- ================================================================
-- Q4: 默认值约束（DEFAULT）的特点和使用场景？

-- 【解答】
-- DEFAULT：为字段设置默认值，INSERT时不提供该字段时自动使用
-- 常用于：状态标志、时间戳、数字默认值、字符串默认值

-- 【原理】
-- DEFAULT可以使用常量或表达式（MySQL 5.7+支持函数作为默认值）
-- AUTO_INCREMENT的默认是下一个序列值
-- TIMESTAMP的默认值是CURRENT_TIMESTAMP
-- 如果字段允许NULL且未指定DEFAULT，默认是NULL

-- 【示例】
USE constraints_demo;

CREATE TABLE t_post (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    author_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'draft',           -- 默认'草稿'状态
    views INT DEFAULT 0,                          -- 默认0浏览量
    is_deleted TINYINT DEFAULT 0,                 -- 默认未删除
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO t_post (title, content, author_id) VALUES ('My First Post', 'Hello world', 1);

SELECT * FROM t_post;
-- status='draft', views=0, is_deleted=0, created_at=当前时间

-- 多条插入，部分字段使用默认值
INSERT INTO t_post (title, content, author_id, status) VALUES
    ('Second Post', 'Content here', 1, 'published'),
    ('Third Post', 'Another content', 2, DEFAULT);  -- 使用默认值'draft'

SELECT id, title, status, views FROM t_post;

-- DEFAULT值可以是表达式
CREATE TABLE t_invoice (
    id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_no VARCHAR(50) DEFAULT (CONCAT('INV', YEAR(NOW()), LPAD(id, 6, '0'))),
    amount DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO t_invoice (amount) VALUES (1000.00);
SELECT * FROM t_invoice;  -- invoice_no 自动生成

-- ================================================================
-- Q5: 外键约束（FOREIGN KEY）的作用和工作原理？

-- 【解答】
-- 外键：引用另一张表的主键，确保引用完整性
-- 作用：防止创建孤立的子记录，防止父记录被删除时留下脏数据

-- 【原理】
-- 子表的外键列的值必须在父表的主键中存在（或为NULL）
-- 定义外键时指定ON DELETE/UPDATE行为：
--   CASCADE：级联删除/更新
--   SET NULL：设为NULL
--   RESTRICT：拒绝删除/更新父记录
--   NO ACTION：同RESTRICT（检查延迟）

-- 【示例】
USE constraints_demo;

-- 父表：部门
CREATE TABLE t_dept (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(50) NOT NULL
);

-- 子表：员工（通过外键关联部门）
CREATE TABLE t_emp (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES t_dept(dept_id)
        ON DELETE SET NULL        -- 部门删除时，员工dept_id设为NULL
        ON UPDATE CASCADE         -- 部门ID更新时，员工dept_id同步更新
);

INSERT INTO t_dept VALUES (1, 'IT'), (2, 'HR');
INSERT INTO t_emp VALUES (1, 'Alice', 1), (2, 'Bob', 1), (3, 'Carol', 2);

-- 外键约束验证
-- INSERT INTO t_emp VALUES (4, 'David', 99);  -- Error: dept_id=99不存在

-- CASCADE删除演示
DELETE FROM t_dept WHERE dept_id = 2;  -- Carol的dept_id会被设为NULL
SELECT * FROM t_emp;  -- Carol的dept_id=NULL

-- UPDATE CASCADE演示
UPDATE t_dept SET dept_id = 100 WHERE dept_id = 1;  -- IT部门的ID变成100
SELECT * FROM t_emp;  -- Alice和Bob的dept_id都变成100

-- ================================================================
-- Q6: 外键约束的ON DELETE和ON UPDATE有哪些选项？

-- 【解答】
-- ON DELETE：父记录删除时的行为
-- ON UPDATE：父记录更新时的行为
-- 选项：CASCADE / SET NULL / RESTRICT / NO ACTION

-- 【原理】
-- CASCADE：子记录随父记录一起删除/更新（最常用，保持引用完整性）
-- SET NULL：子记录的外键设为NULL（允许子记录独立存在）
-- RESTRICT：如果有子记录，拒绝删除/更新父记录（立即检查）
-- NO ACTION：如果有子记录，拒绝删除/更新父记录（延迟检查，MySQL中等效于RESTRICT）

-- 【示例】
USE constraints_demo;

-- 父表
CREATE TABLE t_parent (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

-- 子表1：CASCADE
CREATE TABLE t_child_cascade (
    id INT PRIMARY KEY AUTO_INCREMENT,
    parent_id INT,
    data VARCHAR(50),
    FOREIGN KEY (parent_id) REFERENCES t_parent(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 子表2：SET NULL
CREATE TABLE t_child_setnull (
    id INT PRIMARY KEY AUTO_INCREMENT,
    parent_id INT,
    data VARCHAR(50),
    FOREIGN KEY (parent_id) REFERENCES t_parent(id) ON DELETE SET NULL ON UPDATE SET NULL
);

-- 子表3：RESTRICT
CREATE TABLE t_child_restrict (
    id INT PRIMARY KEY AUTO_INCREMENT,
    parent_id INT,
    data VARCHAR(50),
    FOREIGN KEY (parent_id) REFERENCES t_parent(id) ON DELETE RESTRICT ON UPDATE RESTRICT
);

INSERT INTO t_parent VALUES (1, 'Parent1'), (2, 'Parent2');
INSERT INTO t_child_cascade VALUES (1, 1, 'C1');
INSERT INTO t_child_setnull VALUES (1, 1, 'S1');
INSERT INTO t_child_restrict VALUES (1, 1, 'R1');

-- CASCADE：删除父记录1，子记录也被删除
DELETE FROM t_parent WHERE id = 1;
SELECT * FROM t_child_cascade;  -- 空，级联删除

-- SET NULL：删除父记录2的引用，子记录被设为NULL
DELETE FROM t_parent WHERE id = 2;
SELECT * FROM t_child_setnull;  -- parent_id=NULL

-- RESTRICT：阻止删除有子记录的父记录
-- DELETE FROM t_parent WHERE id = 1;  -- Error: Cannot delete or update parent row

-- ================================================================
-- Q7: 如何查看表中的约束和索引信息？

-- 【解答】
-- SHOW CREATE TABLE：显示建表语句（含所有约束）
-- SHOW INDEX FROM：显示表上的索引
-- SHOW TABLE STATUS：显示表状态
-- INFORMATION_SCHEMA：存储了所有数据库的元数据

-- 【原理】
-- 约束和索引在底层是相关的：PRIMARY KEY/UNIQUE会自动创建索引。
-- 通过INFORMATION_SCHEMA可以获取完整的约束和索引信息。

-- 【示例】
USE constraints_demo;

CREATE TABLE t_constraint_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    dept_id INT,
    age INT CHECK (age >= 0 AND age <= 150),
    CONSTRAINT fk_dept FOREIGN KEY (dept_id) REFERENCES t_dept(id),
    CONSTRAINT uk_code_name UNIQUE (code, name)
);

-- 方法1：SHOW CREATE TABLE
SHOW CREATE TABLE t_constraint_demo;

-- 方法2：SHOW INDEX
SHOW INDEX FROM t_constraint_demo;
-- Non_unique=0 表示唯一索引，Key_name=PRIMARY 主键索引

-- 方法3：INFORMATION_SCHEMA查询
SELECT
    CONSTRAINT_NAME,
    TABLE_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'constraints_demo' AND TABLE_NAME = 't_constraint_demo';

SELECT
    INDEX_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'constraints_demo' AND TABLE_NAME = 't_constraint_demo';
