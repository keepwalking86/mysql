## 1. Troubleshooting Replication

Trong trường hợp trạng thái đồng bộ lỗi từ slave, chẳng hạn `slave_io_running == 0` hoặc `slave_thread_running == 0` khi đó, thực hiện các bước sau để đồng bộ lại dữ liệu cho slave

**On Node1**

- Dump all databases

`mysqldump -h node1 -u root -p --all-databases | gzip >/path/to/all-database-node1.sql.gz`

- Show master status

```
mysql -u root -p
mysql>STOP SLAVE;
mysql>FLUSH TABLES WITH READ LOCK;
mysql>SHOW MASTER STATUS;
```

**On Node2**

- Copy dump file from node1

`scp root@node1:/path/to/all-database-node1.sql.gz .`

- Restore database

`gunzip <all-database-node1.sql.gz |mysql -u root -p`

- Thực hiện CHANGE MASTER TO

```
mysql -u root -p
mysql>STOP SLAVE;
mysql>CHANGE MASTER TO MASTER_HOST='192.168.10.111', MASTER_USER='keepwalking', MASTER_PASSWORD='P@ssw0rd', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.0000xx', MASTER_LOG_POS=xxxx
mysql>START SLAVE;
mysql>SHOW SLAVE STATUS \G;
```

- Show master status

```
mysql>FLUSH TABLES WITH READ LOCK;
mysql>SHOW MASTER STATUS;
```

**On Node1**

```
mysql>unlock tables
mysql>STOP SLAVE;
mysql>CHANGE MASTER TO MASTER_HOST='192.168.10.112', MASTER_USER='keepwalking', MASTER_PASSWORD='P@ssw0rd', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.0000xx', MASTER_LOG_POS=xxxx
mysql>START SLAVE;
mysql>SHOW SLAVE STATUS \G;
```

## 2. Troubleshooting Replication with large database

Trong trường hợp replication là MASTER-MASTER gồm node1(master1-slave1) và node2(master2-slave2), lỗi đồng bộ xảy ra trên node2 (slave2). Khi đó thực hiện các bước sau để giải quyết vấn đề mà không làm gián đoạn dịch vụ đang chạy

**STEP1: STOP SLAVE ON NODE1**

khi đó trên node1 thực hiện `STOP SLAVE` trước khi thực hiện restore trên node2. Việc này, để tránh tình trạng khi restore node2, dữ liệu đồng bộ ngược lại node1, dẫn đến mất dữ liệu.

```
mysql -u root -p
mysql>STOP SLAVE;
```

**STEP2: STOP SLAVE ON NODE2**

```
mysql -u root -p
mysql>STOP SLAVE;
```

**STEP3: DUMP ALL DATABASES ON NODE1**

Chúng ta sẽ thực hiện backup -all-databases với các tham số sau để không làm gián đoạn hệ thống đang chạy:

`[root@node1]#mysqldump -A --single-transaction -F --master-data=2 -r all-databases.sql -u root -p`

Diễn giải các tham số:

-A : --all-databases

-F : --force

--allow-keywords: tham số này dùng để

--sigle-transaction: Gần tương tự như lock tables, nhưng nó sẽ không khóa tất cả các tables, như với các trường hợp table lớn. Mục đích tránh trình trạng gián đoạn hệ thống trong quá trình dump. Tức là trong quá trình dump dữ liệu thì hệ thống vẫn read/write dữ liệu trên master bình thường.

--master-data: Tham số này dùng để dump một master replication server đến một file mà được sử dụng bởi một server khác, như một slave trong một replication. Khi sử dụng tham số này, nội dung dump bao gồm thông tin binary log (file name và position) của MASTER STATUS mà cho phép SLAVE kết nối trong phần `CHANGE MASTER TO`. Nếu --master-data=2, khi đó thông tin `CHANGE MASTER TO` sẽ được viết ở dạng comment trong tệp dump sql. Còn --master-data=1, khi đó thông tin `CHANGE MASTER TO` sẽ được áp dụng luôn khi restore từ tệp dump.

-r: dump to file-name

**STEP4: RESTORE DATABASE ON SLAVE**

- Copy dump file từ MASTER

`[root@node2]#scp root@node1:/path/to/all-databases.sql .`

- Thực hiện restore database

`[root@node2]#mysql -u root -p <all-databases.sql`

- Cấu hình lại CHANGE MASTER TO

Lấy thông tin `CHANGE MASTER TO` từ tệp all-databases.sql

```
[root@node2]# head -n 30 all-databases.sql |grep "CHANGE MASTER"
-- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=154;
```

Thực hiện CHANGE MASTER

```
[root@node2]#mysql -u root -p
mysql>CHANGE MASTER TO MASTER_HOST='IP-ADD-NODE1', MASTER_USER='replicator', MASTER_PASSWORD='P@ssw0rd', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=154;
```

Thực hiện `START SLAVE`

`mysql>START SLAVE`

**STEP4: CHECK REPLICATION ON NODE2**

```
node2#mysql -u root -p
mysql> SHOW SLAVE STATUS \G;
```

**STEP5: SHOW MASTER STATUS ON NODE2**

Show master status của node2 để lấy thông tin cho cấu hình `CHANGE MASTER TO` cho node1

mysql> SHOW MASTER STATUS;
+------------------+----------+--------------+-------------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB        | Executed_Gtid_Set |
+------------------+----------+--------------+-------------------------+-------------------+
| mysql-bin.000008 | 175      |              | test,information_schema |                   |
+------------------+----------+--------------+-------------------------+-------------------+
1 row in set (0.00 sec)

**STEP6: CONFIGURE CHANGE MASTER ON NODE1**

```
node1#mysql -u root -p
mysql>CHANGE MASTER TO MASTER_HOST='IP-ADD-NODE2', MASTER_USER='replicator', MASTER_PASSWORD='P@ssw0rd', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000008', MASTER_LOG_POS=175;
```

**STEP7: CHECK REPLICATION ON NODE1**

```
node2#mysql -u root -p
mysql> SHOW SLAVE STATUS \G;
```

## 3. HA_ERR_KEY_NOT_FOUND

Khi `SHOW SLAVE STATUS \G`, chúng ta nhận thông báo lỗi kiểu như

`Last_SQL_Error: Could not execute Delete_rows event on table database.users; Can't find record in 'users', Error_code: 1032; handler error HA_ERR_KEY_NOT_FOUND; the event's master log mysql-bin.000002, end_log_pos 1026`

Lỗi xảy ra thường do vấn đề liên quan đến đồng bộ dữ liệu trước đó giữa master-slave chưa đầy đủ. Khi đó, thực hiện quá trình đồng bộ lại dữ liệu và cấu hình lại `CHANGE MASTER TO`

