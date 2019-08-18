# Backup & Restore database

## 1. Các kiểu backup và restore

### Logical backup

Logical backup (hay backup logic) là kiểu backup mà xuất cấu trúc database và nội dung của nó.

Một số đặt trưng của kiểu backup này như sau:

- Thực hiện backup trong khi mysql server đang chạy (hot backup)

- Có thể thực hiện backup theo cấp độ từng table, database hoặc toàn bộ database

- Dung lượng đầu ra của kiểu logical backup sẽ lớn hơn kiểu physical backup

- Thời gian thực hiện backup theo kiểu logical sẽ lâu hơn physical backup bởi vì nó phải thực hiện truy cập thông tin database và sau đó thực hiện chuyển đổi sang định dạng logic. Ngoài ra, với mysql server đang chạy khi thực hiện backup cũng làm cho hiệu suất xử lý của nó chậm đi, đặc biệt với hệ thống dữ liệu lớn.

- Backup gồm thông tin tệp tin log và tệp tin cấu hình

### Physical Backup

Physical backup (hay backup vật lý) Là kiểu backup mà sử dụng copy tệp tin, thư mục nội dung database

Một số đặc trưng của kiểu backup này như sau:

- Nó có thể thực hiện backup các tệp tin log và cấu hình

- Chỉ thực hiện copy mà không phải xử lý các thông tin khác vì vậy mà kiểu backup này sẽ thực hiện nhanh hơn so với kiểu logical backup.

- Dung lượng đầu ra của kiểu physical backup cũng sẽ nhỏ hơn so với kiểu logical backup

- Kiểu backup and restore theo kiểu physical rất hợp cho sử dụng dữ liệu lớn vì thời gian thực hiện backup và restore nhanh hơn rất nhiều so với logical

- Hạn chế của kiểu backup này là nó phải table phải lock hoặc phải stop database trước khi thực hiện backup. Vì lý do này, mà để thực hiện kiểu backup này chúng ta sẽ thực hiện backup 

- Backup dữ liệu bảng theo từng tệp tin có thể có hạn chế với kiểu lưu trữ InnoDB (vì dữ liệu bảng của nó có thể một tệp tin riêng hoặc kiểu share file với một table khác) 

## 2. Backup database

### Physical backup

Phương pháp backup này chỉ đơn giản là lock tables hoặc stop database và copy nội dung tệp tin và thư mục chứa nội dung dữ liệu. Một số công cụ có thể sử dụng và hỗ trợ như các lệnh cp, scp, rsync và kết hợp với nén. Mặc định thì thư mục chứa nội dung database nằm ở thư mục /var/lib/mysql

Trong thực hiện tế, database phải luôn hoạt động để không làm gián đoạn quá trình read/write dữ liệu. Vì vậy, để thực hiện kiểu physical backup, chúng ta thực hiện trên slave server trong mô hình master-slave.

### Backup với mysqldump

Syntax:

`mysqldump -u user-name -p db-name --opt > /path/to/backup-file.sql`

Trong đó:

user-name là tên người dùng được phép thực thực backup database
db-name là tên database cần được backup
--opt là giá trị tùy chọn cho mysqldump
 
- Backup full database

`mysqldump -u root -p --all-databases >/path/to/backup-full.sql`

- Backup với một số database nhất định

`mysqldump -u root -p --databases db01-name db02-name db03-name >/path/to/specify-databases.sql`

- Backup một số bảng trong một database

`mysqldump -u root -p db-name tb01-name tb02-name >/path/to/any-tables.sql`

- Chỉ backup schema (structure), không bao gồm data

Sử dụng flag --no-data

`mysqldump -u root -p --no-data db-name >/path/to/db-name.sql`

- Backup with compress

Sử dụng gzip để nén dữ liệu sao lưu

`mysqldump -u root -p db-name |gzip >/path/to/backup-compress.sql.gz`

- Incremental Backups với tùy chọn Binary Log

Việc thực hiện backup full với database có dung lượng lớn sẽ mất nhiều thời gian, vì vậy mà chúng ta lập kế hoạch để sao lưu dữ liệu thay đổi sao khi thực hiện backup full.

Binary log là tệp tin mà lưu trữ tất cả quá trình thực hiện query database khi thực hiện alter hoặc create bản ghi mới. Binary log được sử dụng trong trường hợp replication database mà cho phép slave đồng bộ dữ liệu từ master server. Ngoài ra, binary log còn được sử dụng trong như một phương pháp trong quá trình backup database mà cho phép thực hiện nhanh và hiệu quả hơn khi phải thực hiện full backup.

Để sử dụng binary log, chúng ta cần enable nó bằng việc thêm tùy chọn trong tệp tin cấu hình database. Ví dụ như tùy chọn cấu hình sau:

```
[mysqld]
bin-log = binlog
binlog-ignore-db = test
binlog-ignore-db = information_schema
#binlog-do-db = db-name
max_binlog_size = 100M

```

### Snapshot


## 3. Restore

- Restore từ tệp script sql

`mysql -u user-name -p db-name </path/to/backup-file.sql`

- Restore từ tệp backup được nén gzip

`gunzip < [backupfile.sql.gz] | mysql -u user-name -p db-name`

- Sử dụng tham số -e

`mysql -u user-name -p -e "source /path/to/backup-file.sql" db-name`

Trong đó:

-e (--execute): Tùy chọn dùng để thực hiện một statement nào đó.
source (\.) dùng để thực hiện một tệp script sql được chỉ định.

- Restore với database đã tồn tại

Sử dụng tool mysqlimport

`mysqlimport -u user-name -p db-name /path/to/backup-file.sql`

### Restore với point-to-time (incremental)

Để thực hiện restore đến thời điểm được chỉ định, chúng ta cần biết thông tin vị trí các tệp tin binary log.

- show danh sách các tệp tin binary log

`mysql> SHOW BINARY LOGS;`

- Xác định tệp tin binary log hiện tại

`mysql> SHOW MASTER STATUS;`

- Xem nội dung tệp tin binary log với công cụ mysqlbinlog

`mysqlbinlog binlog_files | mysql -u root -p`

mysqlbinlog thực hiện convert nội dung tệp tin binary log từ dạng binary sang text.

- Thực hiện restore với binary log

Ví dụ thực hiện restore database như sau:

```
mysql -u root -p <latest-full-backup.sql
mysqlbinlog binlog.000001 binlog.000002 | mysql -u root -p
```

- Sử dụng tùy chọn --stop-datetime

Sử dụng tùy chọn --stop-datetime để restore database đến thời điểm được chỉ định

ví dụ:

`mysqlbinlog --stop-datetime="2019-08-19 9:59:59" /var/lib/mysql/binlog.000003 | mysql -u root -p`

- Sử dụng tùy chọn --start-datetime

Sử dụng tùy chọn --start-datetime cho phép restore database từ thời điểm được chỉ định

ví dụ:

`mysqlbinlog --start-datetime="2019-08-10 9:59:59" /var/lib/mysql/binlog.000003 | mysql -u root -p`

Ngoài ra chúng ta có thể thực hiện restore với các tùy chọn --start-position and --stop-position

## 4.Sử dụng một số tool khác

### Sử dụng percona extrabackup

- Cài đặt

```
wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm
yum install percona-release-latest.noarch.rpm
yum install percona-xtrabackup-80
```
với mysql phiên bản thấp hơn, chúng ta sẽ sử dụng xtrabackup bản thấp hơn. Ví dụ:

`yum install percona-xtrabackup-24`

- Sử dụng

Full backup

`xtrabackup --host=database-server -P port-mysql -u user-name -p --backup --target-dir=/path/to/full-dir/ --datadir=/var/lib/mysql/`

Incremental backup

```
xtrabackup --host=database-server -P port-mysql -u user-name -p \
--backup --target-dir=/path/to/inc1-dir/ --incremental-basedir=/path/to/full-dir/ --datadir=/var/lib/mysql/
```

**Read more>**

- [https://mariadb.com/kb/en/library/percona-xtrabackup-overview/](https://mariadb.com/kb/en/library/percona-xtrabackup-overview/)

- [https://dev.mysql.com/doc/mysql-backup-excerpt/5.7/en/backup-and-recovery.html](https://dev.mysql.com/doc/mysql-backup-excerpt/5.7/en/backup-and-recovery.html]
