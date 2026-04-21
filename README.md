# SQL 专家教程 - 18 个模块

一套完整的 MySQL SQL 专家级教程，覆盖从数据库基础到高级优化的 18 个核心模块。

## 快速导航

| 模块 | 文件 | 核心内容 |
|------|------|----------|
| 1 | `01_数据库基础.md` | 数据库vs文件/RDBMS vs NoSQL/主键外键/三大范式/反范式 |
| 2 | `02_SQL五大分类.md` | DDL/DML/DQL/DCL/TCL 区别与关键字 |
| 3 | `03_数据库操作.md` | CREATE/USE/DROP/字符集/存储引擎 |
| 4 | `04_数据表操作.md` | CREATE/DROP/TRUNCATE/ALTER/表复制/临时表 |
| 5 | `05_数据类型.md` | 数值/字符串/日期/DATETIME vs TIMESTAMP/DECIMAL精度 |
| 6 | `06_六大约束.md` | PRIMARY KEY/UNIQUE/NOT NULL/DEFAULT/FOREIGN KEY/CHECK |
| 7 | `07_增删改数据.md` | INSERT/UPDATE/DELETE/批量插入/逻辑删除/Upsert |
| 8 | `08_查询基础.md` | SELECT执行顺序/WHERE/ORDER BY/DISTINCT/UNION/子查询 |
| 9 | `09_聚合与分组.md` | COUNT/SUM/AVG/MAX/MIN/GROUP BY/HAVING/窗口函数 |
| 10 | `10_常用函数.md` | 字符串/数值/日期函数/IF/CASE WHEN/GROUP_CONCAT |
| 11 | `11_多表查询.md` | INNER/LEFT/RIGHT JOIN/子查询/IN/EXISTS/自连接 |
| 12 | `12_视图.md` | CREATE VIEW/可更新视图/WITH CHECK OPTION |
| 13 | `13_存储过程与函数.md` | PROCEDURE/FUNCTION/游标/变量/条件/循环 |
| 14 | `14_触发器.md` | TRIGGER/NEW OLD引用/审计/数据联动 |
| 15 | `15_事务管理.md` | ACID/隔离级别/脏读/不可重复读/幻读/MVCC |
| 16 | `16_索引.md` | 索引分类/聚簇非聚簇/B+树/最左前缀/回表/覆盖索引 |
| 17 | `17_SQL优化.md` | EXPLAIN/慢查询/分页优化/优化技巧 |
| 18 | `18_锁与权限.md` | 全局锁/行级锁/共享锁排他锁/悲观锁乐观锁/GRANT |

## 学习路线图

```
第一阶段（模块1-4）：入门基础 → 数据库概念/SQL分类/数据库操作/表操作
第二阶段（模块5-8）：核心技能 → 数据类型/约束/DML/查询基础
第三阶段（模块9-11）：提升进阶 → 聚合分组/常用函数/多表查询
第四阶段（模块12-15）：高级特性 → 视图/存储过程/触发器/事务
第五阶段（模块16-18）：性能与安全 → 索引/SQL优化/锁与权限
```

## SELECT 执行顺序

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

## 适用人群

- 数据库初学者、后端开发者、数据分析师
- 面试备考学生、DBA 入门、全栈工程师

## 快速开始

```bash
git clone https://github.com/sun-hainan/sql-tutorial.git
cd sql-tutorial
mysql -u root -p
source 01_数据库基础.md
```

> **注意**：所有 `.md` 文件为中文 Markdown 教程，`.sql` 源文件已移至 `_src/` 目录。

## 源文件

原始 `.sql` 文件位于 `_src/` 目录，供直接在 MySQL 中执行。

## 推荐版本

MySQL 8.0+（支持窗口函数、CTE 等新特性）

## 许可证

MIT License
