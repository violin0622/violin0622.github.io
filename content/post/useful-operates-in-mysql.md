---
title: MySQL常用操作
date: 2020-02-19T15:14:38+08:00
tags: [MySQL]
categories: [Middleware]

---

## 数据库概念关系
服务器 -> 实例 -> 数据库 -> 表 -> 记录

## 登录数据库实例
```sh
mysql  \
    -u{用户名}  \   #如果不指定-u， 则使用 root 用户。
    -p{密码} \      #如果指定-p而不输入密码， 则会在交互式界面中询问密码。 这样可以避免密码泄漏。 
    -h{主机地址} \
    -P{服务端口}

```

## 常用信息查看
```sql
select user();      -- 当前用户
select database();  -- 当前数据库
select version();   -- 当前版本
select now();       -- 当前时间
```

## 数据库管理

### 创建数据库
```sql
create database {数据库名}
    character set {字符集}      -- 可选参数
    collate {检查名}            -- 可选参数
    default encryption {Y/N};   -- 可选参数
```
`charactor set` 用于指定数据库级别的字符集。 从MySQL8.0开始， 默认字符集是`utf8mb4`, 这是一种支持 emoji 表情的utf8字符集。 :tada:   
`collate` 用于指定数据库级别的字符型数据排序规则。 从8.0之后， 排序规则默认为`utf8mb4_0900_ai_ci`。 一般不用改。  
`encryption` 用于指定数据库的加密算法。 默认为不使用加密。  

### 查看/删除数据库
```sql
show databases;              -- 查看所有数据库
drop database {数据库名};   -- 删除指定名称的数据库
```

### 导出数据
`注意`：如果在命令行指定了-p， 则导出的sql文件第一行会有个warnning：  
> mysqldump: [Warning] Using a password on the command line interface can be insecure.  

这行warining不是注释，因此在其他数据库导入时会报语法错误。 解决办法有两个:  
1. 在导出命令中不指定`-p`参数， 使用交互方式输入密码。【推荐】
2. 在导出的sql文件中将这一行删除或注释掉。 

```sh
mysqldump -u{用户名} -p{密码} \
  -h{主机地址} -P{端口} \
  {数据库名}            #如果要导出所有数据库， 则库名表名都不用指定。 \
  {数据表名}            #如果要导出单个数据库所有表，则表名不用指定。 \
   > backup.sql         #重定向到备份文件中。 
```

### 导入数据
首先登陆数据库， 创建数据库与用户， 并为用户分配权限。  
```sh
mysql -u{用户名} -p{密码} -h{主机地址} -P{端口} {数据库名} < backup.sql
```

### 导出数据（docker内）
```sh
docker exec -it mysql-instance mysqldump -u{user} -p{password} > backup.sql
```
### 导入数据（docker内）
首先将文件拷贝到docker内， 然后在容器内的命令行执行导入命令。  
```sh
docker cp ./backup.sql mysql-instance:/tmp/backup.sql
docker exec mysql-instance 'mysql -u{user} -p{password} source /tmp/backup.sql'
```

## 用户管理
### 查看系统内所有用户及登录地址
```sql
select distinct 
    concat('user: ''',user,'''@''',host,''';') as query 
    from mysql.user;
```

### 查看某个用户的所有权限
```sql
select * from mysql.user where user={用户名};
```
在`mysql.user`中， user和host两个字段共同构成主键。  

### 创建用户与授权
```sql
-- 创建与授权分两步
create user '{用户名}'@'{主机域}' identified by '{密码}';
grant {权限列表} on {数据库名}.{数据表名} to '{用户名}'@'{主机域}';
-- 分配所有权限
grant all on *.* to 'admin'@'localhost';
-- 查看用户的权限
show grants for '{用户名}'@'{主机域}';
```
创建用户时需要同时指定用户名和主机域， 因为它们共同构成`mysql.user`的主键。 如果不限制该用户可以在哪台主机访问， 则主机域可以设定为`%`， 代表任意主机。 如果不指定主机域， 同样使用`%`作为默认值。  


## 数据表管理
### 建表
```sql
create table 表名(
    -- not null, default, auto_increment, comment 都是可选参数
    id int not null  auto_increment comment '主键',   
    name varchar(10) not null default '' comment '名字',
    primary key(`id`),
    unique key `k索引名` (`name`) -- 最后一行不能以逗号结尾
)charset=utf8mb4;
```

### 修改表
#### 新加字段
```sql
-- 后一个列名用于指定新列的位置
alter table 表名 add column 字段名 enum('M','F') not null after 列名;
-- 将新字段设置为第一列
alter table 表名 add column 字段名 enum('M','F') not null first;
```

#### 删除字段
```sql
alter table 表名 drop 字段名;
```

#### 更新字段
```sql
alter table 表名 change 字段名 enum('M','F') not null ;
```

#### 修改字段数据类型
```sql
alter table 表名 modify 字段名 enum('M','F');
```
修改字段数据类型之后， 其他的配置如 not null 等不会变。 

#### 添加/删除字段默认值
```sql
alter table 表名 alter 字段名 set default 默认值;
alter table 表名 alter 字段名 drop default;
```


### 重命名表名
```sql
alter table 表名 rename to 新表名;
```

## 索引管理
除了可以在创建数据表等时候指定索引之外， 还可以单独对索引进行管理。  

### 查看索引
```sql
show table from 表名;
```

### 创建索引
```sql
create index 索引名 on 表名(字段名);
-- 创建唯一索引
create unique index 索引名 on 表名(字段名);
```

### 删除索引
```sql
drop index 索引名 on 表名;
alter table  表名 drop index 索引名;
```

