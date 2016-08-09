%% MySQL result record:
-record(mysql_result,{
					  	fieldinfo		= [],
					  	rows			= [],
					  	affectedrows	= 0,
						lastinsertid	= 0,
					  	error			= ""
					 }). 
-record(mysql_state, {
					  	pool_ready		= [], 
						pool_working	= [],
						queue			= []
					 }).
-record(mysql_side, {
						ver	  	= null,
						socket 	= null,
						bin_acc = <<>>,					
					  	host, port, username, password, database, charset
					 }).

%% MSG
-define(MSG_MYSQL(S,D,Lv),			0).
%% -define(MSG_MYSQL(S,D,Lv),			io:format(S,D,Lv,?MODULE,?LINE)).
%%--------------------------------------------------------------------
%% Macros
%%--------------------------------------------------------------------
-define(LONG_PASSWORD, 				1).
-define(LONG_FLAG, 					4).
-define(PROTOCOL_41, 				512).
-define(CLIENT_MULTI_STATEMENTS, 	65536).
-define(CLIENT_MULTI_RESULTS, 		131072). 
-define(TRANSACTIONS, 				8192).
-define(SECURE_CONNECTION, 			32768).

-define(MAX_PACKET_SIZE, 			1000000).

-define(CONNECT_TIMEOUT, 			30000).
-define(CONNECT_WITH_DB, 			8).

-define(FETCH_TIMEOUT, 				2000).


-define(DEFAULT_STANDALONE_TIMEOUT, 15000).
-define(MYSQL_QUERY_OP, 			3).
-define(MYSQL_4_0, 					40). %% Support for MySQL 4.0.x
-define(MYSQL_4_1, 					41). %% Support for MySQL 4.1.x et 5.0.x

%% Used by transactions to get the state variable for this connection
%% when bypassing the dispatcher.
-define(STATE_VAR, 					mysql_connection_state).
%% Macros
-define(LOCAL_FILES, 				128).
-define(MYSQL_PORT, 		 		3306).

-define(ETS_STAT_DB,                ets_stat_db). % sql统计
-define(DB_POOL,                    db_pool).

-define(DB,             db_mysql).
-define(ETS_STAT_MYSQL, ets_stat_db).
%%Mysql数据库连接 

%%Mysql连接数
-define(DBCONNECT_COUNT,12).

-define(DB_MODULE,      db_mysql).
