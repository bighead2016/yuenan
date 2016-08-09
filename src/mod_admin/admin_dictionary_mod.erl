%% Created: 2013-5-30
%% Description: TODO: Add description to admin_dictionary_mod
-module(admin_dictionary_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.task.hrl").

-include_lib("stdlib/include/ms_transform.hrl").

%%
%% Exported Functions
%%
-export([init_dictionary/0]).

%%
%% API Functions
%%
init_dictionary() ->
	try
		?ok	= init_dictionary_cost(),
		?ok	= init_dictionary_goods(),
		?ok	= init_dictionary_map(),
		?ok	= init_dictionary_task(),
		?ok	= init_dictionary_open_sys(),
		?ok	= init_dictionary_task_open_sys(),
        ?ok = init_dictionary_partner(),
		?ok	= init_dictionary_active_time(),
        ?ok = init_dictionary_sys_name(),
		?ok
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~nProcessInfo:~p~n",
					   [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
			{Error, Reason}
	end.

%% 初始化技术中心数据库表--消费点字典（货币）
init_dictionary_cost() ->
    List    = misc_app:get_data_list("/cost/cost.yrl"),
    L2      = [[Id, Explain]||{_, Id, Explain}<-List],
    init_dictionary(techcenter_cost, [consume_id, consume_explain], L2).

%% 初始化技术中心数据库表--物品
init_dictionary_goods() ->
    GoodsList   = data_goods:get_goods_list(),
    L2      = [begin
                Goods = data_goods:get_goods(GoodsId),
                [Goods#goods.goods_id, Goods#goods.name, Goods#goods.type, Goods#goods.sub_type, Goods#goods.lv, Goods#goods.pro, Goods#goods.sex, Goods#goods.color]
                end||
                GoodsId<-GoodsList],
    init_dictionary(techcenter_goods, [id, name, type, subtype, lv, pro, sex, color], L2).

%% 初始化技术中心数据库表--地图
init_dictionary_map() ->
    MapList     = data_map:get_map_list(),
    L2      = [begin
                RecMap      = data_map:get_map(MapId),
                [RecMap#rec_map.map_id, RecMap#rec_map.name]
                end||
                MapId<-MapList],
    init_dictionary(techcenter_map, [id, name], L2).

%% 初始化技术中心数据库表--任务
init_dictionary_task() ->
    TaskList    = data_task:get_all(),
    L2      = [begin
                Task        = data_task:get_task(TaskId),
                [Task#task.id, Task#task.name, Task#task.lv_min, Task#task.prev, Task#task.idx, Task#task.type]
                end||
                TaskId<-TaskList],
    init_dictionary(techcenter_task, [task_id, task_name, task_lv, prev_task_id, task_id_order, task_type], L2).

%% 初始化技术中心数据库表--开启模块
init_dictionary_open_sys() ->
    ModuleList  = data_guide:get_module_list(),
    L2      = [begin
                [Mod, Name]
                end||
                {Mod, Name}<-ModuleList],
    init_dictionary(techcenter_open_sys, [id, data], L2).

%% 初始化技术中心数据库表--任务开启模块
init_dictionary_task_open_sys() ->
    TaskList    = data_task:get_all(),
    L2      = [begin
                Task        = data_task:get_task(TaskId),
                [Task#task.id, Task#task.open_sys, Task#task.open_sys_2]
                end||
                TaskId<-TaskList],
    L3         = [[Id, Sys, Sys2]||[Id, Sys, Sys2]<-L2, Sys =/= 0 orelse Sys2 =/= 0],
    init_dictionary(techcenter_task_open_sys, [task_id, open_sys, open_sys_2], L3).

%% 初始化技术中心数据库表--武将
init_dictionary_partner() ->
    PartnerList = data_partner:get_all(),
    L2      = [begin
                Partner = data_partner:get_base_partner(PartnerId),
                [
                    Partner#partner.partner_id,
                    Partner#partner.partner_name,
                    Partner#partner.color
                ]
                end||
                PartnerId<-PartnerList],
    init_dictionary(techcenter_partner, [partner_id, partner_name, partner_color], L2).

%% 初始化技术中心数据库表--活动开启时间
init_dictionary_active_time() ->
    PlId    = config:read_deep([server, base, platform_id]),
    if
        PlId =:= 11 orelse PlId =:= 14 ->
            List    = misc_app:get_data_list("zh_TW/active/active.time.yrl"),
            L2      = [[Id, SysId, Start, End]||
                        {_Null, Id, SysId, Start, End}<-List],
            init_dictionary(techcenter_campaign_time, [id, sys_id, start, 'end'], L2);
        ?true ->
            List    = misc_app:get_data_list("zh_CN/active/active.time.yrl"),
            L2      = [[Id, SysId, Start, End]||
                        {_Null, Id, SysId, Start, End}<-List],
            init_dictionary(techcenter_campaign_time, [id, sys_id, start, 'end'], L2)
    end.
        

%% 初始化技术中心数据库表--活动常量
init_dictionary_sys_name() ->
    List = data_guide:get_module_list(),
    List2 = mix_sys_lv(List, []),
    L2      = [[SysId, Name, Lv]||
                {SysId, Name, Lv}<-List2],
    init_dictionary(techcenter_sys_name, [sys_id, name, lv], L2).

%%
%% Local Functions
%%
truncate(TableName) ->
	mysql_api:execute("TRUNCATE TABLE " ++ misc:to_list(TableName) ++ ";").

insert(TableName, FieldList, ValueList) ->
    try
    	case mysql_api:insert(TableName, FieldList, ValueList) of
            {?ok, _, _} ->
                ok;
            {?error, ErrorCode} ->
                ?MSG_ERROR("~s~n~p|~p|~p", [ErrorCode, TableName, FieldList, ValueList]),
                ?error
        end
    catch
        Type:Y ->
            ?MSG_ERROR("~p~n~p~n~p|~p|~p~n~p", [Type, Y, TableName, FieldList, ValueList, erlang:get_stacktrace()]),
            ?error
    end.

mix_sys_lv([{0 = SysId, <<"初始">> = Name}|Tail], OldList) ->
    Name2 = Name,
    List = [{SysId, Name2, 0}|OldList],
    mix_sys_lv(Tail, List);
mix_sys_lv([{SysId, Name}|Tail], OldList) ->
    Name2 = Name,
    SysRank = data_guide:get_task_rank(SysId),
    List  =  
        case data_task:get_sysid_lv(SysRank) of
            ?null ->
                [{SysId, Name2, 0}|OldList];
            Lv ->
                [{SysId, Name2, Lv}|OldList]
        end,
    mix_sys_lv(Tail, List);
mix_sys_lv([], List) -> List.

init_dictionary(Table, FieldList, DataList) ->
    truncate(Table),
    init_dictionary_2(Table, FieldList, DataList, 0).

init_dictionary_2(Table, FieldList, [Data|Tail], Count) ->
    insert(Table, FieldList, Data),
    init_dictionary_2(Table, FieldList, Tail, Count + 1);
init_dictionary_2(Table, _FieldList, [], Count) ->
    Sql = lists:concat(["select count(*) from `", Table, "`;"]),
    case mysql_api:select(Sql) of
        {?ok, [[Count]]} -> ?ok;
        {?ok, [[CountDB]]} ->
            ?MSG_ERROR("!err[not eq]:Table[~p], Count:~p CountDB:~p", [Table, Count, CountDB]),
            {?error, ?TIP_COMMON_SYS_ERROR};
        {?error, Error} ->
            ?MSG_ERROR("!err[db]:Error:~p", [Error]),
            {?error, ?TIP_COMMON_ERROR_DB}
    end.