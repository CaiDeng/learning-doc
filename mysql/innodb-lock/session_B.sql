# test lock type diffrence of SELECT,INSERT,update,delete in the condition of read commited

## set transaction or repeated-read
set session transaction isolation level read committed;
SELECT @@SESSION.transaction_isolation, @@SESSION.transaction_read_only;

## for example:InnoDB holds locks only for rows that it updates or deletes
## session B update
UPDATE t SET b = 4 WHERE b = 2; # not blocked by lock


#------------------------------------
# test lock type diffrence of SELECT,INSERT,update,delete in the condition of repeated-read isolation level

## set transaction read committed or repeated-read
set session transaction isolation level repeatable read;
SELECT @@SESSION.transaction_isolation, @@SESSION.transaction_read_only;

## session B update in unique index
UPDATE t SET b = b WHERE a = 4; 
UPDATE t SET b = b WHERE a = 7; 
### NOT FOUND
START transaction;
insert into t (a,b,c) values (8,67,35);
delete from t where a=8;
ROLLBACK;

## session B update in unique index with range search
UPDATE t SET b = b WHERE a > 8 ;


## session B update in non-unique index
UPDATE t SET c = c WHERE b = 66;
START transaction;
insert into t (a,b,c) values (5,44,88);
insert into t (a,b,c) values (5,88,88);
insert into t (a,b,c) values (6,99,99);
insert into t (a,b,c) values (8,1010,1010);
insert into t (a,b,c) values (9,1212,1212);
insert into t (a,b,c) values (11,1313,1515);
ROLLBACK;



## session A update in no index 
UPDATE t SET b = b WHERE c = 8;

## session B insert
insert into t (a,b) values (19,21);

select * from t;


