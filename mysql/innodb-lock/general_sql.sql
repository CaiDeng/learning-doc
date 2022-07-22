# query block lock and transaction
SELECT 
    waiting_trx_id,waiting_pid,waiting_query,blocking_trx_id,blocking_pid,blocking_query
FROM sys.innodb_lock_waits;

# query transaction
SELECT 
	trx_id, trx_state, trx_query
FROM INFORMATION_SCHEMA.INNODB_TRX; 

# query lock
SELECT 
    ENGINE_LOCK_ID,ENGINE_TRANSACTION_ID,LOCK_TYPE,LOCK_MODE,LOCK_STATUS,LOCK_DATA,OBJECT_SCHEMA,OBJECT_NAME,INDEX_NAME
FROM performance_schema.data_locks;

# query block lock  
SELECT 
    REQUESTING_ENGINE_TRANSACTION_ID,REQUESTING_ENGINE_LOCK_ID,BLOCKING_ENGINE_LOCK_ID,BLOCKING_ENGINE_TRANSACTION_ID
FROM performance_schema.data_lock_waits;