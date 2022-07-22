# test lock type diffrence of SELECT,INSERT,update,delete in the condition of read commited isolation level

## set transaction read committed or repeated-read
set session transaction isolation level read committed;
SELECT @@SESSION.transaction_isolation, @@SESSION.transaction_read_only;

## drop and create table, then prepare the data
use mydb;
drop  table if exists t;
CREATE TABLE t (a INT NOT NULL, b INT, primary key(a)) ENGINE = InnoDB;
INSERT INTO t VALUES (1,3),(4,6),(7,9),(10,12),(13,15);

## for example:InnoDB holds locks only for rows that it updates or deletes
## session A update 
START TRANSACTION;
UPDATE t SET b = 5 WHERE b = 3;
## --------------------
commit;

#------------------------------------
# test lock type diffrence of SELECT,INSERT,update,delete in the condition of repeated-read isolation level

## set transaction read committed or repeated-read
set session transaction isolation level repeatable read;
SELECT @@SESSION.transaction_isolation, @@SESSION.transaction_read_only;

## drop and create table, then prepare the data
use mydb;
drop  table if exists t;
CREATE TABLE t (a INT NOT NULL, b INT, c int, primary key(a),  index (b)) ENGINE = InnoDB;
INSERT INTO t VALUES (1,33,555),(4,66,88),(7,99,1111),(10,1212,1414),(1313,1515,1717);
show index from t;


## -------------------------------------with unique index-----------------------------------------
### found
START TRANSACTION;
UPDATE t SET b = b WHERE a = 4; # record lock 4
rollback;

### not found
START TRANSACTION;
UPDATE t SET b = b WHERE a = 6; # gap lock:(4,7)
rollback;

### range search: min range of the combination of record lock ,next-key lock, gap lock
START TRANSACTION;
UPDATE t SET b = b WHERE a between 7 and 11; # record lock 7, next_key lock (7,10], gap lock (10,1313)
UPDATE t SET b = b WHERE a between 2 and 11; # next-key lock (1,4],(4,7],(7,10],gap lock (10,1313)
rollback;

### insert
start transaction;
insert into t (a,b,c) values (8,67,35);
rollback;

### select 
### found
START TRANSACTION;
select * from t  WHERE a = 4 for update;# record lock 4
rollback;

### not found
START TRANSACTION;
select * from t WHERE a = 6 for share; # gap lock:(4,7)
rollback;

### range search: min range of the combination of record lock ,next-key lock, gap lock
START TRANSACTION;
select * from t WHERE a between 7 and 11 for share; # record lock 7, next_key lock (7,10], gap lock (10,1313)
select * from t WHERE a between 2 and 11 for share; # next-key lock (1,4],(4,7],(7,10],gap lock (10,1313)
rollback;

### ----------------------------conclusion-------------------------------------------------------
### delete(really considered as update),update and select for share or update statement : min range, record lock,gap lock, next-key lock
### insert statement: insert intention lock before insert, then record lock

## -------------------------------------with non-unique index-----------------------------------------
### -----------------------------------------update-----------------------------------
### found
START TRANSACTION;
UPDATE t SET b = b WHERE b = 66; # the non-unique index: next-key lock (33,66], gap lock (66,99) and the match clustered index'condition is the same as the unique index for preventing modify and query the row by the clustered index without using the non-unique index
rollback;

### not found
START TRANSACTION;
UPDATE t SET b = b WHERE b = 77; # the non-unique index: gap lock:(66,99) and no match clustered index, so no necessary to lock clustered index 
rollback;

### range search: only next-key lock but not the min conbination(why not)
START TRANSACTION;
UPDATE t SET b = b WHERE b between 99 and 1414; # the non-unique index: next-key lock (66,99],(99,1212],(1212,1515] (why not gap lock) and the match clustered index'condition is the same as the unique index
UPDATE t SET b = b WHERE b between 44 and 1111; # the non-unique index: next-key lock (33,66],(66,99],(99,1212] (why not gap lock) and the match clustered index'condition is the same as the unique index
rollback;

### ------------------------------select ..... for share or update-----------------------------------
### found
START TRANSACTION;
select * from t  WHERE b = 66 for update;# the same as the update statement
rollback;

### not found
START TRANSACTION;
select * from t WHERE b = 77 for share; # the same as the udpate statement
rollback;

### range search: the same as the udpate statement
START TRANSACTION;
select * from t WHERE b between 99 and 1414 for share; # the same as the udpate statement
select * from t WHERE b between 44 and 1111 for share; # the same as the udpate statement
rollback;

### ----------------------------conclusion-------------------------------------------------------
### 1. delete(really considered as update),update and select for share or update statement :
###  	-in Equivalent query: when found, next-key lock and gap lock include the index,and the match clustered index'condition is the same as the unique index 
###		 for preventing modify and query the row by the clustered index without using the non-unique index, when not found, gap lock, no gap lock in clustered index
###		-in range query: only the next-key lock, not min conbination of various lock

## -------------------------------------with no index, just general column-----------------------------------------
### -----------------------------------------update-----------------------------------
### found
START TRANSACTION;
UPDATE t SET b = b WHERE c = 88; # (min,1],(1,4],(4,7],(7,10],(10,1313],(1313,max] next-key lock locks all clustered index because of column no order to not identify the range
rollback;

### not found
START TRANSACTION;
UPDATE t SET b = b WHERE c = 99; # ditto
rollback;

### range search
START TRANSACTION;
UPDATE t SET b = b WHERE c between 1111 and 1616; # ditto
UPDATE t SET b = b WHERE c between 77 and 1313; # ditto
rollback;

### ------------------------------select ..... for share or update-----------------------------------
### found
START TRANSACTION;
select * from t  WHERE c = 88 for update;# the same as the update statement
rollback;

### not found
START TRANSACTION;
select * from t WHERE c = 99 for share; # the same as the udpate statement
rollback;

### range search: the same as the udpate statement
START TRANSACTION;
select * from t WHERE c between 1111 and 1616 for share; # the same as the udpate statement
select * from t WHERE c between 77 and 1313 for share; # the same as the udpate statement
rollback;

### ----------------------------conclusion-------------------------------------------------------
### next-key lock locks all clustered index because of column no order to not identify the range