-- ================================================================
-- 模块八：查询基础
-- ================================================================

-- Q1: SELECT语句的执行顺序是什么？

-- 【解答】
-- SQL中各子句按以下顺序执行：
-- FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT

-- 【原理】
-- 这个顺序至关重要，决定了：
-- 1. WHERE在SELECT之前，所以不能用SELECT的别名做过滤（如 WHERE age > AVG(age) 错误）
-- 2. HAVING在GROUP BY之后，所以可以用聚合函数做过滤
-- 3. ORDER BY在SELECT之后，所以可以用SELECT的别名排序
-- 4. LIMIT最后执行，用于最终结果分页

-- 【示例】
DROP DATABASE IF EXISTS select_demo;
CREATE DATABASE select_demo;
USE select_demo;

CREATE TABLE t_score (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(50),
    subject VARCHAR(20),
    score INT,
    class_id INT
);
INSERT INTO t_score (student_name, subject, score, class_id) VALUES
    ('Alice', 'Math', 85, 1),
    ('Bob', 'Math', 92, 1),
    ('Carol', 'Math', 78, 2),
    ('Alice', 'English', 90, 1),
    ('Bob', 'English', 88, 1),
    ('Carol', 'English', 95, 2),
    ('David', 'Math', 70, 2),
    ('Eve', 'English', 82, 1);

-- 执行顺序演示：
-- 1. FROM：确定数据来源
-- 2. WHERE：先过滤class_id=1
-- 3. GROUP BY：按subject分组
-- 4. HAVING：过滤平均分>85的组
-- 5. SELECT：选出subject和平均分（别名avg_score）
-- 6. ORDER BY：按avg_score排序
-- 7. LIMIT：取前1条

SELECT subject, AVG(score) AS avg_score
FROM t_score
WHERE class_id = 1
GROUP BY subject
HAVING AVG(score) > 85
ORDER BY avg_score DESC
LIMIT 1;

-- 常见错误：在WHERE中使用聚合函数
-- SELECT * FROM t_score WHERE AVG(score) > 85;  -- Error: Invalid use of group function

-- 正确做法：用HAVING配合GROUP BY
SELECT subject, AVG(score) AS avg_score
FROM t_score
GROUP BY subject
HAVING AVG(score) > 85;

-- ================================================================
-- Q2: WHERE子句有哪些常用条件过滤方式？

-- 【解答】
-- 基础比较：= / <> / > / < / >= / <=
-- 组合条件：AND / OR / NOT
-- 范围查询：BETWEEN ... AND ... / IN(...) / LIKE
-- NULL查询：IS NULL / IS NOT NULL

-- 【原理】
-- WHERE在FROM之后执行，先于GROUP BY和聚合函数。
-- AND优先级高于OR，必要时用括号明确优先级。
-- 字符串比较默认不区分大小写（ collation决定）。
-- BETWEEN是闭区间[a, b]，IN可以替代多个OR。

-- 【示例】
USE select_demo;

-- 基础比较
SELECT * FROM t_score WHERE score >= 80;
SELECT * FROM t_score WHERE student_name = 'Alice';

-- AND / OR组合
SELECT * FROM t_score WHERE subject = 'Math' AND score > 80;
SELECT * FROM t_score WHERE subject = 'Math' OR subject = 'English';

-- BETWEEN（闭区间）
SELECT * FROM t_score WHERE score BETWEEN 75 AND 90;  -- 75<=score<=90
-- 等价于：score >= 75 AND score <= 90

-- IN（代替多个OR）
SELECT * FROM t_score WHERE student_name IN ('Alice', 'Bob', 'Carol');
-- 等价于：student_name = 'Alice' OR student_name = 'Bob' OR student_name = 'Carol'

-- LIKE模糊匹配
-- %：任意字符序列，_：单个任意字符
SELECT * FROM t_score WHERE student_name LIKE 'A%';      -- 以A开头的名字
SELECT * FROM t_score WHERE student_name LIKE '%e%';     -- 包含e的名字
SELECT * FROM t_score WHERE student_name LIKE 'C_rl';   -- C开头+任意字符+r+任意字符+l（如Carol）

-- IS NULL / IS NOT NULL
SELECT * FROM t_score WHERE score IS NULL;
SELECT * FROM t_score WHERE score IS NOT NULL;

-- NOT取反
SELECT * FROM t_score WHERE score NOT BETWEEN 70 AND 90;
SELECT * FROM t_score WHERE student_name NOT IN ('Alice', 'Bob');

-- 组合复杂条件
SELECT * FROM t_score
WHERE (subject = 'Math' AND score > 80) OR (subject = 'English' AND score > 90);

-- ================================================================
-- Q3: ORDER BY如何使用？多字段排序和排序方向？

-- 【解答】
-- ORDER BY col1 [ASC|DESC], col2 [ASC|DESC]
-- ASC升序（默认），DESC降序
-- 多字段：先按第一字段排，相等时按第二字段排

-- 【原理】
-- ORDER BY在SELECT之后执行，所以可以用SELECT别名排序。
-- NULL值在排序中通常排在最前面（ASC）或最后面（DESC）。
-- 多个字段时，前面的字段优先级更高。

-- 【示例】
USE select_demo;

-- 单字段升序（默认）
SELECT * FROM t_score ORDER BY score ASC;
SELECT * FROM t_score ORDER BY score;  -- ASC可以省略

-- 单字段降序
SELECT * FROM t_score ORDER BY score DESC;

-- 多字段排序：先按subject，再按score
SELECT * FROM t_score ORDER BY subject ASC, score DESC;
-- 先按subject排序，所有Math排在一起，English排在一起
-- 同科目内再按score降序排

-- 表达式排序
SELECT student_name, score, score * 1.1 AS curved_score
FROM t_score
ORDER BY curved_score DESC;  -- 按加分后的分数排序

-- 按别名排序（因为ORDER BY在SELECT之后执行）
SELECT subject, AVG(score) AS avg_score
FROM t_score
GROUP BY subject
ORDER BY avg_score DESC;

-- NULL值排序位置
CREATE TABLE t_null_sort (
    id INT,
    val INT
);
INSERT INTO t_null_sort VALUES (1, 10), (2, NULL), (3, 20), (4, NULL);
SELECT * FROM t_null_sort ORDER BY val ASC;           -- NULL在最前
SELECT * FROM t_null_sort ORDER BY val DESC;          -- NULL在最后
SELECT * FROM t_null_sort ORDER BY val ASC NULLS LAST; -- MySQL不支持NULLS LAST语法，需用IFNULL

-- MySQL处理NULL排序：使用IFNULL或COALESCE
SELECT * FROM t_null_sort ORDER BY IFNULL(val, 999999) ASC;

-- ================================================================
-- Q4: DISTINCT和LIMIT的用法和区别？

-- 【解答】
-- DISTINCT：去除重复行，作用于SELECT的所有列组合
-- LIMIT：限制返回的行数，用于分页

-- 【原理】
-- DISTINCT去重是基于所有SELECT列的组合去重，不是单列去重。
-- DISTINCT不能用于部分列，所有SELECT列都参与去重。
-- LIMIT n OFFSET m：返回n条，跳过前m条。

-- 【示例】
USE select_demo;

-- DISTINCT基础
SELECT DISTINCT subject FROM t_score;
SELECT DISTINCT student_name FROM t_score;  -- 返回6个不同学生

-- DISTINCT作用于多列组合
SELECT DISTINCT class_id, subject FROM t_score;
-- 返回的是 (class_id, subject) 组合的去重结果

-- DISTINCT + 聚合函数
SELECT COUNT(DISTINCT student_name) AS student_count FROM t_score;
SELECT COUNT(DISTINCT class_id) AS class_count FROM t_score;

-- DISTINCT + 多列
SELECT COUNT(DISTINCT class_id, subject) AS distinct_combinations FROM t_score;

-- LIMIT基础
SELECT * FROM t_score LIMIT 5;

-- LIMIT + OFFSET（分页）
SELECT * FROM t_score ORDER BY id LIMIT 3 OFFSET 3;  -- 第2页，每页3条

-- 简写形式
SELECT * FROM t_score ORDER BY id LIMIT 6, 3;  -- LIMIT offset, count

-- LIMIT 0：获取前N条记录（常用于分页预览）
SELECT * FROM t_score LIMIT 0, 3;

-- DISTINCT + LIMIT组合
SELECT DISTINCT student_name FROM t_score LIMIT 3;  -- 先去重，再取前3

-- ================================================================
-- Q5: 别名（AS）的使用场景和注意事项？

-- 【解答】
-- 别名：给列或表起临时名称，用于简写、增强可读性、解决列名冲突
-- 语法：column AS alias / table_name alias

-- 【原理】
-- 列别名用于ORDER BY、HAVING、GROUP BY的引用（SELECT之后执行）。
-- 表别名在FROM子句中使用，作用域是整条SQL。
-- 如果别名含空格或关键字，需用引号（MySQL用反引号`alias`或引号' '）。

-- 【示例】
USE select_demo;

-- 列别名（输出时显示别名）
SELECT
    student_name AS name,
    score AS exam_score,
    score * 1.1 AS curved_score
FROM t_score;

-- 表别名（JOIN时必须用）
SELECT
    s.student_name,
    s.score
FROM t_score AS s
WHERE s.score > 80;

-- 不带AS的别名（语法允许，但不推荐）
SELECT student_name name FROM t_score;

-- 别名用于ORDER BY
SELECT
    subject,
    AVG(score) AS avg_score,
    MAX(score) AS max_score
FROM t_score
GROUP BY subject
ORDER BY avg_score DESC;

-- 别名用于HAVING
SELECT
    student_name,
    AVG(score) AS avg_score
FROM t_score
GROUP BY student_name
HAVING avg_score > 85;

-- 别名用于多表JOIN（防止列名冲突）
CREATE TABLE t_class (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
INSERT INTO t_class VALUES (1, 'Class A'), (2, 'Class B');

SELECT s.student_name, c.name AS class_name
FROM t_score s
LEFT JOIN t_class c ON s.class_id = c.id;

-- 别名含特殊字符需要引号
SELECT score AS 'Final Score' FROM t_score;
SELECT score AS "得分" FROM t_score;

-- ================================================================
-- Q6: UNION和UNION ALL的区别？如何合并查询结果？

-- 【解答】
-- UNION：合并多个SELECT结果集，自动去重
-- UNION ALL：合并多个SELECT结果集，保留所有行（包括重复）

-- 【原理】
-- UNION比UNION ALL多做一步去重，有性能开销。
-- 如果知道结果不会有重复，用UNION ALL更快。
-- UNION ALL不排序不去重，直接追加结果集。
-- 合并时列数必须相同，类型兼容。

-- 【示例】
USE select_demo;

-- UNION去重
SELECT student_name FROM t_score WHERE class_id = 1
UNION
SELECT student_name FROM t_score WHERE subject = 'English';
-- Alice和Bob出现两次，只保留一个

-- UNION ALL保留重复
SELECT student_name FROM t_score WHERE class_id = 1
UNION ALL
SELECT student_name FROM t_score WHERE subject = 'English';
-- 所有记录都保留，重复也保留

-- UNION配合ORDER BY（整个并集排序）
SELECT student_name, score FROM t_score WHERE class_id = 1
UNION ALL
SELECT student_name, score FROM t_score WHERE class_id = 2
ORDER BY score DESC;

-- 复杂示例：不同表合并
CREATE TABLE t_teacher (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
INSERT INTO t_teacher VALUES (1, 'Teacher Wang'), (2, 'Teacher Li');

-- 合并学生和教师姓名
SELECT student_name AS name FROM t_score
UNION
SELECT name FROM t_teacher
ORDER BY name;

-- 合并时列名以第一个SELECT为准
SELECT student_name FROM t_score
UNION
SELECT name FROM t_teacher;  -- 合并结果列名是 student_name

-- ================================================================
-- Q7: 子查询是什么？有哪些类型？

-- 【解答】
-- 子查询：嵌套在另一个查询内部的SELECT语句
-- 类型：标量子查询（返回单个值）、列子查询（返回一列）、行子查询（返回一行）、表子查询（返回临时表）

-- 【原理】
-- 子查询可以在WHERE、FROM、SELECT中使用。
-- WHERE中的子查询：作为条件的一部分（IN/EXISTS/比较运算符）
-- FROM中的子查询：作为临时表（必须给子查询起别名）
-- SELECT中的子查询：作为列的计算值

-- 【示例】
USE select_demo;

-- 标量子查询：返回单个值
SELECT * FROM t_score
WHERE score > (SELECT AVG(score) FROM t_score);  -- 高于平均分的成绩

-- 列子查询：返回一列值
SELECT * FROM t_score
WHERE student_name IN (SELECT DISTINCT student_name FROM t_score WHERE score > 85);

-- 行子查询：返回一行
CREATE TABLE t_best_student (
    student_name VARCHAR(50),
    subject VARCHAR(20),
    score INT
);
INSERT INTO t_best_student VALUES ('Alice', 'English', 90);
SELECT * FROM t_best_student WHERE (student_name, score) = (SELECT student_name, MAX(score) FROM t_score);

-- FROM子查询（派生表）
SELECT avg_score FROM (
    SELECT student_name, AVG(score) AS avg_score
    FROM t_score
    GROUP BY student_name
) AS student_avg
WHERE avg_score > 85;

-- SELECT中的子查询
SELECT
    student_name,
    score,
    (SELECT AVG(score) FROM t_score WHERE student_name = s.student_name) AS personal_avg,
    (SELECT MAX(score) FROM t_score) AS global_max
FROM t_score s;

-- EXISTS子查询
SELECT * FROM t_score s
WHERE EXISTS (
    SELECT 1 FROM t_score WHERE student_name = s.student_name AND score > 90
);

-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================
-- | 特性            | MySQL               | PostgreSQL           | Oracle              | SQLite              |
-- |---------------|---------------------|---------------------|---------------------|--------------------|
-- | 分页语法        | LIMIT offset,count  | LIMIT/OFFSET         | FETCH FIRST N ROWS   | LIMIT offset,count |
-- | 去重            | DISTINCT            | DISTINCT             | DISTINCT             | DISTINCT           |
-- | 别名            | AS或空格             | AS或空格             | AS或空格              | AS或空格            |
-- | UNION          | UNION/UNION ALL      | UNION/UNION ALL      | UNION/UNION ALL      | UNION/UNION ALL    |
-- | 别名限制        | MySQL允许在GROUP BY中使用SELECT别名 | 不允许（标准SQL） | 不允许              | 不允许             |
-- | TOP N          | LIMIT N             | LIMIT N              | FETCH FIRST N ROWS ONLY | LIMIT N           |
-- | OFFSET          | OFFSET M            | OFFSET M             | OFFSET M ROWS        | OFFSET M           |
-- | 空字符串排序     | 排在最前(ASC)        | 排在最前(ASC)         | 排在最前(ASC)         | 排在最前(ASC)       |
-- | NULLS FIRST    | 不支持（用IFNULL）   | 支持                  | 支持                  | 不支持              |

-- Oracle分页（标准SQL）：
-- SELECT * FROM t ORDER BY id OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;

-- PostgreSQL分页（兼容MySQL语法）：
-- SELECT * FROM t ORDER BY id LIMIT 10 OFFSET 20;

-- SQLite分页（同MySQL）：
-- SELECT * FROM t ORDER BY id LIMIT 10 OFFSET 20;

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 写一个查询，找出每个科目最高分的学生姓名和分数，
--    使用子查询（不用窗口函数），然后用窗口函数重写，对比代码量。

-- 2. 写一个分页查询：第3页，每页5条，按分数降序排列学生成绩表。
--    分别用LIMIT OFFSET语法和LIMIT offset,count语法实现。

-- 3. 用DISTINCT统计t_score表中一共有多少个不同的科目（subject），
--    再用COUNT(DISTINCT subject)实现，对比两者结果。

-- 4. 构造一个UNION和UNION ALL的对比查询：有一张学生表和一张教师表，
--    用UNION和UNION ALL分别合并两表的姓名列，观察去重差异。

-- 5. 验证SQL执行顺序：写一个包含WHERE、GROUP BY、HAVING、SELECT别名、ORDER BY的复杂查询，
--    证明ORDER BY可以使用SELECT别名（因为ORDER BY最后执行）。
