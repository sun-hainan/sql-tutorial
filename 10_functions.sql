-- ================================================================
-- 模块十：常用函数
-- ================================================================

-- Q1: 字符串函数有哪些？如何处理字符串？

-- 【解答】
-- CONCAT：连接字符串
-- LENGTH/CHAR_LENGTH：计算长度
-- LEFT/RIGHT/SUBSTRING：截取字符串
-- UPPER/LOWER：大小写转换
-- TRIM/LTRIM/RTRIM：去除空格
-- REPLACE：替换字符串

-- 【原理】
-- MySQL字符串索引从1开始（不是0）。
-- CHAR_LENGTH按字符数计，LENGTH按字节数计（utf8mb4中汉字占4字节）。
-- SUBSTRING(str, pos, len) pos为1表示从第一个字符开始。

-- 【示例】
DROP DATABASE IF EXISTS functions_demo;
CREATE DATABASE functions_demo;
USE functions_demo;

-- CONCAT：连接字符串
SELECT CONCAT('Hello', ' ', 'World') AS greeting;
SELECT CONCAT('User_', 123) AS username;

-- CONCAT_WS：指定分隔符连接
SELECT CONCAT_WS('-', '2024', '01', '15') AS date_str;  -- 2024-01-15

-- LENGTH vs CHAR_LENGTH
SELECT
    LENGTH('中国') AS byte_len,
    CHAR_LENGTH('中国') AS char_len;

-- 截取函数
SELECT LEFT('HelloWorld', 5) AS left_part;   -- Hello
SELECT RIGHT('HelloWorld', 5) AS right_part; -- World
SELECT SUBSTRING('HelloWorld', 6, 5) AS mid_part;  -- World

-- 大小写转换
SELECT UPPER('hello') AS upper_str;  -- HELLO
SELECT LOWER('HELLO') AS lower_str;  -- hello

-- TRIM：去除首尾空格
SELECT CONCAT('[', TRIM('  hello  '), ']') AS trimmed;
SELECT CONCAT('[', LTRIM('  hello  '), ']') AS ltrimmed;
SELECT CONCAT('[', RTRIM('  hello  '), ']') AS rtrimmed;

-- REPLACE：替换字符串
SELECT REPLACE('Hello World', 'World', 'MySQL') AS replaced;

CREATE TABLE t_user_info (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100)
);
INSERT INTO t_user_info VALUES
    (1, 'alice', '13812345678', 'ALICE@EXAMPLE.COM'),
    (2, 'bob', '13998765432', 'BOB@EXAMPLE.COM');

SELECT CONCAT(username, ' - ', phone) AS contact FROM t_user_info;
SELECT username, CONCAT(SUBSTRING(phone, 1, 3), '****', SUBSTRING(phone, 8)) AS masked_phone FROM t_user_info;
SELECT username, LOWER(email) AS email FROM t_user_info;

-- ================================================================
-- Q2: 数值函数有哪些？

-- 【解答】
-- 算术：+ - * / %
-- 常用：ABS/CEIL/FLOOR/ROUND/TRUNCATE
-- 数学：SQRT/POW/LOG/EXP/SIN/COS/TAN

-- 【原理】
-- MySQL的除法(/)默认返回精确的DECIMAL，地板除(DIV)返回整数。
-- 四舍五入：ROUND(num, decimal_places)
-- 取上限：CEIL / CEILING
-- 取下限：FLOOR

-- 【示例】
USE functions_demo;

SELECT 10 + 3 AS add_result;
SELECT 10 - 3 AS sub_result;
SELECT 10 * 3 AS mul_result;
SELECT 10 / 3 AS div_result;
SELECT 10 DIV 3 AS int_div_result;
SELECT 10 % 3 AS mod_result;

SELECT ABS(-10) AS abs_result;
SELECT ROUND(3.14159, 2) AS rounded;
SELECT CEIL(3.1) AS ceil_result;
SELECT FLOOR(3.9) AS floor_result;
SELECT TRUNCATE(3.14159, 3) AS truncated;

SELECT SQRT(16) AS sqrt_result;
SELECT POW(2, 3) AS pow_result;

CREATE TABLE t_product_price (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    price DECIMAL(10,2)
);
INSERT INTO t_product_price VALUES (1, 'Laptop', 5000.00), (2, 'Mouse', 89.50);

SELECT name, price, ROUND(price * 0.85, 2) AS discounted_price FROM t_product_price;

-- ================================================================
-- Q3: 日期时间函数有哪些？

-- 【解答】
-- 获取：NOW() / CURDATE() / CURTIME()
-- 提取：YEAR() / MONTH() / DAY() / HOUR() / MINUTE() / SECOND()
-- 计算：DATE_ADD() / DATE_SUB() / DATEDIFF() / TIMESTAMPDIFF()
-- 格式化：DATE_FORMAT() / STR_TO_DATE()

-- 【原理】
-- NOW()：返回'2024-01-15 12:30:45'（带时间）
-- CURDATE()：返回'2024-01-15'（仅日期）
-- CURTIME()：返回'12:30:45'（仅时间）
-- 日期加减单位：DAY / MONTH / YEAR / HOUR / MINUTE / SECOND

-- 【示例】
USE functions_demo;

SELECT NOW() AS current_datetime;
SELECT CURDATE() AS current_date;
SELECT CURTIME() AS current_time;

SELECT
    NOW() AS now_val,
    YEAR(NOW()) AS yr,
    MONTH(NOW()) AS mo,
    DAY(NOW()) AS dy,
    HOUR(NOW()) AS hr,
    MINUTE(NOW()) AS mi,
    SECOND(NOW()) AS sc;

SELECT DATE_ADD('2024-01-15', INTERVAL 10 DAY) AS after_10_days;
SELECT DATE_SUB('2024-01-15', INTERVAL 1 MONTH) AS before_1_month;
SELECT DATE_ADD(NOW(), INTERVAL 1 HOUR) AS after_1_hour;

SELECT DATEDIFF('2024-01-20', '2024-01-15') AS days_diff;
SELECT TIMESTAMPDIFF(DAY, '2024-01-15', '2024-01-20') AS days_diff2;
SELECT TIMESTAMPDIFF(HOUR, '2024-01-15 10:00', '2024-01-15 12:00') AS hours_diff;

SELECT LAST_DAY('2024-01-15') AS last_day_of_month;

CREATE TABLE t_employee_hired (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    hire_date DATE
);
INSERT INTO t_employee_hired VALUES
    (1, 'Alice', '2022-03-15'),
    (2, 'Bob', '2023-07-20'),
    (3, 'Carol', '2024-01-10');

SELECT
    name,
    hire_date,
    DATEDIFF(CURDATE(), hire_date) AS days_employed,
    TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS years_employed
FROM t_employee_hired;

-- ================================================================
-- Q4: DATE_FORMAT如何使用？常用格式符有哪些？

-- 【解答】
-- DATE_FORMAT(date, format)：将日期格式化为字符串
-- STR_TO_DATE(str, format)：将字符串解析为日期

-- 【原理】
-- 格式符：%Y=4位年，%y=2位年，%m=2位月，%d=2位日
-- %H=24小时制，%h=12小时制，%i=分钟，%s=秒
-- %W=星期全名，%a=星期缩写

-- 【示例】
USE functions_demo;

SELECT DATE_FORMAT(NOW(), '%Y-%m-%d') AS date_iso;
SELECT DATE_FORMAT(NOW(), '%Y年%m月%d日') AS date_cn;
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s') AS datetime_full;
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d %h:%i:%s %p') AS datetime_12h;
SELECT DATE_FORMAT(NOW(), '%H:%i:%s') AS time_24h;
SELECT DATE_FORMAT(NOW(), '%h:%i:%s %p') AS time_12h;
SELECT DATE_FORMAT(NOW(), '%W') AS weekday_name;
SELECT DATE_FORMAT(NOW(), '%a') AS weekday_abbr;
SELECT QUARTER(NOW()) AS quarter_num;

CREATE TABLE t_order_info (
    order_id INT PRIMARY KEY,
    order_date DATETIME
);
INSERT INTO t_order_info VALUES
    (1, '2024-01-15 14:30:00'),
    (2, '2024-02-20 09:15:00');

SELECT
    order_id,
    DATE_FORMAT(order_date, '%Y年%m月%d日 %H:%i') AS order_datetime_cn,
    DATE_FORMAT(order_date, '%Y/%m/%d') AS order_date_slash
FROM t_order_info;

SELECT STR_TO_DATE('2024-01-15', '%Y-%m-%d') AS parsed_date;
SELECT STR_TO_DATE('15/01/2024', '%d/%m/%Y') AS parsed_date_eu;

-- ================================================================
-- Q5: 流程控制函数有哪些？IF、CASE WHEN的用法？

-- 【解答】
-- IF(condition, val_true, val_false)：条件表达式
-- IFNULL(expr, default)：NULL替换
-- CASE WHEN ... THEN ... END：多条件分支

-- 【原理】
-- IF类似三元运算符，condition为真返回val_true，否则返回val_false。
-- CASE WHEN支持多条件分支，可以是等值比较或范围比较。
-- 在SELECT、WHERE、ORDER BY中都可以使用流程控制函数。

-- 【示例】
USE functions_demo;

SELECT IF(10 > 5, 'Yes', 'No') AS result;

CREATE TABLE t_student_grade (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    score INT
);
INSERT INTO t_student_grade VALUES (1, 'Alice', 85), (2, 'Bob', 72), (3, 'Carol', 93);

SELECT
    name,
    score,
    IF(score >= 90, 'A', IF(score >= 80, 'B', IF(score >= 60, 'C', 'D'))) AS grade
FROM t_student_grade;

SELECT IFNULL(NULL, 'default') AS result;
SELECT IFNULL('value', 'default') AS result;

SELECT COALESCE(NULL, NULL, 'first', 'second') AS result;

CREATE TABLE t_sales_region (
    region VARCHAR(20),
    amount DECIMAL(10,2)
);
INSERT INTO t_sales_region VALUES
    ('North', 5000), ('South', 3000), ('East', 4000), ('West', 2000);

SELECT
    SUM(CASE WHEN region = 'North' THEN amount ELSE 0 END) AS north_total,
    SUM(CASE WHEN region = 'South' THEN amount ELSE 0 END) AS south_total,
    SUM(CASE WHEN region = 'East' THEN amount ELSE 0 END) AS east_total,
    SUM(CASE WHEN region = 'West' THEN amount ELSE 0 END) AS west_total
FROM t_sales_region;

-- ================================================================
-- Q6: IFNULL和COALESCE的区别？

-- 【解答】
-- IFNULL(expr, default)：替换单个NULL值
-- COALESCE(expr1, expr2, ...)：返回第一个非NULL值

-- 【原理】
-- IFNULL只接受两个参数，等价于 CASE WHEN expr IS NULL THEN default ELSE expr END
-- COALESCE可以接受多个参数，常用于从多列中取第一个非NULL值

-- 【示例】
USE functions_demo;

SELECT IFNULL(NULL, 'N/A') AS result1;
SELECT IFNULL('value', 'N/A') AS result2;
SELECT COALESCE(NULL, NULL, 'first') AS result3;
SELECT COALESCE('first', 'second') AS result4;

CREATE TABLE t_contact (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    wechat VARCHAR(50)
);
INSERT INTO t_contact VALUES
    (1, 'Alice', '13812345678', 'alice@example.com', 'alice_wx'),
    (2, 'Bob', NULL, 'bob@example.com', NULL),
    (3, 'Carol', '13900000000', NULL, NULL);

SELECT name, COALESCE(phone, email, wechat, 'No Contact') AS contact FROM t_contact;

-- ================================================================
-- Q7: 如何使用GROUP_CONCAT实现行转列？

-- 【解答】
-- GROUP_CONCAT：聚合函数，将分组内的值连接成字符串
-- 语法：GROUP_CONCAT(DISTINCT col ORDER BY col SEPARATOR delim)

-- 【原理】
-- GROUP_CONCAT是MySQL特有的聚合函数，用于把分组内的多行值合并为一个字符串。
-- 默认分隔符是逗号，可用SEPARATOR指定。
-- 可以配合DISTINCT去重，ORDER BY排序。

-- 【示例】
USE functions_demo;

CREATE TABLE t_student_subject (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(50),
    subject VARCHAR(20)
);
INSERT INTO t_student_subject VALUES
    (1, 'Alice', 'Math'),
    (2, 'Alice', 'English'),
    (3, 'Alice', 'Physics'),
    (4, 'Bob', 'Math'),
    (5, 'Bob', 'English'),
    (6, 'Carol', 'Math');

SELECT student_name, GROUP_CONCAT(subject) AS subjects
FROM t_student_subject
GROUP BY student_name;

SELECT student_name, GROUP_CONCAT(subject ORDER BY subject SEPARATOR ', ') AS subjects
FROM t_student_subject
GROUP BY student_name;

CREATE TABLE t_order_product (
    order_id INT,
    product_name VARCHAR(50)
);
INSERT INTO t_order_product VALUES
    (1, 'Laptop'), (1, 'Mouse'), (1, 'Keyboard'),
    (2, 'Monitor'),
    (3, 'Keyboard'), (3, 'Webcam');

SELECT order_id, GROUP_CONCAT(product_name SEPARATOR ', ') AS product_list
FROM t_order_product
GROUP BY order_id;

-- ================================================================
-- Q8: CAST和CONVERT函数的作用？

-- 【解答】
-- CAST(expr AS TYPE)：类型转换
-- CONVERT(expr, TYPE)：类型转换（MySQL特有语法）
-- 常用于将字符串转为数字、日期，将数字转为字符串等

-- 【原理】
-- MySQL会自动进行隐式类型转换，但有时需要显式转换确保精度。
-- 常见类型：CHAR / DATE / DATETIME / DECIMAL / SIGNED / UNSIGNED
-- CAST比CONVERT更标准（SQL标准语法），CONVERT支持字符集转换。

-- 【示例】
USE functions_demo;

SELECT CAST('123' AS SIGNED) + 10 AS result;
SELECT CONVERT('123.45', DECIMAL(5,2)) AS result;
SELECT CAST(123 AS CHAR) AS str_val;
SELECT CAST('2024-01-15' AS DATE) AS date_val;
SELECT CAST('2024-01-15 12:30:45' AS DATETIME) AS datetime_val;
SELECT CAST('123.456' AS DECIMAL(5,2)) AS result;

CREATE TABLE t_sales_str (
    id INT PRIMARY KEY,
    amount VARCHAR(20)
);
INSERT INTO t_sales_str VALUES (1, '1000.50'), (2, '2000.75');

SELECT id, amount, CAST(amount AS DECIMAL(10,2)) AS amount_num FROM t_sales_str;
SELECT SUM(CAST(amount AS DECIMAL(10,2))) AS total FROM t_sales_str;
