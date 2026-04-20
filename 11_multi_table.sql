-- ================================================================
-- 模块十一：多表查询
-- ================================================================

-- Q1: 表与表之间有哪些关系类型？

-- 【解答】
-- 一对一（1:1）：一个表的一条记录对应另一个表的一条记录
-- 一对多（1:N）：一个表的一条记录对应另一个表的多条记录
-- 多对多（M:N）：通过中间表建立多对多关系

-- 【原理】
-- 1:1关系：主键关联（如用户表和用户详情表）或外键唯一约束
-- 1:N关系：外键不加唯一约束（如部门和员工）
-- M:N关系：引入中间表（如学生和课程通过选课表关联）

-- 【示例】
DROP DATABASE IF EXISTS multi_table_demo;
CREATE DATABASE multi_table_demo;
USE multi_table_demo;

-- 一对一关系：用户表和用户详情表（主键关联）
CREATE TABLE t_user (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50)
);
CREATE TABLE t_user_profile (
    user_id INT PRIMARY KEY,
    real_name VARCHAR(50),
    phone VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES t_user(user_id)
);
INSERT INTO t_user VALUES (1, 'alice'), (2, 'bob');
INSERT INTO t_user_profile VALUES (1, 'Alice Smith', '13812345678'), (2, 'Bob Wang', '13998765432');

-- 一对多关系：部门和员工
CREATE TABLE t_dept (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
CREATE TABLE t_emp (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES t_dept(dept_id)
);
INSERT INTO t_dept VALUES (1, 'IT'), (2, 'HR');
INSERT INTO t_emp VALUES (1, 'Alice', 1), (2, 'Bob', 1), (3, 'Carol', 2);

-- 多对多关系：学生和课程（通过选课表关联）
CREATE TABLE t_student (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50)
);
CREATE TABLE t_course (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50)
);
CREATE TABLE t_enrollment (
    student_id INT,
    course_id INT,
    grade DECIMAL(4,1),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES t_student(student_id),
    FOREIGN KEY (course_id) REFERENCES t_course(course_id)
);
INSERT INTO t_student VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Carol');
INSERT INTO t_course VALUES (101, 'Math'), (102, 'English'), (103, 'Physics');
INSERT INTO t_enrollment VALUES (1, 101, 85), (1, 102, 90), (2, 101, 78), (2, 103, 92), (3, 102, 88);

-- ================================================================
-- Q2: INNER JOIN的原理和使用场景？

-- 【解答】
-- INNER JOIN：返回两表中连接条件匹配的行
-- 只保留两表都满足条件的记录，一表有另一表没有的记录被丢弃

-- 【原理】
-- INNER JOIN = FROM A INNER JOIN B ON condition
-- 相当于 WHERE col IN (SELECT col FROM B) 的效果
-- 驱动表：小表放左边（被驱动表在右边）
-- 连接条件通常使用主键-外键

-- 【示例】
USE multi_table_demo;

-- 基础INNER JOIN
SELECT e.emp_name, d.dept_name
FROM t_emp e
INNER JOIN t_dept d ON e.dept_id = d.dept_id;

-- 多表INNER JOIN
SELECT e.emp_name, d.dept_name, p.real_name, p.phone
FROM t_emp e
INNER JOIN t_dept d ON e.dept_id = d.dept_id
INNER JOIN t_user u ON e.emp_name = u.username
INNER JOIN t_user_profile p ON u.user_id = p.user_id;

-- INNER JOIN等价于隐式连接（逗号连接+WHERE）
SELECT e.emp_name, d.dept_name
FROM t_emp e, t_dept d
WHERE e.dept_id = d.dept_id;  -- 效果等同于INNER JOIN

-- 场景：查询选课学生信息和课程信息
SELECT s.student_name, c.course_name, e.grade
FROM t_student s
INNER JOIN t_enrollment e ON s.student_id = e.student_id
INNER JOIN t_course c ON e.course_id = c.course_id;

-- ================================================================
-- Q3: LEFT JOIN和RIGHT JOIN的区别和使用场景？

-- 【解答】
-- LEFT JOIN：返回左表所有行，右表不匹配的行显示NULL
-- RIGHT JOIN：返回右表所有行，左表不匹配的行显示NULL

-- 【原理】
-- LEFT JOIN：左表是驱动表，即使右表没有匹配，也返回左表所有行
-- RIGHT JOIN：右表是驱动表，即使左表没有匹配，也返回右表所有行
-- 实际开发中，LEFT JOIN更常用（右表无数据用NULL填充表示"无"）

-- 【示例】
USE multi_table_demo;

-- LEFT JOIN：所有部门，包括没有员工的部门
INSERT INTO t_dept VALUES (3, 'Marketing');  -- 插入一个没有员工的部门

SELECT d.dept_name, e.emp_name
FROM t_dept d
LEFT JOIN t_emp e ON d.dept_id = e.dept_id;
-- IT部门有Alice和Bob，HR部门有Carol，Marketing部门显示NULL（没有员工）

-- RIGHT JOIN：所有员工，包括没有部门的员工（理论上不应该有）
SELECT e.emp_name, d.dept_name
FROM t_emp e
RIGHT JOIN t_dept d ON e.dept_id = d.dept_id;

-- 场景：统计每个部门的员工数量（包含0个员工的部门）
SELECT d.dept_name, COUNT(e.emp_id) AS emp_count
FROM t_dept d
LEFT JOIN t_emp e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;
-- IT=2, HR=1, Marketing=0

-- LEFT JOIN + WHERE过滤右表为NULL（查找没有员工的部门）
SELECT d.dept_name
FROM t_dept d
LEFT JOIN t_emp e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;

-- ================================================================
-- Q4: 多表连接查询的注意事项？

-- 【解答】
-- 注意别名使用、连接条件完整性、N+1问题、连接顺序

-- 【原理】
-- 1. 每张表用别名，简化长表名引用
-- 2. 确保ON条件覆盖所有外键关系，避免笛卡尔积
-- 3. 多表JOIN时注意执行顺序，驱动表选择小表
-- 4. ON vs WHERE：ON决定连接，WHERE决定过滤

-- 【示例】
USE multi_table_demo;

-- 多表JOIN示例
SELECT
    s.student_name,
    c.course_name,
    e.grade,
    d.dept_name
FROM t_student s
INNER JOIN t_enrollment e ON s.student_id = e.student_id
INNER JOIN t_course c ON e.course_id = c.course_id
INNER JOIN t_emp emp ON s.student_name = emp.emp_name
INNER JOIN t_dept d ON emp.dept_id = d.dept_id
WHERE e.grade >= 80
ORDER BY e.grade DESC;

-- ON vs WHERE的区别
INSERT INTO t_dept VALUES (4, 'Finance');
INSERT INTO t_emp VALUES (4, 'David', NULL);  -- David没有部门

-- ON：连接时不管dept_id是否为NULL
SELECT e.emp_name, d.dept_name
FROM t_emp e
LEFT JOIN t_dept d ON e.dept_id = d.dept_id;  -- David显示NULL

-- WHERE：过滤掉不匹配的行
SELECT e.emp_name, d.dept_name
FROM t_emp e
LEFT JOIN t_dept d ON e.dept_id = d.dept_id
WHERE d.dept_name IS NOT NULL;  -- David被过滤掉了（因为dept_id=NULL，ON不会匹配）

-- ================================================================
-- Q5: 子查询在多表查询中的应用？

-- 【解答】
-- 子查询可以嵌套在WHERE、FROM、SELECT中
-- 标量子查询、列子查询、行子查询、表子查询

-- 【原理】
-- 子查询先于外层查询执行，返回结果供外层使用。
-- WHERE中的子查询作为条件：IN/EXISTS/比较运算符
-- FROM中的子查询作为临时表（必须给子查询起别名）

-- 【示例】
USE multi_table_demo;

-- 场景1：查找选了Math课程的学生
SELECT s.student_name
FROM t_student s
WHERE s.student_id IN (
    SELECT course_id FROM t_course WHERE course_name = 'Math'
);

-- 场景2：查找分数高于平均分的学生
SELECT s.student_name, e.grade
FROM t_student s
INNER JOIN t_enrollment e ON s.student_id = e.student_id
WHERE e.grade > (SELECT AVG(grade) FROM t_enrollment);

-- 场景3：查找每个学生最高分的课程
SELECT s.student_name, c.course_name, e.grade
FROM t_student s
INNER JOIN t_enrollment e ON s.student_id = e.student_id
INNER JOIN t_course c ON e.course_id = c.course_id
WHERE e.grade = (
    SELECT MAX(grade) FROM t_enrollment WHERE student_id = s.student_id
);

-- 场景4：查找选了3门课以上的学生
SELECT s.student_name, COUNT(e.course_id) AS course_count
FROM t_student s
INNER JOIN t_enrollment e ON s.student_id = e.student_id
GROUP BY s.student_id, s.student_name
HAVING COUNT(e.course_id) > 1;

-- 场景5：FROM子查询（派生表）
SELECT avg_stats.grade_level, COUNT(*) AS student_count
FROM (
    SELECT s.student_name, AVG(e.grade) AS avg_grade,
        CASE
            WHEN AVG(e.grade) >= 90 THEN 'A'
            WHEN AVG(e.grade) >= 80 THEN 'B'
            ELSE 'C'
        END AS grade_level
    FROM t_student s
    INNER JOIN t_enrollment e ON s.student_id = e.student_id
    GROUP BY s.student_id, s.student_name
) AS avg_stats
GROUP BY avg_stats.grade_level;

-- ================================================================
-- Q6: IN和EXISTS的区别？如何选择？

-- 【解答】
-- IN：检查值是否在列表中，列表通常来自子查询
-- EXISTS：检查是否存在满足条件的记录（不返回具体值，只返回true/false）

-- 【原理】
-- IN：先执行子查询得到列表，再在外层查询中匹配。列表大时性能下降。
-- EXISTS：对外层每一行，检查内层是否有匹配。子查询小、外层大时更高效。
-- NOT IN vs NOT EXISTS：NOT EXISTS性能通常更好（能利用索引）。

-- 【示例】
USE multi_table_demo;

-- IN：查找选了Math或English的学生
SELECT s.student_name
FROM t_student s
WHERE s.student_id IN (
    SELECT course_id FROM t_course WHERE course_name IN ('Math', 'English')
);

-- EXISTS：查找选了课程的学生（只看是否存在）
SELECT s.student_name
FROM t_student s
WHERE EXISTS (
    SELECT 1 FROM t_enrollment e WHERE e.student_id = s.student_id
);

-- IN vs EXISTS 对比（等价查询）
-- 查找选了Math课程的学生
SELECT s.student_name
FROM t_student s
WHERE s.student_id IN (
    SELECT e.student_id FROM t_enrollment e
    INNER JOIN t_course c ON e.course_id = c.course_id
    WHERE c.course_name = 'Math'
);

SELECT s.student_name
FROM t_student s
WHERE EXISTS (
    SELECT 1 FROM t_enrollment e
    INNER JOIN t_course c ON e.course_id = c.course_id
    WHERE c.course_name = 'Math' AND e.student_id = s.student_id
);

-- NOT IN vs NOT EXISTS
-- 查找没选任何课的学生
SELECT s.student_name
FROM t_student s
WHERE s.student_id NOT IN (
    SELECT DISTINCT student_id FROM t_enrollment
);

SELECT s.student_name
FROM t_student s
WHERE NOT EXISTS (
    SELECT 1 FROM t_enrollment e WHERE e.student_id = s.student_id
);

-- ================================================================
-- Q7: 自连接的原理和应用场景？

-- 【解答】
-- 自连接：一个表与自己进行连接，本质是多行记录之间的关联
-- 典型场景：员工表（上级领导）、分类表（父类子类）、好友关系

-- 【原理】
-- 自连接需要给表起两个不同的别名，才能区分同一表的不同实例。
-- 自连接可以把树形结构展开为扁平结构。
-- 注意不要遗漏连接条件，否则产生笛卡尔积。

-- 【示例】
USE multi_table_demo;

-- 员工表（含上级领导ID）
CREATE TABLE t_employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    manager_id INT,
    salary DECIMAL(10,2)
);
INSERT INTO t_employee VALUES
    (1, 'CEO Zhang', NULL, 100000.00),
    (2, 'VP Wang', 1, 80000.00),
    (3, 'VP Li', 1, 80000.00),
    (4, 'Manager Chen', 2, 50000.00),
    (5, 'Manager Wu', 3, 50000.00),
    (6, 'Staff Sun', 4, 30000.00),
    (7, 'Staff Zhao', 5, 30000.00);

-- 场景1：查询每个员工及其上级名字
SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM t_employee e
LEFT JOIN t_employee m ON e.manager_id = m.emp_id;

-- 场景2：查询Staff及其直属上级
SELECT
    e.emp_name AS staff,
    m.emp_name AS manager
FROM t_employee e
INNER JOIN t_employee m ON e.manager_id = m.emp_id;

-- 场景3：查询每个经理的下属数量
SELECT
    m.emp_name AS manager,
    COUNT(e.emp_id) AS subordinate_count
FROM t_employee e
INNER JOIN t_employee m ON e.manager_id = m.emp_id
GROUP BY m.emp_id, m.emp_name;

-- 场景4：查询所有层级关系（CEO → VP → Manager → Staff）
SELECT
    L1.emp_name AS level1,
    L2.emp_name AS level2,
    L3.emp_name AS level3,
    L4.emp_name AS level4
FROM t_employee L1
LEFT JOIN t_employee L2 ON L2.manager_id = L1.emp_id
LEFT JOIN t_employee L3 ON L3.manager_id = L2.emp_id
LEFT JOIN t_employee L4 ON L4.manager_id = L3.emp_id
WHERE L1.manager_id IS NULL;  -- 从CEO开始

-- 场景5：分类表自连接（树形结构）
CREATE TABLE t_category (
    cat_id INT PRIMARY KEY,
    cat_name VARCHAR(50),
    parent_id INT,
    FOREIGN KEY (parent_id) REFERENCES t_category(cat_id)
);
INSERT INTO t_category VALUES
    (1, 'Electronics', NULL),
    (2, 'Computers', 1),
    (3, 'Phones', 1),
    (4, 'Laptops', 2),
    (5, 'Desktops', 2),
    (6, 'Smartphones', 3);

-- 查询每个分类及其父分类
SELECT
    c.cat_name AS category,
    p.cat_name AS parent_category
FROM t_category c
LEFT JOIN t_category p ON c.parent_id = p.cat_id;
