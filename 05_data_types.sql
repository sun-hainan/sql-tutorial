-- ================================================================
-- 模块五：数据类型
-- ================================================================

-- Q1: 数值类型有哪些？各类型的取值范围和存储大小是多少？

-- 【解答】
-- 整数：TINYINT(1B) / SMALLINT(2B) / MEDIUMINT(3B) / INT(4B) / BIGINT(8B)
-- 浮点：FLOAT(4B) / DOUBLE(8B) / DECIMAL(M,D)
-- BIT：位字段类型

-- 【原理】
-- 整数类型如果不指定UNSIGNED，默认是有符号（负数）。
-- DECIMAL是精确小数，FLOAT/DOUBLE是近似值。
-- DECIMAL(M,D)：M=总位数（不含小数点），D=小数位数。M最大65，D最大30。

-- 【示例】
DROP DATABASE IF EXISTS data_types_demo;
CREATE DATABASE data_types_demo;
USE data_types_demo;

CREATE TABLE t_numeric_types (
    -- 有符号整数
    col_tinyint_signed TINYINT,
    col_smallint SIGNED,
    col_mediumint MEDIUMINT,
    col_int INT,
    col_bigint BIGINT,

    -- 无符号整数（只有正数）
    col_unsigned TINYINT UNSIGNED,
    col_positive SMALLINT UNSIGNED,

    -- 浮点类型
    col_float FLOAT,
    col_double DOUBLE,
    col_decimal DECIMAL(10,2),     -- 最多10位数字，2位小数
    col_decimal2 DECIMAL(5,3),     -- 最多5位数字，3位小数

    -- BIT类型（位字段）
    col_bit BIT(8)
);

INSERT INTO t_numeric_types VALUES (
    127,                    -- tinyint signed max
    32767,                  -- smallint max
    8388607,                -- mediumint max
    2147483647,             -- int max
    9223372036854775807,    -- bigint max
    255,                    -- tinyint unsigned max
    65535,                  -- smallint unsigned max
    3.14159265358979,       -- float（近似值）
    3.14159265358979,       -- double（近似值）
    12345678.90,            -- decimal(10,2)
    123.456,                -- decimal(5,3)
    255                      -- bit(8) 存一个字节
);

SELECT
    col_tinyint_signed AS tinyint_signed,
    col_unsigned AS tinyint_unsigned,
    col_decimal,
    col_decimal2,
    col_bit + 0 AS bit_as_int  -- BIT转数字显示
FROM t_numeric_types;

-- 验证DECIMAL精确性（与FLOAT对比）
CREATE TABLE t_precision_test (
    id INT PRIMARY KEY,
    float_val FLOAT,
    decimal_val DECIMAL(10,10)
);
INSERT INTO t_precision_test VALUES (1, 0.1234567890, 0.1234567890);
SELECT * FROM t_precision_test;
-- float_val 显示近似值，decimal_val 显示精确值

-- ================================================================
-- Q2: 字符串类型（CHAR、VARCHAR、TEXT）的特点和选择原则？

-- 【解答】
-- CHAR(n)：固定长度，不足用空格填充，n最大255
-- VARCHAR(n)：可变长度，实际占用=数据长度+1~2字节，n最大65535（字符数因编码而异）
-- TEXT：用于大文本，最大65535字节（TINYTEXT/TEXT/MEDIUMTEXT/LONGTEXT）

-- 【原理】
-- CHAR vs VARCHAR的选择：
-- 长度固定（如性别、国籍、邮编、MD5哈希值）→ CHAR
-- 长度变化（如姓名、地址、描述）→ VARCHAR
-- VARCHAR会额外用1-2字节存储长度，所以短字符串CHAR更省空间

-- TEXT vs VARCHAR：
-- TEXT不能有默认值，不能作为主键，不能建完整索引（InnoDB）
-- VARCHAR可以通过BLOB存储大文本，但通常用TEXT
-- 一般描述用TEXT，JSON/XML用LONGTEXT

-- 【示例】
USE data_types_demo;

CREATE TABLE t_string_types (
    id INT PRIMARY KEY AUTO_INCREMENT,

    -- CHAR：固定长度
    country_code CHAR(3),           -- 3位国家码，如CHN、USA
    gender CHAR(1),                 -- M/F
    md5_hash CHAR(32),             -- MD5固定32字符

    -- VARCHAR：可变长度
    username VARCHAR(50),
    email VARCHAR(100),
    address VARCHAR(200),

    -- TEXT系列
    remark TEXT,                    -- 最多65535字节
    article MEDIUMTEXT,             -- 最多1.6千万字节
    big_content LONGTEXT            -- 最多4G字节
);

INSERT INTO t_string_types (country_code, gender, md5_hash, username, email, address, remark) VALUES
    ('CHN', 'F', 'd41d8cd98f00b204e9800998ecf8427e', 'alice', 'alice@example.com', 'Guangzhou', 'VIP customer');

-- CHAR vs VARCHAR 空间占用演示
CREATE TABLE t_char_varchar (
    id INT PRIMARY KEY,
    fixed CHAR(10),
    variable VARCHAR(10)
);
INSERT INTO t_char_varchar VALUES (1, 'AB', 'AB');
SELECT
    LENGTH(fixed) AS char_length,
    LENGTH(variable) AS varchar_length,
    OCTET_LENGTH(fixed) AS char_bytes,
    OCTET_LENGTH(variable) AS varchar_bytes
FROM t_char_varchar;
-- CHAR(10) 实际存10字节（不足用空格补），VARCHAR(10) 实际存3字节+长度前缀

-- ================================================================
-- Q3: 日期时间类型有哪些？DATE、TIME、DATETIME、TIMESTAMP的区别？

-- 【解答】
-- DATE：日期'2024-01-15'（3字节）
-- TIME：时间'12:30:45'（3字节）
-- YEAR：年份'2024'（1字节）
-- DATETIME：日期时间'2024-01-15 12:30:45'（8字节，无时区概念）
-- TIMESTAMP：时间戳（4字节，自动维护，支持时区）

-- 【原理】
-- DATETIME vs TIMESTAMP 核心区别：
-- 1. 存储方式：DATETIME存文本'YYYY-MM-DD HH:MM:SS'，TIMESTAMP存秒数
-- 2. 时区：DATETIME无时区概念，TIMESTAMP自动转UTC（跨时区时显示本地时间）
-- 3. 范围：DATETIME 1000-9999年，TIMESTAMP 1970-2038年
-- 4. 自动更新：TIMESTAMP默认CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- 5. 索引：TIMESTAMP更高效（整型比较 vs 字符串比较）

-- 【示例】
USE data_types_demo;

CREATE TABLE t_datetime_types (
    id INT PRIMARY KEY AUTO_INCREMENT,

    -- 日期
    birth_date DATE,

    -- 时间（可表示时间段，如'08:30:00'或'30 02:00:00'表示30天2小时）
    work_time TIME,
    duration TIME,                  -- 时间段

    -- 年份
    birth_year YEAR,

    -- DATETIME
    created_datetime DATETIME,

    -- TIMESTAMP（自动维护）
    updated_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO t_datetime_types
(birth_date, work_time, duration, birth_year, created_datetime)
VALUES
    ('1990-05-20', '09:00:00', '08:30:00', '1990', NOW());

SELECT * FROM t_datetime_types;

-- TIMESTAMP vs DATETIME 时区演示（需要不同会话）
CREATE TABLE t_timezone_test (
    id INT PRIMARY KEY,
    dt DATETIME,
    ts TIMESTAMP
);
INSERT INTO t_timezone_test VALUES (1, '2024-01-15 12:00:00', '2024-01-15 12:00:00');

-- 查看当前时区
SHOW VARIABLES LIKE 'time_zone';

-- 时区切换演示（MySQL中修改session时区）
-- SET time_zone = '+00:00';  -- UTC
-- SELECT * FROM t_timezone_test;  -- DATETIME显示12:00:00，TIMESTAMP会变

-- TIMESTAMP范围限制演示（超出范围会报错）
-- INSERT INTO t_datetime_types (created_datetime) VALUES ('1970-01-01 00:00:00');  -- TIMESTAMP不支持

-- ================================================================
-- Q4: DATETIME vs TIMESTAMP：为什么金额应该用DECIMAL而不是FLOAT？

-- 【解答】
-- 浮点数是近似存储，存在精度丢失问题。
-- 金融、货币、精确计算场景必须用DECIMAL。
-- FLOAT/DOUBLE适合科学计算（允许近似值）。

-- 【原理】
-- IEEE 754浮点数标准：某些十进制小数无法用二进制精确表示，只能近似。
-- 示例：0.1 + 0.2 在二进制下是 0.30000000000000004
-- DECIMAL是字符串存储，每一位数字都精确保留。

-- 【示例】
USE data_types_demo;

-- FLOAT精度丢失演示
CREATE TABLE t_float_precision (
    id INT PRIMARY KEY,
    amount_float FLOAT,
    amount_decimal DECIMAL(10,2)
);
INSERT INTO t_float_precision VALUES (1, 0.07, 0.07), (2, 0.05, 0.05), (3, 0.03, 0.03);
INSERT INTO t_float_precision (id, amount_float, amount_decimal) VALUES (4, 0.01, 0.01);

SELECT
    id,
    amount_float,
    SUM(amount_float) AS float_sum,
    amount_decimal,
    SUM(amount_decimal) AS decimal_sum
FROM t_float_precision
GROUP BY id;

-- 银行转账场景：减法精度问题
CREATE TABLE t_account_money (
    id INT PRIMARY KEY,
    balance_float FLOAT,
    balance_decimal DECIMAL(15,2)
);
INSERT INTO t_account_money VALUES (1, 1000.00, 1000.00);

-- 连续多次扣款（0.1元扣10次，应该剩999元，但FLOAT可能有精度问题）
UPDATE t_account_money SET balance_float = balance_float - 0.1;
UPDATE t_account_money SET balance_decimal = balance_decimal - 0.1;

SELECT
    balance_float,
    balance_decimal
FROM t_account_money;
-- FLOAT可能显示 999.0000000000001 或 998.9999999999999
-- DECIMAL精确显示 999.00

-- ================================================================
-- Q5: ENUM和SET类型是什么？何时使用？

-- 【解答】
-- ENUM：单选枚举，只能选一个值，最多65535个成员
-- SET：多选集合，可以选零个或多个值，最多64个成员

-- 【原理】
-- ENUM：适合性别、状态、类型等有限选项。存储时用1-2字节整数，节省空间。
-- SET：适合权限、标签等多选场景。存储时用位图，8个成员用1字节。
-- 如果选项会频繁增加，用VARCHAR更灵活；如果固定且量大，用ENUM/SET节省空间。

-- 【示例】
USE data_types_demo;

CREATE TABLE t_enum_set_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,

    -- ENUM：单选
    gender ENUM('Male', 'Female', 'Unknown'),
    order_status ENUM('pending', 'paid', 'shipped', 'delivered', 'cancelled'),

    -- SET：多选
    roles SET('admin', 'editor', 'author', 'viewer'),
    permissions SET('read', 'write', 'delete', 'admin')
);

INSERT INTO t_enum_set_demo (gender, order_status, roles, permissions) VALUES
    ('Female', 'paid', 'admin,editor', 'read,write'),
    ('Male', 'shipped', 'author', 'read'),
    ('Unknown', 'pending', 'viewer', 'read');

SELECT * FROM t_enum_set_demo;

-- ENUM排序（按定义顺序，不是字母顺序）
INSERT INTO t_enum_set_demo (gender, order_status, roles, permissions) VALUES
    ('Male', 'cancelled', 'admin', 'delete');

SELECT order_status, COUNT(*) FROM t_enum_set_demo GROUP BY order_status;
-- pending=1, paid=1, shipped=1, delivered=0, cancelled=1

-- SET查询（查找包含特定权限的用户）
SELECT * FROM t_enum_set_demo WHERE FIND_IN_SET('admin', roles) > 0;
SELECT * FROM t_enum_set_demo WHERE FIND_IN_SET('write', permissions) > 0;

-- ================================================================
-- Q6: BLOB和TEXT有什么区别？何时使用？

-- 【解答】
-- BLOB（Binary Large Object）：二进制大对象，存储原始字节流，无字符集概念
-- TEXT：文本大对象，存储字符数据，有字符集概念，会进行字符排序和比较

-- 【原理】
-- BLOB类型：TINYBLOB / BLOB / MEDIUMBLOB / LONGBLOB
-- TEXT类型：TINYTEXT / TEXT / MEDIUMTEXT / LONGTEXT
-- 存储上限：约255B / 64KB / 16MB / 4GB
-- InnoDB会把BLOB/TEXT的大列存储在溢出页（除非列放在最前面）

-- 【适用场景】
-- BLOB：图片、音频、视频、压缩数据、加密数据
-- TEXT：文章内容、日志、JSON/XML大文档、代码片段

-- 【示例】
USE data_types_demo;

CREATE TABLE t_blob_text_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100),
    content TEXT,                   -- 文章正文
    attachment BLOB                -- 二进制附件
);

INSERT INTO t_blob_text_demo (title, content) VALUES
    ('Article 1', '这是一篇很长的文章内容...'),
    ('Article 2', '另一篇文章，包含更多文字内容...');

-- 插入图片数据（实际生产中用程序读取文件，这里演示语法）
-- INSERT INTO t_blob_text_demo (title, attachment) VALUES ('Image', LOAD_FILE('/path/to/image.jpg'));

-- TEXT的字符集影响排序
CREATE TABLE t_text_charset (
    id INT PRIMARY KEY,
    content TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
);
INSERT INTO t_text_charset VALUES (1, '中国');
SELECT * FROM t_text_charset;

-- ================================================================
-- Q7: 无符号整数（UNSIGNED）是什么？为什么有时需要使用？

-- 【解答】
-- UNSIGNED：表示无符号数，只能表示非负整数，取值范围翻倍（正数范围）
-- 有符号：-128~127；无符号：0~255（TINYINT为例）

-- 【原理】
-- 存储方式相同（都是固定字节），只是解释方式不同。
-- 用途：ID、计数器、年龄、数量、版本号等不可能为负的场景。
-- 如果明确某字段永远不会是负数，用UNSIGNED可以扩大一倍正数范围。

-- 【示例】
USE data_types_demo;

CREATE TABLE t_unsigned_demo (
    id INT UNSIGNED PRIMARY KEY,          -- 用户ID不会是负数
    age TINYINT UNSIGNED,                 -- 年龄0-255足够
    view_count INT UNSIGNED DEFAULT 0,     -- 浏览次数
    balance DECIMAL(10,2)                 -- 余额可以是负数吗？这里先不设UNSIGNED
);

INSERT INTO t_unsigned_demo VALUES
    (1, 25, 100, 500.00),
    (4294967295, 255, 999999999, 0.00);  -- INT UNSIGNED最大值

SELECT * FROM t_unsigned_demo;

-- 如果用有符号INT，最大只能到2147483647，无法存4294967295
-- CREATE TABLE t_bad (id INT PRIMARY KEY);
-- INSERT INTO t_bad VALUES (4294967295);  -- Error

-- 注意：不能给已经插入负数的列加UNSIGNED
CREATE TABLE t_signed_test (id INT);
INSERT INTO t_signed_test VALUES (-1);
-- ALTER TABLE t_signed_test MODIFY COLUMN id INT UNSIGNED;  -- Error: 数据已含负数

-- ================================================================
-- Q8: 如何选择字段的默认值（DEFAULT）？

-- 【解答】
-- DEFAULT：为字段设置默认值，INSERT时不提供值时使用
-- 常用默认值：数字用0，字符串用空字符串，日期用CURRENT_TIMESTAMP

-- 【原理】
-- 没有DEFAULT的字段，INSERT时必须显式提供值（除非允许NULL）。
-- DEFAULT可以是常量、表达式（MySQL 5.7+支持）、或CURRENT_TIMESTAMP等时间函数。
-- 自定义默认值不能用于TIMESTAMP（会自动维护）和AUTO_INCREMENT。

-- 【示例】
USE data_types_demo;

CREATE TABLE t_default_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,

    -- 数字默认值
    age INT DEFAULT 0,
    score DECIMAL(5,1) DEFAULT 0.0,

    -- 字符串默认值
    phone VARCHAR(20) DEFAULT '' NOT NULL,
    bio VARCHAR(200) DEFAULT NULL,         -- 显式NULL，不是空字符串
    status VARCHAR(20) DEFAULT 'active',

    -- 日期时间默认值
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    birth_date DATE DEFAULT NULL,

    -- 表达式默认值（MySQL 5.7+）
    total_amount DECIMAL(10,2) DEFAULT (100.00 * 2)
);

INSERT INTO t_default_demo (name) VALUES ('Alice');
INSERT INTO t_default_demo (name, age, phone, status) VALUES ('Bob', 30, '13800138000', 'inactive');

SELECT * FROM t_default_demo;
-- Alice：age=0, score=0.0, phone='', bio=NULL, status='active'
-- Bob：age=30, score=0.0, phone='13800138000', bio=NULL, status='inactive'

-- 注意：DEFAULT CURRENT_TIMESTAMP 只能在DATETIME/TIMESTAMP上使用
-- 下面的CREATE会失败
-- CREATE TABLE t_bad (id INT DEFAULT (MAX(id)+1));  -- 不能用聚合函数做默认值
