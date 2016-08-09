%%% 其他数据生成器
-module(misc_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").


%%
%% Exported Functions
%%
-export([generate/1]).
-export([change_table_version/1, change_server_info/1, change_plat_list/1]).

%%
%% API Functions
%%
%% misc_data_generator:generate().
generate(Ver)	->
    % 当前数据库版本列表
	FunDatas1	= {get_db_version_list, "db", "table_version.yrl", ?null, ?MODULE, change_table_version, ?null},
	FunDatas2	= {get_server_info, "server", "server_info.yrl", [#rec_server_info.platform_id, #rec_server_info.serv_id], ?MODULE, ?null, ?null},
	FunDatas3	= {get_combine_list, "server", "server_info.yrl", ?null, ?MODULE, change_server_info, ?null},
	FunDatas4	= {get_info_list, "server", "server_info.yrl", ?null, ?MODULE, ?null, ?null},
	FunDatas5	= generate_node_combine_list(get_node_combine_list, Ver),
	FunDatas6	= {get_platform_info, "server", "platform_info.yrl", [#rec_platform_info.platform_id], ?MODULE, ?null, ?null},
	FunDatas7	= {get_platform_list, "server", "platform_info.yrl", ?null, ?MODULE, change_plat_list, ?null},
    misc_app:make_gener(data_misc, 
                        [], 
                        [FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, FunDatas6, FunDatas7], Ver).


%%
%% Local Functions
%%

change_table_version(Data) ->
    change_table_version(Data, []).

change_table_version([D|Tail], OldList) ->
    change_table_version(Tail, [D#rec_table_version{table_name = misc:to_atom(D#rec_table_version.table_name)}|OldList]);
change_table_version([], List) ->
    lists:reverse(List).

%% 修正合服号
change_server_info(Data) ->
    change_server_info(Data, []).

change_server_info([#rec_server_info{serv_id = Sid, combined = Cid, platform_id = PlatId}|Tail], OldList) ->
    List = 
        case lists:keytake({Cid, PlatId}, 1, OldList) of
            {value, {_, L}, OldList2} ->
                [{{Cid, PlatId}, [Sid|L]}|OldList2];
            _ ->
                [{{Cid, PlatId}, [Sid]}|OldList]
        end,
    change_server_info(Tail, List);
change_server_info([], List) ->
    lists:reverse(List).

generate_node_combine_list(FunName, Ver) ->
    Datas  = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/server/server_info.yrl"),
    Datas2 = change_server_info(Datas),
    generate_node_combine_list(FunName, Datas2, []).

generate_node_combine_list(FunName, [{Cid, SList}|Datas], Acc) ->
    Key     = Cid,
    Value   = SList,
    When    = ?null,
    generate_node_combine_list(FunName, Datas, [{Key, Value, When}|Acc]);
generate_node_combine_list(FunName, [], Acc) -> {FunName, lists:reverse(Acc)}.

change_plat_list(Data) -> [{PlatId, CNode, Plat}||#rec_platform_info{platform_id = PlatId, center_node = CNode, platform = Plat}<-Data].
