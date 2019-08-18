**Requirements**

OS: CentOS 7

IP Addresses:

- node01: 192.168.10.111

- node02: 192.168.10.112

**Step1: Install mysql on 2 nodes**

```
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
yum install mysql-community-server -y
```

- Run security setting

`mysql_secure_installation`

**Step2: Configure mysql on node1**

vi /etc/my.cnf

```
[mysqld]
server-id                       = 1
port                            = 3306
datadir                         = /var/lib/mysql
socket                          = /var/lib/mysql/mysql.sock
user                            = mysql
bind-address                    = 0.0.0.0

collation-server                = utf8_unicode_ci
init-connect                    = 'SET NAMES utf8'
lower_case_table_names          = 1
character-set-server            = utf8
show_compatibility_56           = ON

# Replication config #
log-bin                         = "mysql-bin"
binlog-ignore-db                = test
binlog-ignore-db                = information_schema
replicate-ignore-db             = test
replicate-ignore-db             = information_schema
relay-log                       = "mysql-relay-log"
auto-increment-increment        = 2
auto-increment-offset           = 1
expire_logs_days                = 3

# MyISAM #
key-buffer-size                 = 6G
myisam-recover-options          = FORCE,BACKUP

# # SAFETY #
max-allowed-packet              = 16M
max-connect-errors              = 1000000
skip-name-resolve

# CACHES AND LIMITS #
tmp-table-size                  = 32M
max-heap-table-size             = 32M
query-cache-type                = 0
query-cache-size                = 0
max-connections                 = 500
thread-cache-size               = 50
open-files-limit                = 65535
table-definition-cache          = 1024
table-open-cache                = 2048

# INNODB #
default_storage_engine          = innodb
innodb_autoinc_lock_mode        = 2
innodb_flush_log_at_trx_commit  = 0
innodb_buffer_pool_size         = 122M
innodb_flush_log_at_trx_commit  = 0
innodb_thread_concurrency       = 4
innodb_flush_method             = O_DIRECT
innodb-log-files-in-group       = 2
innodb-log-file-size            = 32M
innodb-file-per-table           = 1
innodb-buffer-pool-size         = 8M

symbolic-links                  = 0

[mysql_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```
**Step3: Configure mysql on node2**

vi /etc/my.cnf

```
[mysqld]
server-id                       = 2
port                            = 3306
datadir                         = /var/lib/mysql
socket                          = /var/lib/mysql/mysql.sock
user                            = mysql
bind-address                    = 0.0.0.0

collation-server                = utf8_unicode_ci
init-connect                    = 'SET NAMES utf8'
lower_case_table_names          = 1
character-set-server            = utf8
show_compatibility_56           = ON

# Replication config #
log-bin                         = "mysql-bin"
binlog-ignore-db                = test
binlog-ignore-db                = information_schema
replicate-ignore-db             = test
replicate-ignore-db             = information_schema
relay-log                       = "mysql-relay-log"
auto-increment-increment        = 2
auto-increment-offset           = 1
expire_logs_days                = 3

# MyISAM #
key-buffer-size                 = 6G
myisam-recover-options          = FORCE,BACKUP

# # SAFETY #
max-allowed-packet              = 16M
max-connect-errors              = 1000000
skip-name-resolve

# CACHES AND LIMITS #
tmp-table-size                  = 32M
max-heap-table-size             = 32M
query-cache-type                = 0
query-cache-size                = 0
max-connections                 = 500
thread-cache-size               = 50
open-files-limit                = 65535
table-definition-cache          = 1024
table-open-cache                = 2048

# INNODB #
default_storage_engine          = innodb
innodb_autoinc_lock_mode        = 2
innodb_flush_log_at_trx_commit  = 0
innodb_buffer_pool_size         = 122M
innodb_flush_log_at_trx_commit  = 0
innodb_thread_concurrency       = 4
innodb_flush_method             = O_DIRECT
innodb-log-files-in-group       = 2
innodb-log-file-size            = 32M
innodb-file-per-table           = 1
innodb-buffer-pool-size         = 8M

symbolic-links                  = 0

[mysql_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```

Diễn giải tệp cấu hình:

- server-id: nằm trong 1 to 2^32-1, và giá trị server-id giữa các server là duy nhất

- log-bin: dùng để tạo ra các tệp tin log dạng binary mà ghi lại tất cả các thông tin thay đổi của databases.
Vị trí mặc định của các tệp tin log-bin nằm ở **/var/lib/mysql/**.
Chúng ta có thể sử dụng công cụ **mysqlbinlog** để đọc thông tin tệp tin bin log
Chúng ta có thể sử dụng tham số **binlog_do_db** để chỉ định replication cho từng database. Trong trường hợp này, chúng ta sẽ replication all database, vì vậy mà không sử dụng đến tham số binlog_do_db

- relay-log: giống binary log, gồm các tệp tin log có định dạng binary, chứa các thông tin mô tả về sự thay đổi của database. 

- relay-log-index: dùng để tạo tệp tin index mà sẽ chứa tên của tất cả các tệp tin relay-log

Vị trí mặc định của các tệp tin relay-log và relay-log-index nằm ở thư mục data /var/lib/mysql

**Note:** Giải thích quá trình replication như sau:

Master sẽ lưu mọi thay đổi database của nó vào một file binlog và để đó (có thể cấu hình được các thông số như kích thước tối đa, thời gian lưu trên server). Slave sẽ truy vấn đến master và lấy thông tin từ binlog về, sau đó thực hiện đọc và ghi vào replaylog. Cuối cùng Slave đọc replaylog và cập nhật các event trong đó. Kết thúc quá trình Replication.

**Step4: Start mysql server on 2 nodes**

```
systemctl enable mysqld
systemctl start mysqld
```

**Step5: Thiết lập Master trên node01 (master01)**

- login mysql with root permission

```
mysql -u root -p
Enter password:
```

- Create an user on the node1 (Master 1) that allows replication on the node2 (Slave 1)

Cho phép người dùng replicator được phép truy cập từ node2 với mật khẩu là 'Passw0rd' với chỉ thông tin replication slave

```
mysql>grant replication slave on *.* to 'replicator''192.168.10.112' identified by 'Passw0rd';
mysql>flush privileges;
```

- Check master status

```
mysql> show master status;
+------------------+-----------+--------------+-------------------------+-------------------+
| File             | Position  | Binlog_Do_DB | Binlog_Ignore_DB        | Executed_Gtid_Set |
+------------------+-----------+--------------+-------------------------+-------------------+
| mysql-bin.000002 | 875834797 |              | test,information_schema |                   |
+------------------+-----------+--------------+-------------------------+-------------------+
1 row in set (0,00 sec)
```

Chúng ta thấy:
File log-bin có giá trị là: mysql-bin.000002
Position có giá trị là: 875834797; Nếu không lock database thì khi có sự thay đổi ở database thì giá trị này sẽ thay đổi
Binlog_Ignore_DB: Các DB không được replicate (trong directive binlog-ignore-db)
Executed_Gtid_Set: Là giá trị của global transaction IDs

**Step6: Thiết lập Master trên node02 (master02)**

- login mysql with root permission

```
mysql -u root -p
Enter password:
```

- Create an user on the node02

Tạo user replicator mà cho phép truy cập từ node01 với mật khẩu là 'Passw0rd' với chỉ thông tin replication slave

```
mysql>grant replication slave on *.* to 'replicator''192.168.10.111' identified by 'Passw0rd';
mysql>flush privileges;
```

- Check master status

```
mysql> show master status;
+------------------+----------+--------------+-------------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB        | Executed_Gtid_Set |
+------------------+----------+--------------+-------------------------+-------------------+
| mysql-bin.000002 |     1503 |              | test,information_schema |                   |
+------------------+----------+--------------+-------------------------+-------------------+
1 row in set (0,00 sec)
```

**Step7: Thiết lập Slave trên node2 (Slave01)**

Chúng ta sẽ khai báo node02 sẽ đóng vai trò là slave trong quá trình replication Master - Slave

- login mysql with root permission

```
mysql -u root -p
Enter password:
```
- Khai báo thông tin mà slave có thể nhận dữ liệu từ Master (node01)

```
mysql>STOP SLAVE;
mysql>CHANGE MASTER TO MASTER_HOST='192.168.10.111', MASTER_USER='replicator', MASTER_PASSWORD='P@ssw0rd', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000002', MASTER_LOG_POS=875834797, MASTER_CONNECT_RETRY = 10;
mysql>START SLAVE;
```

- Kiểm tra thông tin trạng thái SLAVE

```
mysql> show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.10.111
                  Master_User: replicator
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 875834797
               Relay_Log_File: mysql-relay-log.000002
                Relay_Log_Pos: 877840062
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: test,information_schema
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 875834797
              Relay_Log_Space: 877840269
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: b476c51d-7cfb-11e9-89dc-0050569762a1
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0,00 sec)
```

**Step8: Thiết lập Slave trên node1 (Slave02)**

Chúng ta sẽ khai báo node01 sẽ đóng vai trò là slave trong quá trình replication Master - Slave

- login mysql with root permission

```
mysql -u root -p
Enter password:
```
- Khai báo thông tin mà slave có thể nhận dữ liệu từ Master2 (node02)

```
mysql>STOP SLAVE;
mysql>CHANGE MASTER TO MASTER_HOST='192.168.10.112', MASTER_USER='replicator', MASTER_PASSWORD='P@ssw0rd', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000002', MASTER_LOG_POS=1503, MASTER_CONNECT_RETRY = 10;
mysql>START SLAVE;
```

- Kiểm tra thông tin trạng thái SLAVE

Sử dụng lệnh **show slave status** để kiểm tra trạng thái replication MySQL đang chạy và cần xác giá trị của các cột **Slave_IO_Running** và **Slave_SQL_Running** là yes 

```
mysql> show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.10.112
                  Master_User: replicator
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 1503
               Relay_Log_File: mysql-relay-log.000002
                Relay_Log_Pos: 643
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: test,information_schema
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1503
              Relay_Log_Space: 850
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 2
                  Master_UUID: b207e0b8-7cfb-11e9-80fc-0050569731ec
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0,01 sec)
```

**Step9: Kiểm tra quá trình replication giữa các nodes**

- Thực hiện tạo database từ node01 và kiểm tra thông tin database trên node02

- Thực hiện tạo database từ node02 và kiểm tra thông tin database trên node01

**Step10: Một số lưu ý**

- Note1:

Nếu quá trình replication chưa có database và chưa có yêu cầu ghi dữ liệu thì chúng ta thực hiện quá trình replication mà không cần không thực hiện lock tables. Trong trường hợp của chúng ta, giả sử đã có databases và hệ thống đang chạy, có nghĩa là có quá trình thay đổi như giá trị read/write, vì vậy mà chúng ta cần thực hiện lock databases để tạm thời chặn quá trình thay đổi này.

Thực hiện lock databases như sau:

>FLUSH TABLES WITH READ LOCK;

Quá trình lock tables sẽ được giải phóng khi chúng ta thoát cửa sổ vừa thực hiện lệnh lock trên hoặc thực hiện lệnh sau để unlock

```
mysql>unlock tables
mysql>quit
```

Để duy trì chế độ lock, chúng ta sẽ giữ nguyên cửa sổ thực hiện lệnh lock. 

- Note2:

Nếu tạo tài khoản người dùng cho quá trình replication mà cho phép truy cập từ all và không có password, như sau:

`mysql>grant replication slave on *.* to 'replicator'@'%';`

khi đó chúng ta chỉ cần `START SLAVE' mà không cần thực hiện khai báo thông tin kết nối từ slave đến master

**Step11: Một số dòng lệnh kiểm tra quá trình replication**

- Kiểm tra trạng thái replication MySQL đang chạy ở slave

`SHOW SLAVE STATUS\G;`

- Kiểm tra tiến trình đang chạy ở slave với lệnh sau

`SHOW PROCESSLIST \G;`

- Hiển thị danh sách các slave được replication từ master

Thực hiện lệnh sau trên master

```
mysql> SHOW SLAVE HOSTS;
+-----------+------+------+-----------+--------------------------------------+
| Server_id | Host | Port | Master_id | Slave_UUID                           |
+-----------+------+------+-----------+--------------------------------------+
|         2 |      | 3306 |         1 | b207e0b8-7cfb-11e9-80fc-0050569731ec |
+-----------+------+------+-----------+--------------------------------------+
1 row in set (0,00 sec)
```

Trong đó:

- Server_id: là thông tin định danh của slave

- Master_id: là thông tin định danh của master

- Slave_UUID: Giá trịnh định danh global của slave (Thông tin lấy từ tệp /var/lib/mysql/auto.cnf)

Show thông tin trạng thái tệp log binary của master

```
mysql> SHOW MASTER STATUS\G
*************************** 1. row ***************************
             File: mysql-bin.000002
         Position: 880730280
     Binlog_Do_DB: 
 Binlog_Ignore_DB: test,information_schema
Executed_Gtid_Set: 
1 row in set (0,00 sec)
```

**Read more>**

[https://dev.mysql.com/doc/refman/8.0/en/show.html](https://dev.mysql.com/doc/refman/8.0/en/show.html)



