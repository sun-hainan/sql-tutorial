-- ================================================================
-- 模块十八：锁与权限
-- ================================================================

-- Q1: 锁的级别有哪些？全局锁、表级锁、行级锁的区别？

-- 【解答】
-- 全局锁：锁整个数据库实例，所有表
-- 表级锁：锁整张表
-- 行级锁：锁表中特定行（InnoDB支持）

-- 【原理】
-- 全局锁：用于全库备份，MySQL使用 FLUSH TABLES WITH READ LOCK。
-- 表级锁：MyISAM和InnoDB都支持，开销小但粒度粗。
-- 行级锁：只有InnoDB支持，开销大但粒度细，锁住特定行。
-- InnoDB行锁实际锁住的是索引项，不是行数据本身。

-- 【示例】
DROP DATABASE IF EXISTS lock_demo;
CREATE DATABASE lock_demo;
USE lock_demo;

CREATE TABLE t_account (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    balance DECIMAL(10,2)
) ENGINE = InnoDB;
INSERT INTO t_account VALUES (1, 'Alice', 10000), (2, 'Bob', 5000);

-- 表级锁（InnoDB也支持，但主要是MyISAM）
LOCK TABLE t_account READ;  -- 读锁，其他会话只能读
-- 其他会话执行：SELECT * FROM t_account;  -- 可以读
-- 其他会话执行：INSERT INTO t_account VALUES (3, 'Carol', 3000);  -- 等待锁

UNLOCK TABLES;

LOCK TABLE t_account WRITE;  -- 写锁，独占
-- 其他会话无法读写

UNLOCK TABLES;

-- ================================================================
-- Q2: InnoDB的行级锁有哪些类型？

-- 【解答】
-- 记录锁（Record Lock）：锁住索引记录
-- 间隙锁（Gap Lock）：锁住索引之间的间隙
-- 临键锁（Next-Key Lock）：记录锁+间隙锁的组合
-- 插入意向锁（Insert Intention Lock）：插入操作前在间隙加的锁

-- 【原理】
-- InnoDB通过临键锁（Next-Key Lock）防止幻读。
-- 临键锁锁定：索引记录本身 + 索引之间的间隙。
-- 范围查询时会锁定一个范围的间隙。
-- 默认隔离级别REPEATABLE READ下，InnoDB使用临键锁。

-- 【示例】
USE lock_demo;

CREATE TABLE t_order (
    id INT PRIMARY KEY,
    status VARCHAR(20),
    INDEX idx_status (status)
);
INSERT INTO t_order VALUES (1, 'paid'), (3, 'paid'), (5, 'shipped'), (7, 'delivered');

-- 记录锁：锁定特定记录
-- SELECT * FROM t_order WHERE id = 3 FOR UPDATE;
-- 锁定 id=3 的索引记录，其他事务无法修改 id=3

-- 间隙锁：锁定id在1和3之间的间隙（id为2的位置）
-- SELECT * FROM t_order WHERE id > 1 AND id < 5 FOR UPDATE;
-- 锁住 id IN (2, 4) 的间隙

-- 临键锁：记录锁 + 间隙锁
-- SELECT * FROM t_order WHERE id >= 1 AND id <= 5 FOR UPDATE;
-- 锁住 id=1,3,5 以及它们之间的间隙

-- ================================================================
-- Q3: 共享锁和排他锁的区别？

-- 【解答】
-- 共享锁（S锁）：读锁，多个事务可以同时持有
-- 排他锁（X锁）：写锁，独占锁，其他事务不能持有

-- 【原理】
-- S锁与S锁兼容，X锁与任何锁都不兼容。
-- 读取数据时用S锁允许其他读，修改数据时需要X锁。
-- 悲观锁：使用SELECT ... FOR UPDATE获取排他锁。
-- 乐观锁：通过版本号字段实现，不阻塞操作。

-- 【示例】
USE lock_demo;

-- 共享锁
-- Session 1:
START TRANSACTION;
SELECT * FROM t_account WHERE id = 1 LOCK IN SHARE MODE;
-- Session 2:
START TRANSACTION;
SELECT * FROM t_account WHERE id = 1 LOCK IN SHARE MODE;  -- 可以获取，多个S锁共存

-- 排他锁
-- Session 1:
START TRANSACTION;
SELECT * FROM t_account WHERE id = 1 FOR UPDATE;  -- 获取X锁
-- Session 2:
START TRANSACTION;
SELECT * FROM t_account WHERE id = 1 FOR UPDATE;  -- 等待，X锁冲突
-- Session 2:
START TRANSACTION;
SELECT * FROM t_account WHERE id = 1 LOCK IN SHARE MODE;  -- 也等待，X锁与S锁冲突

-- ================================================================
-- Q4: 悲观锁和乐观锁是什么？如何实现？

-- 【解答】
-- 悲观锁：假设并发冲突频繁，先加锁再操作（SELECT FOR UPDATE）
-- 乐观锁：假设并发冲突少，不加锁，通过版本号检查冲突（CASE WHEN version = old_version）

-- 【原理】
-- 悲观锁：适合写多场景，阻塞等待，保证数据一致性。
-- 乐观锁：适合读多写少场景，不阻塞，发现冲突后重试或报错。
-- 乐观锁实现：表加version列，更新时检查version是否变化。

-- 【示例】
USE lock_demo;

-- 悲观锁实现
CREATE TABLE t_inventory (
    product_id INT PRIMARY KEY,
    stock INT,
    version INT DEFAULT 1
);
INSERT INTO t_inventory VALUES (1, 100, 1);

-- 悲观锁：扣库存
START TRANSACTION;
SELECT stock FROM t_inventory WHERE product_id = 1 FOR UPDATE;
-- 假设查到stock=100
UPDATE t_inventory SET stock = stock - 1 WHERE product_id = 1;
COMMIT;
-- 其他事务尝试获取product_id=1的行锁时会被阻塞

-- 乐观锁实现：更新时检查version
START TRANSACTION;
UPDATE t_inventory
SET stock = stock - 1, version = version + 1
WHERE product_id = 1 AND version = 1;
-- 成功返回1行受影响
-- 如果version不匹配（已被其他事务更新），返回0行，更新失败

-- 乐观锁检查（应用层逻辑）
START TRANSACTION;
SELECT stock, version FROM t_inventory WHERE product_id = 1;
-- 应用层：检查stock是否足够，然后更新
UPDATE t_inventory
SET stock = stock - 1, version = version + 1
WHERE product_id = 1 AND version = @old_version;
-- 检查affected_rows，如果为0则说明有并发冲突，需要重试

-- ================================================================
-- Q5: 锁等待和死锁是什么？如何处理？

-- 【解答】
-- 锁等待：事务A持有锁，事务B等待A释放锁
-- 死锁：两个或多个事务相互等待对方持有的锁，形成循环等待

-- 【原理】
-- 锁等待：innodb_lock_wait_timeout控制等待超时（默认50秒）。
-- 死锁：InnoDB有死锁检测机制，会自动回滚代价最小的事务。
-- 解决死锁：业务层重试、设计优化（按固定顺序访问资源）。

-- 【示例】
USE lock_demo;

-- 死锁演示（两个事务互相等待）
-- Session 1:
START TRANSACTION;
UPDATE t_account SET balance = balance - 100 WHERE id = 1;  -- 锁定id=1
-- Session 2:
START TRANSACTION;
UPDATE t_account SET balance = balance - 100 WHERE id = 2;  -- 锁定id=2
-- Session 1:
UPDATE t_account SET balance = balance + 100 WHERE id = 2;  -- 等待id=2的锁
-- Session 2:
UPDATE t_account SET balance = balance + 100 WHERE id = 1;  -- 死锁！等待id=1的锁，而id=1已被Session 1持有
-- InnoDB检测到死锁，回滚其中一个事务

-- 查看死锁信息
SHOW ENGINE INNODB STATUS;

-- 避免死锁的方法
-- 1. 按固定顺序访问资源（所有事务都先访问id小的）
-- 2. 减少事务持有锁的时间
-- 3. 使用低隔离级别（但可能产生其他问题）

-- ================================================================
-- Q6: MySQL的权限系统是什么？GRANT和REVOKE如何使用？

-- 【解答】
-- 权限系统：基于用户+主机的访问控制，存放在mysql库中
-- GRANT：授予权限
-- REVOKE：撤销权限

-- 【原理】
-- MySQL权限存储在mysql.user、mysql.db、mysql.tables_priv等表。
-- 权限检查顺序：user表 → db表 → tables_priv → columns_priv。
-- 最小权限原则：只授予完成任务所需的最小权限。
-- 创建用户和授权是两个独立操作（部分MySQL版本支持组合语法）。

-- 【示例】
-- -- 创建用户
-- CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'StrongPwd123!';
-- CREATE USER 'report_user'@'%' IDENTIFIED BY 'ReadOnlyPwd456!';

-- -- 授予全局权限
-- GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'localhost';
-- GRANT SELECT ON *.* TO 'report_user'@'%';

-- -- 授予数据库级权限
-- GRANT SELECT, INSERT, UPDATE, DELETE ON sql_demo.* TO 'app_user'@'localhost';

-- -- 授予表级权限
-- GRANT SELECT, INSERT ON sql_demo.t_order TO 'app_user'@'localhost';
-- GRANT SELECT ON sql_demo.t_order TO 'report_user'@'%';

-- -- 授予列级权限（只能INSERT/SUPDATE特定列）
-- GRANT SELECT, UPDATE(phone, email) ON sql_demo.t_user TO 'app_user'@'localhost';

-- -- 撤销权限
-- REVOKE DELETE ON sql_demo.* FROM 'app_user'@'localhost';

-- -- 查看权限
-- SHOW GRANTS FOR 'app_user'@'localhost';
-- SHOW GRANTS FOR 'report_user'@'%';

-- -- 删除用户
-- DROP USER 'app_user'@'localhost';
-- DROP USER 'report_user'@'%';

-- ================================================================
-- Q7: 如何进行数据库备份和恢复？

-- 【解答】
-- 备份工具：mysqldump（逻辑备份）、mysqlpump、xtrabackup（物理备份）
-- 恢复：source命令或mysql < backup.sql

-- 【原理】
-- mysqldump：导出SQL语句，速度慢但可跨版本恢复。
-- xtrabackup：物理备份，锁定少，恢复快，但备份文件大。
-- 备份策略：全量备份 + 增量备份 + binlog备份。

-- 【示例】
-- 备份单个数据库
-- mysqldump -u root -p database_name > backup.sql

-- 备份多个数据库
-- mysqldump -u root -p --databases db1 db2 db3 > multi_backup.sql

-- 备份所有数据库
-- mysqldump -u root -p --all-databases > all_backup.sql

-- 备份指定表
-- mysqldump -u root -p database_name table1 table2 > tables_backup.sql

-- 带数据的备份（不加--no-data）
-- mysqldump -u root -p database_name > backup_with_data.sql

-- 只备份结构（不加数据）
-- mysqldump -u root -p --no-data database_name > structure_backup.sql

-- 恢复数据库
-- mysql -u root -p database_name < backup.sql

--  SOURCE命令恢复（登录MySQL后）
-- USE database_name;
-- SOURCE /path/to/backup.sql;

-- ================================================================
-- Q8: binlog是什么？如何使用binlog恢复数据？

-- 【解答】
-- binlog（Binary Log）：记录所有修改数据的SQL语句，用于数据恢复和主从复制

-- 【原理】
-- binlog记录：INSERT/UPDATE/DELETE等修改数据的语句。
-- 恢复场景：恢复到某个时间点或某个位置。
-- 配合全量备份，可以精确恢复到任意时间点。

-- 【示例】
-- 查看binlog配置
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';

-- 查看binlog文件列表
SHOW BINARY LOGS;
SHOW MASTER STATUS;

-- 查看binlog内容（事件级别）
SHOW BINLOG EVENTS IN 'binlog.000001' FROM 1;

-- 使用mysqlbinlog工具查看内容
-- mysqlbinlog binlog.000001 --start-position=100 --stop-position=500

-- 基于时间点恢复
-- 1. 找到需要恢复的时间点前的一个binlog位置
-- 2. 执行：mysqlbinlog binlog.000001 --stop-datetime='2024-01-15 10:00:00' | mysql -u root -p

-- 基于位置恢复
-- mysqlbinlog binlog.000001 --start-position=100 --stop-position=500 | mysql -u root -p

-- 主从复制配置
-- 主库：SHOW MASTER STATUS;  -- 获取binlog文件名和位置
-- 从库：CHANGE MASTER TO MASTER_HOST='master_host', MASTER_USER='repl_user', MASTER_PASSWORD='pwd', MASTER_LOG_FILE='binlog.000001', MASTER_LOG_POS=123;
-- 从库：START SLAVE;
