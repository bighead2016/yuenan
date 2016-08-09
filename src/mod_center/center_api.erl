%%% 
-module(center_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([update_account/4, is_elder/2, get_node/1]).
-export([update_account_cb/3, is_elder_cb/2]).
-export([init/0]).
-export([chk_gift/1, del_code/1, rollback/1, gen_code/4, get_center_node/0]).
-export([sync_serv_info/1, get_serv_info/1, update_serv_info/1, save_serv_info/0, get_all_serv_info/0,
		 stop_center/1, try_stop_center/0, check_serv_info/0, check_serv_info/1,
         get_all_node/0]).

%%
%% API Functions
%%

%% 更新帐户信息
update_account(Account, Lv, ServId, UserId) when Lv >= 35 ->
    case config:read(platform_info, #rec_platform_info.center_node) of
        ?null ->
            ?ok;
        CenterNode ->
            case net_adm:ping(misc:to_atom(CenterNode)) of
                pong ->
                    rpc:cast(misc:to_atom(CenterNode), ?MODULE, update_account_cb, [Account, ServId, UserId]);
                pang ->
                    ?ok
            end
    end;
update_account(_Account, _Lv, _ServId, _UserId) ->
    ?ok.

%%  查询帐户信息
is_elder(Account, ServId) ->
    center_elder_mod:is_elder(Account, ServId).

%%-------------------------------------center_serv--------------------------------------------------
update_account_cb(Account, ServId, UserId) ->
    center_elder_mod:update_account_cb(Account, ServId, UserId).

is_elder_cb(Account, ServId) ->
    center_elder_mod:is_elder_cb(Account, ServId).


init() ->
	cross_init(),
    center_mod:initial_ets_player_code(),
	init_serv_info(),
    center_elder_mod:init().

cross_init() ->
	 cross_arena_data_api:init_cross_arena_member(),
	 cross_arena_data_api:init_cross_arena_phase(),
	 cross_arena_data_api:init_cross_arena_report(),
	 cross_arena_data_api:init_cross_arena_group_report(),
     cross_arena_data_api:init_cross_arena_robot(),
	 ?ok.

%% 读取中心结点
get_center_node() ->
    config:read(center_node).

%%===============================================================================
%% 读取激活码对应礼包信息
chk_gift(CodeUpper) ->
    CenterNode = get_center_node(),
    case rpc:call(CenterNode, center_gift_media_card_serv, chk_gift_call, [CodeUpper]) of
        {?ok, GiftType, Gift} ->
            ?MSG_DEBUG("gift=[~p|~p]", [GiftType, Gift]),
            {?ok, GiftType, Gift};
        {badrpc, nodedown} ->
            {?error, ?TIP_COMMON_ERR_NET};
        _ ->
            {?error, ?TIP_COMMON_BAD_SING}
    end.

rollback(CodeUpper) ->
    CenterNode = get_center_node(),
    case rpc:call(CenterNode, center_gift_media_card_serv, rollback_call, [CodeUpper]) of
        {badrpc, nodedown} ->
            {?error, ?TIP_COMMON_ERR_NET};
        _ ->
            ?ok
    end.

del_code(CodeUpper) ->
    CenterNode = get_center_node(),
    case rpc:call(CenterNode, center_gift_media_card_serv, del_code_call, [CodeUpper]) of
        {badrpc, nodedown} ->
            {?error, ?TIP_COMMON_ERR_NET};
        _ ->
            ?ok
    end.
%% gen_code(1, 6, 2000, []). 
gen_code(Key, Type, Count, ArgList) ->
    CenterNode = get_center_node(),
    case rpc:call(CenterNode, center_gift_media_card_serv, generate_code_cast, [Key, Type, Count, ArgList]) of
        {badrpc, nodedown} ->
            {?error, ?TIP_COMMON_ERR_NET};
        _ ->
            ?ok
    end.

%%====================================================================================
%% 同步服务器信息到中心节点
sync_serv_info(State) ->
	OpenTime = misc:date_time_to_stamp(config:read_deep([server, release, start_time])),
	case misc:seconds() >= OpenTime of
		?false ->
			?ok;
		?true ->
			?MSG_ERROR("sync server info State:~p", [State]),
			CenterNode	= get_center_node(),
			SId			= config:read_deep([server, base, sid]),
%% 			PlatId   	= config:read_deep([server, base, platform_id]),
			NodeList    = config:read(combine), %   data_misc:get_node_combine_list({SId, PlatId}),
			StateList   = 
				if
					?null =/= NodeList ->
						[{Cid, node(), State}||Cid<-NodeList, is_integer(Cid)];
					?true ->
						[{SId, node(), State}]
				end,
			erlang:send({center_serv_info_serv, CenterNode}, {recv, StateList})
	end.

%% 根据服务器id获取节点信息
get_serv_info(SId) ->
	try
		CenterNode	= get_center_node(),
        case net_adm:ping(CenterNode) of
            pong ->
        		case gen_server:call({center_serv_info_serv, CenterNode}, {get, SId}, ?CONST_TIMEOUT_CALL) of
        			{NodeName, ?CONST_CENTER_STATE_NORMAL} ->
        				{NodeName, ?CONST_CENTER_STATE_NORMAL};
        			_ ->
        				{?error, ?CONST_CENTER_STATE_UNKNOWN}
        		end;
            pang ->
                {?error, ?CONST_CENTER_STATE_UNKNOWN}
        end
	catch
		X:Y ->
			?MSG_ERROR("X =~p, Y=~p, E =~p", [X, Y, erlang:get_stacktrace()]),
			{?error, ?CONST_CENTER_STATE_UNKNOWN}
	end.

%% 合服更新服务器信息
update_serv_info(ServList) ->
	CenterNode	= get_center_node(),
	erlang:send({center_serv_info_serv, CenterNode}, {update, {node(), ServList, ?CONST_CENTER_STATE_NORMAL}}).

%% 获取中心服务器对应的平台所有服务器信息
get_all_serv_info() ->
    try
        case catch center_serv_info_serv:get_all_serv_info_call() of
            {?ok, List} ->
                {?ok, List};
            {?error, ErrorCode} ->
                ?MSG_ERROR("err=[~p]", [ErrorCode]),
                {?error, ErrorCode};
            Err ->
                ?MSG_ERROR("err=[~p]", [Err]),
                {?error, ?TIP_COMMON_ERR_NET}
        end
    catch
        X:Y ->
            ?MSG_ERROR("err=[~p|~p]~n~p", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_ERR_NET}
    end.

%% desc:读取本平台所有结点列表
get_all_node() ->
    try
        case catch center_serv_info_serv:get_all_node_call() of
            {?ok, List} ->
                {?ok, List};
            {?error, ErrorCode} ->
                ?MSG_ERROR("err=[~p]", [ErrorCode]),
                {?error, ErrorCode};
            Err ->
                ?MSG_ERROR("err=[~p]", [Err]),
                {?error, ?TIP_COMMON_ERR_NET}
        end
    catch
        X:Y ->
            ?MSG_ERROR("err=[~p|~p]~n~p", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_ERR_NET}
    end.

%% 加载服务器信息
init_serv_info() ->
	ets:delete_all_objects(?CONST_ETS_SERV_INFO),
	FieldList = [sid, record],
	case mysql_api:select(FieldList, game_serv_info) of
		{?ok, ServList} ->
			F = fun([_ServId, BinRecord]) ->
						Rec	= mysql_api:decode(BinRecord),
						ets_api:insert(?CONST_ETS_SERV_INFO, Rec)
				end,
			[F(Serv) || Serv <- ServList];
		{?error, _ErrorCode} ->
			?ok
	end,
    ?ok.

%% 保存服务器信息
save_serv_info() ->
	try
		%% 保存前先清空数据
		Sql1 = <<"delete from `game_serv_info`">>,
		mysql_api:select(Sql1),
		ServInfos = ets:tab2list(?CONST_ETS_SERV_INFO),
		[save_serv_info(ServRec) || ServRec <- ServInfos]
	catch
		T:R ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [T, R, erlang:get_stacktrace()])
	end.

save_serv_info(ServRec) ->
	case mysql_api:select(<<"insert into `game_serv_info`(`sid`, `record`)value('", (misc:to_binary(ServRec#ets_serv_info.sid))/binary, 
							"',", (mysql_api:encode(ServRec))/binary, ");">>) of
		{?ok, _, _} ->
			?ok;
		X ->
			?MSG_ERROR("~p~n~p~n", [X, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 查看中心节点其他服务器信息
check_serv_info() ->
	ets_api:list(?CONST_ETS_SERV_INFO).

check_serv_info(SId) ->
	ets_api:lookup(?CONST_ETS_SERV_INFO, SId).
%%
%% Local Functions
%%
%% lookup_ets_center_node_info(ServId) ->
%%     ets_api:lookup(?CONST_ETS_CENTER_NODE_INFO, ServId).
%% 
%% %% insert_ets_center_node_info(Record) ->
%% %%     ets_api:insert(?CONST_ETS_CENTER_NODE_INFO, Record).
%% 
%% update_ets_center_node_info(Key, List) ->
%%     ets_api:update_element(?CONST_ETS_CENTER_NODE_INFO, Key, List).


%% 关闭远端结点
stop_center([CenterNode]) ->
	Self = node(),
	case net_adm:ping(misc:to_atom(CenterNode)) of
		pong ->
			X = rpc:call(misc:to_atom(CenterNode), ?MODULE, try_stop_center, []),
			?MSG_SYS("ok[~p|~p]: stop success[~p].............2/2~n", [Self, ?LINE, X]);
		pang ->
			?MSG_ERROR("center_node is pang~p", []),
			?ok
	end,
	erlang:halt(0, [{flush, false}]).

try_stop_center() ->
	Self = node(),
	catch cross_arena_data_api:refresh_daily_db(),
	catch tower_api:save_all(),
	catch copy_single_report_api:save_all(),
	catch center_api:save_serv_info(),
    ?MSG_SYS("ok[~p|~p]: write center cross arena db end.............1/2~n", [Self, ?LINE]),
    catch try_terminate_2(),
	erlang:halt(0, [{flush, false}]).

try_terminate_2() ->
    misc_sys:stop_apps([sanguo_center]),
    misc_app:processing_print(3).

%% 读取当前结点信息
get_node(Sid) ->
    case ets_api:lookup(?CONST_ETS_SERV_INFO, Sid) of
        #ets_serv_info{node_name = Node} ->
            Node;
        _ ->
            ?undefined
    end.
    
