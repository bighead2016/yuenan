%%% 处理sql
-module(combine_db_mod).

-include("../../include/const.common.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([execute/2]).

execute(SqlPhase, DbIdList) ->
    execute(SqlPhase, DbIdList, [], 5).
    
execute(SqlPhase, [DbId|Tail], OldList, Times) when Times > 0 ->
%%     ?MSG_SYS("~p", [SqlPhase]),
    ResultList = 
        case get_sql(SqlPhase) of
            <<>> ->
                [];
            Sql ->
%%                 ?MSG_SYS("[~s]", [Sql]),
                case mysql_single_api:select(Sql, DbId) of
                    {?ok, DataList} -> DataList;
                    {?ok, DataList, _} -> DataList;
                    {timeout, _} -> 
                        ?MSG_SYS("err|time out|last ~p times", [Times]),
                        execute(SqlPhase, [DbId|Tail], OldList, Times-1);
                    X               -> 
                        ?MSG_SYS("err|~p", [X]),   
                        []
                end
        end,
    execute(SqlPhase, Tail, [{DbId, ResultList}|OldList], Times);
execute(_, L, _, Times) when [] =/= L andalso Times =< 0 ->
    ?MSG_SYS("err|time out for 5 times", []),
    [];
execute(_, [], List, _) ->
    List.

%% ====================================================================
%% Internal functions
%% ====================================================================
%% 读取sql
% show
get_sql(show_all_tables) ->
    <<"show tables;">>;
get_sql({desc, TableName}) ->
    <<"desc `", (misc:to_binary(TableName))/binary, "`;">>;
get_sql({show_create_table, TableName}) ->
    <<"show create table ", (misc:to_binary(TableName))/binary, ";">>;
% select
get_sql(select_effective_user) ->
    <<"select * from `game_user` where not (`cash_sum` <= '0' and `lv` <= '30' and unix_timestamp() - `logout_time_last` > '86400'*'20');">>;
get_sql({select, Db, Table, "", Fields}) ->
	<<"select ", (misc:to_binary(Fields))/binary, " from `", (misc:to_binary(Db))/binary, "`.`", 
      (misc:to_binary(Table))/binary, "` ;">>;
get_sql({select, Db, Table, Where, Fields}) ->
	<<"select ", (misc:to_binary(Fields))/binary, " from `", (misc:to_binary(Db))/binary, "`.`", 
      (misc:to_binary(Table))/binary, "` where ",
      (misc:to_binary(Where))/binary, " ;">>;
get_sql({select_count, Table}) ->
	<<"select count(*) from `", (misc:to_binary(Table))/binary, "` ;">>;
% insert
get_sql({insert, Table, Fields, Values}) ->
    <<"insert into `", (misc:to_binary(Table))/binary, "` (", (misc:to_binary(Fields))/binary, 
      ") values(", (misc:to_binary(Values))/binary, ");">>;
get_sql({insert, Table}) ->
    <<"insert into `db_table_state` (`table_name`) values ('",
      (misc:to_binary(Table))/binary, "');">>;
get_sql({insert_all, Table, Db, TableFrom, Fields}) ->
    <<"insert into `", (misc:to_binary(Table))/binary, "` ( ", (misc:to_binary(Fields))/binary, ") select ", (misc:to_binary(Fields))/binary, 
      " from `", (misc:to_binary(Db))/binary, "`.`",
      (misc:to_binary(TableFrom))/binary, "`;">>;
get_sql({insert_all_where, Table, Db, TableFrom, Fields, ""}) ->
    <<"insert into `", (misc:to_binary(Table))/binary, "` ( ", (misc:to_binary(Fields))/binary, ") select ", (misc:to_binary(Fields))/binary, 
      " from `", (misc:to_binary(Db))/binary, "`.`",
      (misc:to_binary(TableFrom))/binary, "` ;">>;
get_sql({insert_all_where, Table, Db, TableFrom, Fields, Where}) ->
    <<"insert into `", (misc:to_binary(Table))/binary, "` ( ", (misc:to_binary(Fields))/binary, ") select ", (misc:to_binary(Fields))/binary, 
      " from `", (misc:to_binary(Db))/binary, "`.`",
      (misc:to_binary(TableFrom))/binary, "` where ",
      (misc:to_binary(Where))/binary, " ;">>;
get_sql({insert_all, Table, Db, TableFrom, Fields, Order}) ->
    <<"insert into `", (misc:to_binary(Table))/binary, "` ( ", (misc:to_binary(Fields))/binary, ") select ", (misc:to_binary(Fields))/binary, 
      " from `", (misc:to_binary(Db))/binary, "`.`",
      (misc:to_binary(TableFrom))/binary, "` ", (misc:to_binary(Order))/binary, ";">>;
% update
get_sql({update_db, Table, Len}) ->
    <<"update `db_table_state` set `total` = `total`+ '", (misc:to_binary(Len))/binary, 
      "' where `table_name` = '", (misc:to_binary(Table))/binary, "' ">>;
get_sql({update, Table, Field, Value, Where}) ->
    <<"update `", (misc:to_binary(Table))/binary, "` set `", 
      (misc:to_binary(Field))/binary, "` = '", (misc:to_binary(Value))/binary, "' ",
      " where ", (misc:to_binary(Where))/binary, " ;">>;
get_sql({update_bin, Table, Field, Value, Where}) ->
    <<"update `", (misc:to_binary(Table))/binary, "` set `", 
      (misc:to_binary(Field))/binary, "` = ", (misc:to_binary(Value))/binary, " ",
      " where ", (misc:to_binary(Where))/binary, " ;">>;
get_sql({update_name, Table, Field, Value1, Value2}) ->
    <<"update `", (misc:to_binary(Table))/binary, "` set `", 
      (misc:to_binary(Field))/binary, "` = '", (misc:to_binary(Value2))/binary, "' ",
      " where `", (misc:to_binary(Field))/binary, "` = '", (misc:to_binary(Value1))/binary, "';">>;
get_sql(update_game_boss_max) ->
    <<"insert into `game_boss` select * from `game_boss_tmp` order by `lv` desc limit 1;">>;
% x
get_sql({drop_table, TableName}) ->
    <<"drop table if exists `", (misc:to_binary(TableName))/binary, "`;">>;
get_sql({truncate_table, TableName}) ->
    <<"truncate table `", (misc:to_binary(TableName))/binary, "`;">>;
get_sql({create_table, 'db_name_info'}) ->
    <<"CREATE TABLE if not exists `db_name_info` (",
      " `name` char(64) NOT NULL default '' COMMENT '', ", 
      " `count` int(10) NOT NULL default '1' comment '', ",
      " `serv_list` longblob not null comment '', ", 
      " PRIMARY KEY  (`name`) ", 
      " ) ENGINE=InnoDb DEFAULT CHARSET=utf8;">>;
get_sql({create_table, 'game_change_name'}) ->
    <<"CREATE TABLE if not exists `game_change_name` (",
      " `user_id` int(20) NOT NULL, ", 
      " `is_changed` int(1) default '0', ", 
      " PRIMARY KEY  (`user_id`) ", 
      " ) ENGINE=InnoDb DEFAULT CHARSET=utf8;">>;
get_sql({create_table, 'game_change_name_guild'}) ->
    <<"CREATE TABLE if not exists `game_change_name_guild` (",
      " `guild_id` int(20) NOT NULL, ", 
      " `is_changed` int(1) default '0', ", 
      " PRIMARY KEY  (`guild_id`) ", 
      " ) ENGINE=InnoDb DEFAULT CHARSET=utf8;">>;
get_sql({create_table, 'game_boss_tmp'}) ->
    <<"CREATE TABLE `game_boss_tmp` (",
      " `lv` int(10) NOT NULL, ", 
      " PRIMARY KEY (`lv`) ",
      " ) ENGINE=InnoDB DEFAULT CHARSET=utf8;">>;
get_sql({create_table, 'game_config'}) ->
    <<"CREATE TABLE `game_config` ( ",
      " `combine_reward` int(2) NOT NULL COMMENT '', ",
      " `version` char(255) not null comment '' ",
      " ) ENGINE=InnoDB DEFAULT CHARSET=utf8;">>;
get_sql({create_table, 'game_arena_member_tmp'}) ->
    <<"CREATE TABLE if not exists `game_arena_member_tmp` ( ",
    " `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT 'id', ",
    " `player_name` varchar(50) NOT NULL DEFAULT '' COMMENT '', ",
    " `player_sex` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
    " `player_lv` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `player_career` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
    " `rank` bigint(20) NOT NULL  AUTO_INCREMENT  COMMENT '' , ",
    " `times` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `winning_streak` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `cd` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `fight_force` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `open_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
    " `daily_buy_time` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `clean_times_time` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `on_line_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
    " `sn` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `streak_wining_reward` varchar(200) NOT NULL DEFAULT '[]' COMMENT '', ",
    " `daily_max_win` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
    " `max_win` int(11) NOT NULL COMMENT '', ",
    " `meritorious` int(11) NOT NULL, ",
    " `score` int(11) NOT NULL COMMENT '', ",
    " `daily_target` int(11) NOT NULL COMMENT '', ",
    " `target_state` int(4) NOT NULL COMMENT '', ",
    " PRIMARY KEY (`rank`), ",
    " KEY `rank` (`rank`) USING HASH ",
    " ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='';">>;
get_sql({create_table, Sql}) ->
    misc:to_binary(Sql);
get_sql(create_tab_db) ->
    <<"create table if not exists `db_table_state`(`table_name` char(127) NOT NULL COMMENT '',",
      " `count` int(20) NOT NULL default '0' ,", 
      " `total` int(20) NOT NULL default '0' COMMENT '',",
      " PRIMARY KEY  (`table_name`), ", 
      " KEY `table_name` USING HASH (`table_name`) ",  
      " ) ENGINE=InnoDb DEFAULT CHARSET=utf8;">>;
get_sql({drop_db, DbName}) ->
    <<"drop database if exists `", (misc:to_binary(DbName))/binary, "`;">>;
get_sql({create_db, DbName}) ->
    <<"create database if not exists `", (misc:to_binary(DbName))/binary, "`;">>;
get_sql({alter_table, Table, Field1, Desc, Field2}) ->
    <<"alter table `", (misc:to_binary(Table))/binary, "` change `", (misc:to_binary(Field1))/binary, "` ", 
      (misc:to_binary(Desc))/binary, " after `", (misc:to_binary(Field2))/binary, "`;">>;
get_sql({show_column, Db, Table, Field}) ->
    <<"select `column_name`,`column_type`,`is_nullable`, `column_default`, `column_comment` from `information_schema`.`COLUMNS` where `TABLE_SCHEMA`='",
      (misc:to_binary(Db))/binary, "' and `table_name` = '", (misc:to_binary(Table))/binary, "' and `column_name` = '", (misc:to_binary(Field))/binary, "';">>;
% other
get_sql({execute, Sql}) ->
    misc:to_binary(Sql);
get_sql(_) ->
    <<>>.









