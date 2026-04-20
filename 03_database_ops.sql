-- ================================================================
-- 模块三：数据库操作
-- ================================================================

-- Q1: 如何创建、切换、删除数据库？

-- 【解答】
-- CREATE DATABASE：创建数据库
-- USE：切换当前数据库
-- DROP DATABASE：删除数据库（危险！所有数据永久丢失）

-- 【原理】
-- 数据库是最大级别的命名空间，用于隔离不同项目的数据。
-- 创建时可指定字符集和排序规则，不指定则使用MySQL默认配置。
-- MySQL默认字符集通常是 latin1，建议创建时显式指定 utf8mb4。

-- 【示例】
-- 创建数据库（指定字符集和排序规则）
CREATE DATABASE IF NOT EXISTS shop_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- 切换数据库
USE shop_db;

-- 在当前数据库中创建表
CREATE TABLE t_product (
    id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- 删除数据库（所有表和数据永久删除）
DROP DATABASE IF EXISTS shop_db;

-- ================================================================
-- Q2: 字符集（CHARACTER SET）和排序规则（COLLATION）是什么？

-- 【解答】
-- 字符集：规定了数据库能存储哪些字符（文字、符号）
-- 排序规则：规定了字符之间的比较和排序规则（是否区分大小写、重音符号等）

-- 【原理】
-- 常见字符集：
-- latin1：西欧字符，不支持中文
-- gbk：简体中文
-- utf8：变长UTF-8（MySQL早期实现，最多3字节，不含某些emoji）
-- utf8mb4：完整的UTF-8（MySQL 5.5.3+，推荐，支持所有Unicode字符含emoji）

-- 常见排序规则（以utf8mb4为例）：
-- utf8mb4_general_ci：通用排序，不区分大小写，性能优先
-- utf8mb4_unicode_ci：Unicode排序，精确度更高（基于标准Unicode算法）
-- utf8mb4_bin：按字节二进制比较，区分大小写

-- 【示例】
DROP DATABASE IF EXISTS charset_demo;
CREATE DATABASE charset_demo
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE charset_demo;

CREATE TABLE t_text_test (
    id INT PRIMARY KEY,
    content VARCHAR(100)
);

INSERT INTO t_text_test VALUES (1, 'Apple');
INSERT INTO t_text_test VALUES (2, 'apple');
INSERT INTO t_text_test VALUES (3, 'APPLE');

-- 排序规则影响查询（不区分大小写）
SELECT * FROM t_text_test WHERE content = 'apple';
-- 如果用 utf8mb4_bin，会找到3条；如果用 utf8mb4_general_ci，会找到1条（'APPLE'不匹配）

-- 排序规则影响排序结果
SELECT content FROM t_text_test ORDER BY content;
-- utf8mb4_unicode_ci: Apple, apple, APPLE（通常按字典序）
-- utf8mb4_bin: APPLE, Apple, apple（按ASCII码排序）

-- 演示区分大小写
CREATE TABLE t_case_test (
    id INT PRIMARY KEY,
    name VARCHAR(50) COLLATE utf8mb4_bin
);
INSERT INTO t_case_test VALUES (1, 'abc'), (2, 'ABC'), (3, 'Abc');

SELECT * FROM t_case_test WHERE name = 'abc';  -- 只返回 'abc'（二进制比较）
SELECT * FROM t_case_test WHERE name = 'ABC';  -- 只返回 'ABC'

-- ================================================================
-- Q3: 如何查看数据库的属性（字符集、排序规则、大小等）？

-- 【解答】
-- SHOW DATABASES：列出所有数据库
-- SHOW CREATE DATABASE：查看创建语句（含字符集）
-- SHOW TABLE STATUS：查看表信息
-- INFORMATION_SCHEMA：系统数据库，存储元数据

-- 【原理】
-- INFORMATION_SCHEMA是MySQL的系统数据库，保存了所有数据库/表/列的元数据。
-- 通过查询INFORMATION_SCHEMA可以获取数据库结构信息，而不需要SHOW命令。

-- 【示例】
SHOW DATABASES;

-- 查看某个数据库的创建信息
SHOW CREATE DATABASE mysql;

-- 查看当前数据库所有表
SHOW TABLES;

-- 查看某个表的创建语句（含字符集信息）
SHOW CREATE TABLE mysql.user;

-- 查看表结构（DESCRIBE）
DESC mysql.user;

-- 通过INFORMATION_SCHEMA查询数据库信息
SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME
FROM INFORMATION_SCHEMA.SCHEMATA;

-- 查看某个数据库中所有表的字符集
SELECT TABLE_NAME, TABLE_COLLATION
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'mysql';

-- 查看某个表的列信息
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_SET_NAME, COLLATION_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'mysql' AND TABLE_NAME = 'user'
LIMIT 10;

-- ================================================================
-- Q4: MySQL的存储引擎是什么？InnoDB和MyISAM有什么区别？

-- 【解答】
-- 存储引擎：数据库管理数据存储和读取的底层组件
-- InnoDB：MySQL 5.5+默认引擎，支持事务、行级锁、外键、崩溃恢复
-- MyISAM：早期默认引擎，不支持事务，表级锁，读取性能好

-- 【原理】
-- InnoDB vs MyISAM核心区别：
-- | 特性         | InnoDB          | MyISAM          |
-- |-------------|----------------|-----------------|
-- | 事务        | 支持            | 不支持           |
-- | 锁级别       | 行级锁          | 表级锁           |
-- | 外键        | 支持            | 不支持           |
-- | 全文索引     | 5.6+支持        | 支持             |
-- | 存储空间     | 约2倍           | 约1倍            |
-- | 崩溃恢复     | 自动恢复        | 需手动修复        |
-- | 适用场景     | 写多/并发/事务   | 读多/静态/日志    |

-- 【示例】
SHOW ENGINES;

-- 创建InnoDB表（默认）
CREATE TABLE t_innodb (
    id INT PRIMARY KEY,
    name VARCHAR(50)
) ENGINE = InnoDB;

-- 创建MyISAM表
CREATE TABLE t_myisam (
    id INT PRIMARY KEY,
    name VARCHAR(50)
) ENGINE = MyISAM;

-- 插入相同数据
INSERT INTO t_innodb VALUES (1, 'Alice'), (2, 'Bob');
INSERT INTO t_myisam VALUES (1, 'Alice'), (2, 'Bob');

-- 查看存储引擎
SHOW TABLE STATUS FROM mysql LIKE 'user';

-- ================================================================
-- Q5: 如何复制或重命名数据库？

-- 【解答】
-- MySQL没有直接命令复制整个数据库，需要手动操作：
-- 1. mysqldump导出 → mysql导入
-- 2. 或者逐个导出表再导入

-- 【原理】
-- CREATE DATABASE xxx SELECT ... 不支持（MySQL禁止跨库SELECT INTO）
-- 正确方式是使用 mysqldump 工具导出SQL脚本，再导入到新数据库

-- 【示例】
-- 场景：复制 shop_db 到 shop_db_backup
-- 步骤1：使用mysqldump导出（命令行执行）
-- mysqldump -u root -p shop_db > shop_db_backup.sql

-- 步骤2：创建新数据库
-- CREATE DATABASE shop_db_backup;

-- 步骤3：导入数据
-- mysql -u root -p shop_db_backup < shop_db_backup.sql

-- 重命名数据库（MySQL 5.1.7后已移除此功能）
-- 正确做法：导出 → 删除 → 重建 → 导入

-- 或者使用RENAME TABLE（在同一个数据库内重命名表）
USE shop_db;
CREATE TABLE t_test_rename (id INT);
RENAME TABLE t_test_rename TO t_renamed;

SHOW TABLES;

-- ================================================================
-- Q6: 什么是数据库的"默认数据库"？USE和完全限定名有什么区别？

-- 【解答】
-- "默认数据库"：USE选择后，当前会话的默认数据库，后续操作默认在该数据库中执行
-- 完全限定名：database_name.table_name.column_name，明确指定数据库

-- 【原理】
-- USE db_name：设置当前会话的默认数据库
-- 完全限定名可以跨库操作，不依赖USE的设置
-- 跨库查询必须使用完全限定名：SELECT * FROM other_db.t_table

-- 【示例】
DROP DATABASE IF EXISTS db1;
DROP DATABASE IF EXISTS db2;
CREATE DATABASE db1;
CREATE DATABASE db2;

USE db1;
CREATE TABLE t_user (id INT PRIMARY KEY, name VARCHAR(50));
INSERT INTO t_user VALUES (1, 'Alice');

USE db2;
CREATE TABLE t_order (id INT PRIMARY KEY, amount DECIMAL(10,2));
INSERT INTO t_order VALUES (1, 299.00);

-- 切换到db1后，以下两种查询等价：
USE db1;
SELECT * FROM t_user;                   -- 默认在db1中查找
SELECT * FROM db1.t_user;               -- 完全限定名

-- 跨库查询（必须使用完全限定名）
SELECT u.name, o.amount
FROM db1.t_user u
INNER JOIN db2.t_order o ON u.id = 1;

-- 即使在db2中，引用db1的表仍需完全限定名
USE db2;
SELECT * FROM db1.t_user;

-- ================================================================
-- Q7: MySQL的配置文件my.cnf（或my.ini）在哪里？常用配置项有哪些？

-- 【解答】
-- Windows：my.ini（一般在安装目录或C:\ProgramData\MySQL）
-- Linux/Mac：my.cnf（在/etc/my.cnf或/usr/local/mysql/my.cnf）
-- 常用配置项：character-set-server、default-storage-engine、max_connections等

-- 【原理】
-- MySQL配置文件控制服务器启动参数，不修改配置文件也可以通过SET GLOBAL动态调整（需重启才永久生效）。
-- 修改配置文件后需要重启MySQL服务使配置生效。

-- 【示例】
-- 查看当前字符集配置
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'collation%';

-- 查看默认存储引擎
SHOW VARIABLES LIKE 'default_storage_engine';

-- 查看最大连接数
SHOW VARIABLES LIKE 'max_connections';

-- 动态修改（当前会话生效）
SET NAMES utf8mb4;  -- 设置客户端字符集

-- 动态修改（需super权限，重启后失效）
SET GLOBAL max_connections = 500;

-- ================================================================
-- Q8: DROP DATABASE、TRUNCATE TABLE、DROP TABLE三者的区别是什么？

-- 【解答】
-- DROP DATABASE：删除整个数据库（所有表、所有数据永久丢失）
-- TRUNCATE TABLE：清空表中所有数据（保留表结构，速度快，不可回滚）
-- DROP TABLE：删除整个表（表结构和数据全部删除，不可恢复）

-- 【原理】
-- 危险程度：DROP DATABASE > DROP TABLE > TRUNCATE TABLE > DELETE
-- TRUNCATE是DDL（自动提交），DELETE是DML（可回滚）
-- TRUNCATE重置AUTO_INCREMENT计数器，DELETE不会

-- 【示例】
DROP DATABASE IF EXISTS danger_demo;
CREATE DATABASE danger_demo;
USE danger_demo;

CREATE TABLE t_del_test (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50)
);
INSERT INTO t_del_test (name) VALUES ('A'), ('B'), ('C');
SELECT * FROM t_del_test;  -- 3条，AUTO_INCREMENT=3

-- DELETE：可回滚，会重置AUTO_INCREMENT吗？不，保留计数器
START TRANSACTION;
DELETE FROM t_del_test;
ROLLBACK;
SELECT * FROM t_del_test;  -- 数据恢复，但AUTO_INCREMENT仍为3
SELECT MAX(id) FROM t_del_test;  -- 3

-- TRUNCATE：不可回滚，重置AUTO_INCREMENT
TRUNCATE TABLE t_del_test;
INSERT INTO t_del_test (name) VALUES ('X');
SELECT * FROM t_del_test;  -- 1条（AUTO_INCREMENT重置为1）

-- DROP TABLE：删除表结构
DROP TABLE t_del_test;
-- 表不存在了，所有数据永久丢失
