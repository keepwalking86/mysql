# Một số lệnh thường dùng trong mysql

**Create a database**

syntax:

`mysql>CREATE DATABASE IF NOT EXISTS DB_NAME CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci'`

**Create table**

syntax:

```
CREATE TABLE [IF NOT EXISTS] table_name(
        /*column_list*/
) ENGINE=table_type
```
ex:

```
CREATE TABLE Users(
   id INT PRIMARY KEY AUTO_INCREMENT,
   username VARCHAR(50) NOT NULL,
   email VARCHAR(50) NOT NULL
) ENGINE = InnoDB
```

**Show table structure**

syntax:

`mysql>DESCRIBE table_name;`

hoặc

`SHOW COLUMNS FROM table_name;`

ex:

```
mysql>show databases;
vnn
mysql>use vnn;
mysql>show tables;
Users;
mysql>decribe Users;
```

**Tạo Unique trong MySQL**

unique dùng để thiết lập giá trị của column (trường ) là duy nhất, không lặp lại giá trị.

Thêm giá trị `UNIQUE` vào field mà chúng ta muốn thiết lập.

ex:

```
CREATE TABLE Users(
   id INT PRIMARY KEY AUTO_INCREMENT,
   username VARCHAR(50) NOT NULL UNIQUE,
   email VARCHAR(50) NOT NULL UNIQUE
);
```
- hoặc cách sau:
```
CREATE TABLE Users(
   id INT PRIMARY KEY AUTO_INCREMENT,
   username VARCHAR(50) NOT NULL,
   email VARCHAR(50) NOT NULL,
   UNIQUE (username),
   UNIQUE (email)
);
```
- Sử dụng alter để thêm UNIQUE

```
CREATE TABLE Users(
   id INT PRIMARY KEY AUTO_INCREMENT,
   username VARCHAR(50) NOT NULL,
   email VARCHAR(50) NOT NULL
);
 
ALTER TABLE Users ADD UNIQUE(username);
ALTER TABLE Users ADD UNIQUE(email);
```

**How to know storage engine**

Một số engine phổ biến như innodb, myisam,...

syntax:

```
USE database_name;
SHOW TABLE STATUS\G;
```

**Insert data into table**

syntax:
```
INSERT INTO
table_name(field1, field2, field2, ..., fieldn)
VALUES('field1', 'field2', 'field3', ...,'fieldn')
```
ex:

```
use vnn;
insert into Users(username, email) values ('Hacker', 'vnn@hacker.vn');
```

**Show information dữ liệu**

Show thông tin từ một table với `SELECT`

syntax:
```
SELECT what_to_select
FROM which_table
WHERE conditions_to_satisfy;
```
ex:

`select * from vnn.Users`

`select username from vnn.Users;`

sử dụng điều kiện lọc với `WHERE`

`select * from vnn.Users where username='Hacker';`

`select * from vnn.Users where usename like 'hack%';`

**Cú pháp cho WHERE IN - WHERE LIKE**

- **WHERE IN** dùng để lọc điều kiện trong một tập giá trị, nó tương đương với các giá trị của toán tử **OR**

syntax:

```
what_to_select
FROM which_table
WHERE IN (value1, value2, ..);
```

ex:

`select * from vnn.Users where username in ('Hacker', 'Security');`

as

`select * from vnn.Users where username='Hacker' or username='Security';`

- **WHERE LIKE** sử dụng lọc dữ liệu theo phương thức so khớp

Like kết hợp với một số kí tự đặc biệt để so khớp như **%, -**

Trong đó: kí hiệu % dùng để đại diện cho 0 hoặc nhiều kí tự bất kỳ; kí hiệu _ dùng đại diện cho một kí tự bất kỳ

ex:

`select * from vnn.Users where username like '_ack%'`

**Count records**

syntax:

`COUNT(expression)`

ex: count tất cả row trong tables users của hacker database

`SELECT COUNT(*) FROM hacker.users;`

**Count tables in a database**

`SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='database-name';`

**Count records for all tables**

`SELECT SUM(TABLE_ROWS) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='database-name';`
