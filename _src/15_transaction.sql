-- ================================================================
-- 模块十五：事务管理
-- ================================================================

-- Q1: 事务的ACID特性是什么？

-- 【解答】
-- Atomicity（原子性）：事务是最小执行单元，要么全部成功，要么全部失败
-- Consistency（一致性）：事务前后数据库状态保持一致，满足所有约束
-- Isolation（隔离性）：并发事务之间相互隔离，互不干扰
-- Durability（持久性）：提交后的修改永久保存，即使系统崩溃也不丢失

-- 【原理】
-- 原子性：事务中的SQL要么全部COMMIT，要么全部ROLLBACK
-- 一致性：约束（主键、外键、UNIQUE、CHECK）必须在事务前后都满足
-- 隔离性：通过锁机制和MVCC实现，不同隔离级别有不同的隔离效果
-- 持久性：提交后数据写入redo log，即使数据库崩溃也能恢复

-- 【示例】
DROP DATABASE IF EXISTS transaction_demo;
CREATE DATABASE transaction_demo;
USE transaction_demo;

CREATE TABLE t_account (
    account_id INT PRIMARY KEY,
    account_name VARCHAR(50),
    balance DECIMAL(10,2)
);
INSERT INTO t_account VALUES (1, 'Alice', 10000), (2, 'Bob', 5000);

-- 转账场景演示原子性和一致性
START TRANSACTION;
UPDATE t_account SET balance = balance - 3000 WHERE account_id = 1;
UPDATE t_account SET balance = balance + 3000 WHERE account_id = 2;
COMMIT;

-- 验证：余额总和不变（一致性）
SELECT SUM(balance) AS total FROM t_account;  -- 15000，转账前后相等

-- 测试原子性：中间某一步失败，事务回滚
START TRANSACTION;
UPDATE t_account SET balance = balance - 5000 WHERE account_id = 1;
-- 模拟错误
-- UPDATE t_account SET balance = balance + 5000 WHERE account_id = 999;  -- 账户不存在会失败
ROLLBACK;

SELECT * FROM t_account;  -- Alice余额未变，说明事务回滚了

-- ================================================================
-- Q2: 并发环境下会产生哪些问题？

-- 【解答】
-- 脏读（Dirty Read）：读取到其他事务未提交的数据
-- 不可重复读（Non-repeatable Read）：同一事务中两次读取同一行，数据不一致
-- 幻读（Phantom Read）：同一事务中两次查询，结果集行数不同（因为有新数据被插入）

-- 【原理】
-- 脏读：其他事务的修改还未COMMIT，却被当前事务读取到
-- 不可重复读：其他事务修改并提交了数据，导致当前事务两次读取结果不同
-- 幻读：其他事务插入新数据，导致当前事务的查询结果多了几行
-- 核心区别：脏读读到的是"未提交"的修改，不可重复读和幻读读到的是"已提交"的修改

-- 【示例】
USE transaction_demo;

-- 模拟并发场景（需要两个会话）
-- Session 1:
START TRANSACTION;
UPDATE t_account SET balance = balance - 1000 WHERE account_id = 1;
-- 不COMMIT，此时balance还是旧值（假设是10000）

-- Session 2（在Session 1未提交时查询）：
-- SELECT balance FROM t_account WHERE account_id = 1;
-- 脏读：如果能读到Session 1的未提交修改（balance=9000），就是脏读
-- 正常情况：InnoDB默认隔离级别是REPEATABLE READ，不会脏读

-- 不可重复读示例：
-- Session 1:
START TRANSACTION;
SELECT balance FROM t_account WHERE account_id = 1;  -- 结果：10000
-- Session 2:
START TRANSACTION;
UPDATE t_account SET balance = 5000 WHERE account_id = 1;
COMMIT;
-- Session 1:
SELECT balance FROM t_account WHERE account_id = 1;  -- 结果：5000（同一事务中两次读取不同）
-- 这就是不可重复读

-- ================================================================
-- Q3: 四大隔离级别分别是什么？

-- 【解答】
-- READ UNCOMMITTED：最低级别，允许脏读（实际不用）
-- READ COMMITTED：防止脏读，允许不可重复读
-- REPEATABLE READ（MySQL默认）：防止脏读和不可重复读，允许幻读（InnoDB通过MVCC防止幻读）
-- SERIALIZABLE：最高级别，完全串行化，不允许任何并发问题

-- 【原理】
-- 隔离级别越高，性能越差，数据一致性越强。
-- MySQL InnoDB默认是REPEATABLE READ，通过MVCC和Next-Key Lock尽量减少幻读。
-- SERIALIZABLE会将所有读操作加锁，完全串行执行。

-- 【示例】
USE transaction_demo;

-- 查看当前会话隔离级别
SELECT @@transaction_isolation;
SELECT @@global.transaction_isolation;

-- 设置隔离级别（会话级）
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- 各个隔离级别的行为差异演示
CREATE TABLE t_counter (id INT PRIMARY KEY, value INT);
INSERT INTO t_counter VALUES (1, 0);

-- Session 1: REPEATABLE READ
-- START TRANSACTION;
-- SELECT * FROM t_counter;  -- (1, 0)

-- Session 2: 在Session 1事务中插入了新数据
-- START TRANSACTION;
-- INSERT INTO t_counter VALUES (2, 1);
-- COMMIT;

-- Session 1: 再次查询
-- SELECT * FROM t_counter;  -- (1, 0) 还是只有1条，这就是REPEATABLE READ防止幻读

-- 如果是READ COMMITTED，第二次会看到(2, 1)

-- ================================================================
-- Q4: START TRANSACTION、COMMIT、ROLLBACK的用法？

-- 【解答】
-- START TRANSACTION / BEGIN：开启事务
-- COMMIT：提交事务，使修改永久化
-- ROLLBACK：回滚事务，撤销所有修改
-- SAVEPOINT：设置保存点，支持部分回滚

-- 【原理】
-- 默认情况下，MySQL自动提交（每条SQL单独提交）。
-- 开启事务后，SQL进入手动模式，直到COMMIT或ROLLBACK。
-- SAVEPOINT可以设置多个，回滚到指定保存点不影响之前的修改。

-- 【示例】
USE transaction_demo;

-- 基础事务操作
START TRANSACTION;
INSERT INTO t_account VALUES (3, 'Carol', 3000);
COMMIT;

START TRANSACTION;
INSERT INTO t_account VALUES (4, 'David', 4000);
ROLLBACK;

SELECT * FROM t_account;  -- 只有Alice、Bob、Carol

-- SAVEPOINT演示
START TRANSACTION;
INSERT INTO t_account VALUES (5, 'Eve', 5000);
SAVEPOINT sp1;
INSERT INTO t_account VALUES (6, 'Frank', 6000);
SAVEPOINT sp2;
INSERT INTO t_account VALUES (7, 'Grace', 7000);

-- 回滚到sp2：Grace被撤销，但Eve和Frank还在
ROLLBACK TO SAVEPOINT sp2;

-- 再回滚到sp1：Frank也被撤销，只剩Eve
ROLLBACK TO SAVEPOINT sp1;

COMMIT;

SELECT * FROM t_account;  -- 应该有5条记录，Grace和Frank被回滚

-- ================================================================
-- Q5: 什么是MVCC？它如何提高并发性能？

-- 【解答】
-- MVCC（Multi-Version Concurrency Control）：多版本并发控制
-- 通过保存数据的历史版本，实现读写不阻塞，提高并发性能

-- 【原理】
-- InnoDB为每行数据存储两个隐藏列：DB_TRX_ID（最后修改事务ID）、DB_ROLL_PTR（回滚指针）
-- 每次修改时，数据行被复制到undo log，回滚指针指向undo log中的旧版本
-- 读操作根据事务开始的快照读取对应版本的数据
-- 使得读操作不会被写操作阻塞

-- 【示例】
USE transaction_demo;

-- MVCC工作原理（概念演示）
-- 假设初始数据：Alice balance=10000

-- Transaction A 开始（ID=100）
-- Transaction B 开始（ID=101）
-- Transaction A 修改：balance=9000（创建版本A1，undo指向原版本）
-- Transaction B 读：读到的仍是10000（旧版本，快照读）
-- Transaction A 提交
-- Transaction B 读：取决于隔离级别
--   READ COMMITTED：已提交版本，balance=9000
--   REPEATABLE READ：快照还在，balance=10000

-- 查看InnoDB行结构（通过information_schema）
-- SELECT * FROM information_schema.INNODB_TABLES;

-- ================================================================
-- Q6: MySQL如何保证事务的持久性？

-- 【解答】
-- Redo Log（重做日志）：记录已提交事务的修改，用于崩溃恢复
-- 写入流程：修改数据 → 写入redo log → COMMIT → 数据最终落盘

-- 【原理】
-- 数据修改时，先写redo log（顺序写，性能高），再修改数据页（随机写）。
-- 即使数据库崩溃，也可以通过redo log恢复已提交的事务。
-- Redo log是物理日志，记录的是"页"的修改。
-- Undo log用于回滚未提交的事务。

-- 【示例】
USE transaction_demo;

-- 查看redo log相关配置
SHOW VARIABLES LIKE 'innodb_log%';

-- Redo log工作流程演示
-- 1. START TRANSACTION
-- 2. UPDATE t_account SET balance = balance - 1000
-- 3. InnoDB先将修改写入redo log buffer
-- 4. COMMIT
-- 5. InnoDB将redo log buffer刷入磁盘
-- 6. 后台线程将数据页从buffer pool刷入磁盘
-- 即使步骤6之前数据库崩溃，redo log已刷盘，可以恢复

-- 查看事务日志
-- SHOW ENGINE INNODB STATUS;

-- ================================================================
-- Q7: 分布式事务是什么？XA事务的原理？

-- 【解答】
-- 分布式事务：跨多个数据库实例的事务，保证跨库操作的原子性
-- XA事务：使用两阶段提交（2PC）保证分布式事务一致性

-- 【原理】
-- 两阶段提交：
-- 1. Prepare阶段：协调者向所有参与者发送Prepare，每个参与者写redo log但不提交
-- 2. Commit阶段：所有参与者都成功后，协调者发送Commit，否则发送Rollback
-- MySQL通过XA Transactions规范支持分布式事务

-- 【示例】
-- MySQL XA事务语法
-- XA START 'transaction_id';          -- 开启XA事务
-- XA END 'transaction_id';            -- 结束事务语句
-- XA PREPARE 'transaction_id';         -- 准备阶段
-- XA COMMIT 'transaction_id';         -- 提交
-- XA ROLLBACK 'transaction_id';       -- 回滚

-- 全局事务示例（跨两个数据库）
-- XA START 'global_tx_1';
-- UPDATE db1.t_account SET balance = balance - 100;
-- UPDATE db2.t_account SET balance = balance + 100;
-- XA END 'global_tx_1';
-- XA PREPARE 'global_tx_1';
-- XA COMMIT 'global_tx_1';

-- 实际使用中，通常由应用服务器（如Java的JTA）或中间件（如ShardingSphere）处理

-- ================================================================
-- 【MySQL vs 其他数据库对比】
-- ================================================================
-- | 特性            | MySQL               | PostgreSQL           | Oracle              | SQLite              |
-- |---------------|---------------------|---------------------|---------------------|--------------------|
-- | 默认隔离级别    | REPEATABLE READ     | READ COMMITTED        | READ COMMITTED       | SERIALIZABLE        |
-- | MVCC支持        | InnoDB支持          | 支持                  | 支持                 | 不完全支持          |
-- | SAVEPOINT      | 支持                | 支持                  | 支持                 | 支持                |
-- | 事务控制语句    | START TRANSACTION   | BEGIN/BEGIN WORK     | COMMIT/ROLLBACK      | BEGIN/COMMIT        |
-- | 自动提交        | 默认ON              | 默认OFF（需显式COMMIT）| 默认OFF             | 默认ON              |
-- | 分布式事务      | XA事务              | 两阶段提交(2PC)        | ORA_TMFC/XA          | 不支持              |
-- | SELECT FOR UPDATE | 支持              | 支持                  | 支持                 | 支持                |
-- | SELECT LOCK IN SHARE MODE | 支持      | FOR UPDATE/SHARE     | FOR UPDATE           | 不支持              |
-- | 死锁检测        | InnoDB自动检测      | 自动检测               | 自动检测              | 不支持              |

-- PostgreSQL事务隔离级别：
-- READ COMMITTED（默认）：只能看到已提交的数据
-- REPEATABLE READ：MySQL的RR隔离级别
-- SERIALIZABLE：完全串行化
-- PostgreSQL没有REPEATABLE READ这个级别（用SNAPSHOT机制替代）

-- Oracle自动提交：
-- Oracle默认不自动提交（需显式COMMIT或DDL语句自动提交）
-- MySQL默认自动提交（除BEGIN/START TRANSACTION外每条SQL自动提交）
-- SQLite默认自动提交（事务以BEGIN开始，以COMMIT/ROLLBACK结束）

-- PostgreSQL/SQLite没有XA：
-- PostgreSQL用两阶段提交（PREPARE TRANSACTION + COMMIT/ROLLBACK PREPARED）
-- 需要pg_createlang等扩展支持

-- ================================================================
-- 【练习题】
-- ================================================================
-- 1. 开启事务：向账户表插入一条记录，然后设置SAVEPOINT，
--    再插入第二条记录并回滚到SAVEPOINT，最后COMMIT。
--    验证哪些记录被持久化。

-- 2. 模拟并发场景（需要两个会话窗口）：
--    会话A开启事务修改某行数据不提交，会话B尝试修改同一行，
--    观察会话B是被阻塞还是立即报错，说明原因。

-- 3. 查询当前会话和全局的隔离级别（SELECT @@transaction_isolation），
--    然后分别设置READ COMMITTED和SERIALIZABLE，
--    用BEGIN开启事务后查询数据，观察两者行为差异。

-- 4. 用ROLLBACK TO SAVEPOINT演示部分回滚：
--    在一个事务中依次插入3条记录，分别设置sp1和sp2两个保存点，
--    回滚到sp1后COMMIT，验证哪几条记录被保存。

-- 5. 用START TRANSACTION + COMMIT + ROLLBACK实现一个完整的转账事务：
--    账户A减100，账户B加100，验证转账前后两账户余额总和不变（一致性验证）。
