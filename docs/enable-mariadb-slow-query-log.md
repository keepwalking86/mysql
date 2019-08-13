**Sửa nội dung tệp tin cấu hình mysql/mariadb**

Thêm nội dung sau vào tệp tin /etc/my.cnf, mở rộng trong phần [mysqld]

```
slow_query_log = 1
long_query_time = 1
slow_query_log_file = /var/log/mysql/slow-query.log
log_queries_not_using_indexes=ON
```

Trong đó:

- slow_query_log = 1 : Dùng để enable slow query log

- long_query_time = 2 : Thiết lập thời gian một truy vấn SQL sẽ thực hiện (tính bằng giây)

- slow_query_log_file = /var/log/mysql-slow.log : Chỉ định tên tệp cho slow query log

- log_queries_not_using_indexes = ON : Chỉ định ON/OF log query sẽ được indexes

**Tạo slow query logfile**

```
sudo touch /var/log/mysql/slow-query.log
sudo chown -R mysql:mysql /var/log/mysql/slow-query.log
```

**Restart mysql/mariadb**

`sudo systemctl restart mysqld`

**Xem, phân tích thông tin slow query log**

- Xem nội dung tệp tin slow query log

`sudo tail -f /var/log/mysql/slow-query.log`

- Sử dụng mysqldumpslow để phân tích và xuất slow query logfile

`mysqldumpslow -a /var/log/mysql/slow-query.log`

- Sử dụng công cụ pt-query-digest để phân tích query log

**pt-query-digest** là một công cụ của Percona dùng để phân tích các query mysql từ slow, general, và binary log files

Cài đặt công cụ Percona trên CentOS 7

`sudo yum install https://www.percona.com/downloads/percona-toolkit/3.0.13/binary/redhat/7/x86_64/percona-toolkit-3.0.13-1.el7.x86_64.rpm`

Phân tích slow query log file

`pt-query-digest /var/log/mysql/slow-query.log`

**Read more>**

[https://mariadb.com/kb/en/library/slow-query-log/](https://mariadb.com/kb/en/library/slow-query-log/)

[https://dev.mysql.com/doc/refman/5.7/en/mysqldumpslow.html](https://dev.mysql.com/doc/refman/5.7/en/mysqldumpslow.html)
