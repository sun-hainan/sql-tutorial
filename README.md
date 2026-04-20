# SQL专家教程 - 18个模块

## 教程概述

这是一套完整的SQL专家级教程，覆盖从数据库基础到高级优化的18个核心模块。每个模块都配有可运行的MySQL SQL脚本，通过问题驱动的学习方式，深入讲解每个知识点。

## 教程结构

```
模块一   → 数据库基础认知
模块二   → SQL五大语言分类（DDL/DML/DQL/DCL/TCL）
模块三   → 数据库操作
模块四   → 数据表操作
模块五   → 数据类型
模块六   → 六大约束
模块七   → 增删改数据
模块八   → 查询基础
模块九   → 聚合与分组
模块十   → 常用函数
模块十一 → 多表查询
模块十二 → 视图
模块十三 → 存储过程与函数
模块十四 → 触发器
模块十五 → 事务管理
模块十六 → 索引
模块十七 → SQL优化
模块十八 → 锁与权限
```

## 文件清单

| 文件 | 模块 | 核心内容 |
|------|------|----------|
| `01_database_basics.sql` | 模块一 | 数据库vs文件/关系型vs非关系型/SQL是什么/主键外键/三大范式/反范式 |
| `02_sql分类.sql` | 模块二 | DDL/DML/DQL/DCL/TCL区别与关键字 |
| `03_database_ops.sql` | 模块三 | CREATE/USE/DROP/SHOW/字符集/排序规则 |
| `04_table_ops.sql` | 模块四 | CREATE/DROP/TRUNCATE/ALTER/数据类型选择/表复制 |
| `05_data_types.sql` | 模块五 | 数值型/字符串/日期时间/DATETIME vs TIMESTAMP |
| `06_constraints.sql` | 模块六 | PRIMARY KEY/UNIQUE/NOT NULL/DEFAULT/FOREIGN KEY/CHECK |
| `07_dml.sql` | 模块七 | INSERT/UPDATE/DELETE/批量插入/逻辑删除 |
| `08_select_basics.sql` | 模块八 | SELECT执行顺序/FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER BY→LIMIT |
| `09_aggregation_groupby.sql` | 模块九 | COUNT/SUM/AVG/MAX/MIN/GROUP BY/HAVING/排序分页 |
| `10_functions.sql` | 模块十 | 字符串函数/CONCAT/SUBSTRING/数值函数/日期函数/DATE_FORMAT/流程IF/CASE WHEN |
| `11_multi_table.sql` | 模块十一 | 表关系/INNER JOIN/LEFT JOIN/RIGHT JOIN/子查询/IN/EXISTS |
| `12_views.sql` | 模块十二 | CREATE VIEW/可更新视图/WITH CHECK OPTION/简化查询/安全保障 |
| `13_procedures_functions.sql` | 模块十三 | PROCEDURE/FUNCTION/游标CURSOR/变量/条件/循环 |
| `14_triggers.sql` | 模块十四 | CREATE TRIGGER/NEW OLD引用/数据联动/审计/性能影响 |
| `15_transaction.sql` | 模块十五 | ACID/并发问题脏读不可重复读幻读/四大隔离级别/事务控制/MVCC预览 |
| `16_indexes.sql` | 模块十六 | 索引分类/聚簇非聚簇/B+树原理/最左前缀/回表/覆盖索引/索引失效场景 |
| `17_optimization.sql` | 模块十七 | EXPLAIN执行计划/type性能排序/慢查询日志/优化技巧/避免SELECT*/分页优化 |
| `18_locks_permissions.sql` | 模块十八 | 全局锁表级锁行级锁/共享锁排他锁/InnoDB记录锁间隙锁临键锁/悲观锁乐观锁/GRANT REVOKE/备份恢复/binlog |

## 适用人群

- **数据库初学者**：从零建立知识体系，理解关系型数据库核心概念
- **后端开发者**：掌握SQL核心技能，能够编写复杂查询和优化语句
- **数据分析师**：提升查询效率，掌握聚合、分组、多表关联技巧
- **面试备考学生**：覆盖高频面试题（索引、事务、优化、锁机制）
- **DBA入门**：夯实理论基础，理解InnoDB存储引擎、锁机制、备份恢复
- **全栈工程师**：前后端都需要的通用技能

## SQL执行顺序

SQL语句的实际执行顺序（从上到下）：

```sql
SELECT DISTINCT TOP(3) column_name AS alias_name,
       aggregate_func(column)
FROM table_name
JOIN another_table ON condition
WHERE condition
GROUP BY column_name
HAVING aggregate_condition
ORDER BY column_name ASC/DESC
```

**实际执行顺序：**

```
① FROM       → 确定数据来源，加载表
② ON         → 处理JOIN条件
③ JOIN       → 拼接表
④ WHERE      → 过滤数据（此时还不知道聚合结果）
⑤ GROUP BY   → 分组
⑥ HAVING     → 过滤分组结果
⑦ SELECT     → 选取列，计算表达式和聚合函数
⑧ DISTINCT   → 去重
⑨ ORDER BY   → 排序
⑩ LIMIT/TOP  → 分页/限制行数
```

**重要结论：**
- `WHERE` 在 `GROUP BY` 之前执行，所以 WHERE 中不能使用聚合函数
- `HAVING` 在 `GROUP BY` 之后执行，所以 HAVING 中可以使用聚合函数
- `ORDER BY` 在 SELECT 之后执行，所以可以用 SELECT 的别名排序
- `WHERE` 先于 SELECT 执行，所以不能用 WHERE 过滤 SELECT 的别名

## MySQL特色总结

| 特性 | MySQL实现 |
|------|----------|
| 默认存储引擎 | InnoDB（5.5+），支持事务、行级锁、外键 |
| 字符串长度 | VARCHAR最大65535字节（utf8mb4约16000字符） |
| 字符集推荐 | utf8mb4（完整UTF-8，支持emoji） |
| 分页语法 | LIMIT offset, count（MySQL/PostgreSQL），TOP n（SQL Server） |
| 自增主键 | AUTO_INCREMENT（MySQL），SERIAL（PostgreSQL） |
| 批量插入 | INSERT INTO ... VALUES (...), (...), (...) |
| Upsert语法 | INSERT ... ON DUPLICATE KEY UPDATE |
| 递归查询 | 8.0+支持WITH RECURSIVE |
| 窗口函数 | 8.0+支持（ROW_NUMBER/RANK/LEAD/LAG等） |
| 公用表表达式 | 8.0+支持WITH CTE |
| CHECK约束 | 8.0.16+正式支持，之前版本忽略不报错 |
| 临时表 | CREATE TEMPORARY TABLE（会话级，断开自动删除） |
| 触发器 | 支持BEFORE/AFTER触发器 |
| 默认隔离级别 | REPEATABLE READ（InnoDB） |
| 全文索引 | InnoDB 5.6+支持，MyISAM更早支持 |

## 学习路线图

```
第一阶段：入门基础（模块1-4）
  模块一 → 了解数据库是什么、关系型vs非关系型
  模块二 → 理解SQL五大分类
  模块三 → 掌握数据库的创建、切换、删除
  模块四 → 掌握数据表创建、修改、删除

第二阶段：核心技能（模块5-8）
  模块五 → 掌握常用数据类型及选择原则
  模块六 → 理解六大约束，理解数据完整性
  模块七 → 掌握INSERT/UPDATE/DELETE
  模块八 → 掌握SELECT核心查询（WHERE/ORDER BY/DISTINCT/UNION）

第三阶段：提升进阶（模块9-11）
  模块九 → 聚合函数、GROUP BY、HAVING、窗口函数
  模块十 → 字符串/数值/日期函数、CASE WHEN
  模块十一 → 多表JOIN（INNER/LEFT/RIGHT）、子查询、IN/EXISTS

第四阶段：高级特性（模块12-15）
  模块十二 → 视图的创建、分类、WITH CHECK OPTION
  模块十三 → 存储过程、函数、游标
  模块十四 → 触发器（NEW/OLD引用、审计联动）
  模块十五 → 事务ACID、四大隔离级别、MVCC

第五阶段：性能与安全（模块16-18）
  模块十六 → 索引分类、B+树原理、最左前缀、回表、覆盖索引
  模块十七 → EXPLAIN执行计划分析、慢查询、分页优化
  模块十八 → 锁机制、权限GRANT/REVOKE、备份恢复、binlog
```

## 学习建议

1. **按顺序学习**：建议从模块一依次学习到模块十八
2. **动手实践**：每个SQL文件可直接在MySQL中执行，建议边学边练
3. **理解原理**：每个问题都有"解答+原理+示例"三部分
4. **重点掌握**：模块八（查询基础）、模块十六（索引）、模块十七（SQL优化）是面试高频考点

## 快速开始

### 1. 克隆仓库
```bash
git clone https://github.com/sun-hainan/sql-tutorial.git
cd sql-tutorial
```

### 2. 在MySQL中执行
```bash
mysql -u root -p
source 01_database_basics.sql
source 02_sql分类.sql
-- 依次执行其他模块...
```

### 3. 查看学习
```bash
# 每个文件结构：
-- === 模块X ===
-- Q1: 问题描述
-- 【解答】答案
-- 【原理】底层原理
-- 【示例】可运行的SQL代码
-- 【练习题】实践题目
```

## MySQL版本

- 推荐MySQL 8.0+（支持窗口函数、CTE等新特性）
- 部分内容兼容MySQL 5.7+

## 许可证

MIT License
