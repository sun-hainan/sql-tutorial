-- ================================================================
-- 模块十三：存储过程与函数
-- ================================================================

-- Q1: 存储过程（PROCEDURE）是什么？如何创建和调用？

-- 【解答】
-- 存储过程：预先编译的SQL代码块，存储在数据库中，可接受参数、执行逻辑、返回结果
-- 创建：CREATE PROCEDURE proc_name(params) BEGIN ... END
-- 调用：CALL proc_name(args)

-- 【原理】
-- 存储过程是预编译的，执行效率比普通SQL高。
-- 存储过程可以包含：变量、IF/WHILE语句、游标、异常处理。
-- 参数模式：IN（输入）、OUT（输出）、INOUT（输入输出）。

-- 【示例】
DROP DATABASE IF EXISTS sp_demo;
CREATE DATABASE sp_demo;
USE sp_demo;

CREATE TABLE t_account (
    account_id INT PRIMARY KEY,
    account_name VARCHAR(50),
    balance DECIMAL(10,2)
);
INSERT INTO t_account VALUES (1, 'Alice', 10000), (2, 'Bob', 5000);

-- 创建简单的存储过程：转帐
DELIMITER //
CREATE PROCEDURE p_transfer(
    IN p_from_id INT,
    IN p_to_id INT,
    IN p_amount DECIMAL(10,2)
)
BEGIN
    -- 检查余额
    IF (SELECT balance FROM t_account WHERE account_id = p_from_id) < p_amount THEN
        SELECT 'Insufficient balance' AS message;
    ELSE
        -- 扣款
        UPDATE t_account SET balance = balance - p_amount WHERE account_id = p_from_id;
        -- 加款
        UPDATE t_account SET balance = balance + p_amount WHERE account_id = p_to_id;
        SELECT 'Transfer successful' AS message;
    END IF;
END//
DELIMITER ;

-- 调用存储过程
CALL p_transfer(1, 2, 1000);
SELECT * FROM t_account;

-- ================================================================
-- Q2: 函数（FUNCTION）与存储过程的区别？

-- 【解答】
-- 函数：必须有返回值，只能读取数据，不能修改数据
-- 存储过程：可修改数据，可返回多个结果集，参数模式更多
-- 函数可在SQL表达式中调用，存储过程需CALL调用

-- 【原理】
-- 函数限制：不能有OUT参数、不能调用存储过程、不能修改数据
-- 函数优点：可以在SELECT中使用，可以计算后作为列值
-- 存储过程：适合复杂业务流程、批量操作、需要事务控制的场景

-- 【示例】
USE sp_demo;

-- 创建函数：计算个人所得税
DELIMITER //
CREATE FUNCTION f_calculate_tax(p_salary DECIMAL(10,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_tax DECIMAL(10,2);
    IF p_salary <= 5000 THEN
        SET v_tax = 0;
    ELSEIF p_salary <= 10000 THEN
        SET v_tax = (p_salary - 5000) * 0.10;
    ELSE
        SET v_tax = (p_salary - 5000) * 0.20;
    END IF;
    RETURN v_tax;
END//
DELIMITER ;

-- 在查询中调用函数
SELECT emp_name, salary, f_calculate_tax(salary) AS tax FROM t_account;

-- 创建函数：返回格式化金额
DELIMITER //
CREATE FUNCTION f_format_amount(p_amount DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    RETURN CONCAT('¥', FORMAT(p_amount, 2));
END//
DELIMITER ;

-- 在WHERE中使用函数
SELECT emp_name, f_format_amount(salary) AS salary_formatted
FROM t_account
WHERE f_calculate_tax(salary) > 100;

-- ================================================================
-- Q3: 变量、条件和循环的用法？

-- 【解答】
-- 变量：DECLARE / SET / SELECT ... INTO
-- 条件：IF-THEN-ELSE / CASE-WHEN
-- 循环：WHILE / REPEAT / LOOP

-- 【原理】
-- 变量在BEGIN...END块中声明，作用域是该块及其子块。
-- 条件语句用于分支逻辑。
-- 循环语句用于重复执行代码块。
-- ITERATE相当于continue，LEAVE相当于break。

-- 【示例】
USE sp_demo;

-- 变量演示
DELIMITER //
CREATE PROCEDURE p_variable_demo()
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_max_salary DECIMAL(10,2);

    SELECT COUNT(*), MAX(salary) INTO v_count, v_max_salary FROM t_account;

    SELECT CONCAT('Total: ', v_count, ', Max: ', v_max_salary) AS result;
END//
DELIMITER ;

CALL p_variable_demo();

-- IF-THEN-ELSE演示
DELIMITER //
CREATE FUNCTION f_grade_level(p_score INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE v_level VARCHAR(10);
    IF p_score >= 90 THEN
        SET v_level = 'A';
    ELSEIF p_score >= 80 THEN
        SET v_level = 'B';
    ELSEIF p_score >= 60 THEN
        SET v_level = 'C';
    ELSE
        SET v_level = 'D';
    END IF;
    RETURN v_level;
END//
DELIMITER ;

-- CASE-WHEN演示（函数）
DELIMITER //
CREATE FUNCTION f_month_name(p_month INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    CASE p_month
        WHEN 1 THEN RETURN 'January';
        WHEN 2 THEN RETURN 'February';
        WHEN 3 THEN RETURN 'March';
        WHEN 4 THEN RETURN 'April';
        WHEN 5 THEN RETURN 'May';
        WHEN 6 THEN RETURN 'June';
        WHEN 7 THEN RETURN 'July';
        WHEN 8 THEN RETURN 'August';
        WHEN 9 THEN RETURN 'September';
        WHEN 10 THEN RETURN 'October';
        WHEN 11 THEN RETURN 'November';
        WHEN 12 THEN RETURN 'December';
        ELSE RETURN 'Invalid';
    END CASE;
END//
DELIMITER ;

SELECT f_month_name(3);

-- WHILE循环演示
DELIMITER //
CREATE PROCEDURE p_while_demo()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE result VARCHAR(200) DEFAULT '';

    WHILE i <= 5 DO
        SET result = CONCAT(result, i, ',');
        SET i = i + 1;
    END WHILE;

    SELECT result AS sequence;
END//
DELIMITER ;

CALL p_while_demo();

-- REPEAT循环（至少执行一次）
DELIMITER //
CREATE PROCEDURE p_repeat_demo()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE result VARCHAR(200) DEFAULT '';

    REPEAT
        SET result = CONCAT(result, i, ',');
        SET i = i + 1;
    UNTIL i > 5 END REPEAT;

    SELECT result AS sequence;
END//
DELIMITER ;

CALL p_repeat_demo();

-- ================================================================
-- Q4: 游标（CURSOR）是什么？如何使用？

-- 【解答】
-- 游标：用于遍历查询结果集的机制，可以在存储过程中逐行处理数据
-- 声明：DECLARE cursor_name CURSOR FOR SELECT ...
-- 使用：OPEN / FETCH / CLOSE

-- 【原理】
-- 游标必须在声明变量之后声明，顺序很重要。
-- 游标使用流程：DECLARE → OPEN → FETCH → 处理 → CLOSE。
-- 游标遍历结束后需要处理NOT FOUND条件（通常配合DECLARE ... HANDLER）。
-- 游标适合逐行处理复杂业务逻辑的场景。

-- 【示例】
USE sp_demo;

CREATE TABLE t_sales (
    id INT PRIMARY KEY,
    product_name VARCHAR(50),
    amount DECIMAL(10,2)
);
INSERT INTO t_sales VALUES
    (1, 'Laptop', 5000), (2, 'Mouse', 99), (3, 'Keyboard', 299),
    (4, 'Monitor', 1299), (5, 'Headset', 199);

-- 使用游标统计销售总额
DELIMITER //
CREATE PROCEDURE p_cursor_demo()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_amount DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;

    -- 声明游标
    DECLARE cur CURSOR FOR SELECT amount FROM t_sales;

    -- 声明继续条件处理器
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_amount;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SET v_total = v_total + v_amount;
    END LOOP;

    CLOSE cur;

    SELECT CONCAT('Total sales: ', v_total) AS result;
END//
DELIMITER ;

CALL p_cursor_demo();

-- ================================================================
-- Q5: 如何查看、修改和删除存储过程/函数？

-- 【解答】
-- 查看：SHOW CREATE PROCEDURE/FUNCTION sp_name
-- 修改：CREATE OR REPLACE（MySQL 8.0+）或DROP + CREATE
-- 删除：DROP PROCEDURE/FUNCTION [IF EXISTS] sp_name

-- 【原理】
-- 存储过程和函数存放在mysql.proc系统表中（MySQL 8.0前）或数据字典中（8.0+）。
-- ALTER PROCEDURE只能修改特征（语言、SQL、并发等），不能修改代码。
-- 修改代码需要DROP后重新CREATE。

-- 【示例】
USE sp_demo;

-- 查看存储过程/函数列表
SHOW PROCEDURE STATUS;
SHOW FUNCTION STATUS;

-- 查看特定存储过程定义
SHOW CREATE PROCEDURE p_transfer;
SHOW CREATE FUNCTION f_calculate_tax;

-- 查看参数和特征
SHOW CREATE PROCEDURE p_transfer\G

-- 删除存储过程
DROP PROCEDURE IF EXISTS p_variable_demo;

-- 删除函数
DROP FUNCTION IF EXISTS f_format_amount;

-- 修改存储过程特征（不能修改代码）
-- ALTER PROCEDURE p_transfer READS SQL DATA;

-- ================================================================
-- Q6: 存储过程和函数的重要参数特性？

-- 【解答】
-- DETERMINISTIC：相同输入是否产生相同输出
-- NO SQL：不含SQL语句
-- READS SQL DATA：只读取数据
-- MODIFIES SQL DATA：修改数据

-- 【原理】
-- 这些特性是MySQL的元数据声明，不是强制约束。
-- InnoDB表默认允许创建函数/存储过程，但Binary Log记录可能会有要求。
-- 设置log_bin_trust_function_creators = 1 可避免创建限制。

-- 【示例】
-- 创建函数时指定特性
DELIMITER //
CREATE FUNCTION f_simple_return()
RETURNS INT
NOT DETERMINISTIC
NO SQL
BEGIN
    RETURN 42;
END//
DELIMITER ;

SELECT f_simple_return();

-- 查看函数特性
SHOW CREATE FUNCTION f_simple_return;
SHOW FUNCTION STATUS LIKE 'f_simple_return';

-- 设置全局参数允许创建函数（需管理员权限）
-- SET GLOBAL log_bin_trust_function_creators = 1;
