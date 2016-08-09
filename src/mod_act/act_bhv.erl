%%% 运营活动行为
%%% key={UserId, {act, ActId}}/{UserId, {temp, TemplateId}}

-module(act_bhv).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("const.define.hrl").
-include_lib("const.protocol.hrl").

-include("record.base.data.hrl").
-include("record.act.hrl").
-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([behaviour_info/1]).
-export([init_all/0, login_packet/2, login/1, logout/1, zero/1, reg_mod/1]).
-export([cash_in/3, refresh/0, get_act_user/2, is_open/1, login_time_packet/0]).

-define(CONST_SYS_POINT_WITHOUT_ACT, [?CONST_COST_BOSS_ROBOT, 
                                      ?CONST_COST_SPRING_AUTO_CASH, 
                                      ?CONST_COST_PARTY_AUTO, 
                                      ?CONST_COST_WORLD_SET_ROBOT,
                                      ?CONST_COST_MARKET_SALE,
                                      ?CONST_COST_MARKET_RETURN,
                                      ?CONST_COST_MARKET_ONCE,
                                      ?CONST_COST_MARKET_ONCE_REWARD,
                                      ?CONST_COST_MARKET_ONCE_2,
                                      ?CONST_COST_MARKET_ADD,
                                      ?CONST_COST_MARKET_NORMAL_SALE,
                                      ?CONST_COST_GET_GOODS,
                                      ?CONST_COST_MARKET_NORMAL_SALE_2,
                                      ?CONST_COST_WLEFARE_BUY_FUND
                                      ]).

%%
%% API Functions
%%

behaviour_info(callbacks) ->
   [
        {init,         1}, 
        {over,         1}, 
        {login,        1}, 
        {login_packet, 2}, 
        {join,         2}, 
        {refresh,      2}, 
        {logout,       1}, 
        {offline,      2}
   ];
behaviour_info(_) ->
    undefined.

%% 0点
refresh() ->
    Now = misc:seconds(),
    Key = act_db_mod:sel_ets_time_key(?null),
    refresh(Key, Now),
	init_all(),
    ?ok.

refresh('$end_of_table', _) ->
    ?ok;
refresh(Key, Now) ->
	Mod = reg_mod(Key),
	catch Mod:refresh(Key),
    case act_db_mod:sel_ets_time(Key) of
        ?null ->
            ?ok;
        Rec ->
            case catch init(Rec, Now) of
                1 ->
                    case Rec#ets_act_info.reset_daily of
                        1 ->
                            UserKey = act_db_mod:sel_ets_act_user_key(?null),
                            do_over(UserKey, Rec#ets_act_info.id);
                        _ ->
                            act_db_mod:ins_ets_act_temp(#ets_act_tmp{act_id = Rec#ets_act_info.id, temp_id = Rec#ets_act_info.template}),
                            act_db_mod:upd_ets_time(Rec#ets_act_info.id, [{#ets_act_info.is_open, 1}])
                    end;
                _ ->
                    act_db_mod:upd_ets_time(Rec#ets_act_info.id, [{#ets_act_info.is_open, 0}]),
                    UserKey = act_db_mod:sel_ets_act_user_key(?null),
                    do_over(UserKey, Rec#ets_act_info.id)
            end
    end,
    Key2 = act_db_mod:sel_ets_time_key(Key),
    refresh(Key2, Now).

do_over('$end_of_table', _) ->
    ?ok;
do_over(Key, ActId) ->
    Mod = reg_mod(ActId),
    case catch act_db_mod:sel_ets_act_user(Key) of
        #ets_act_user{act_id = ActId, user_id = UserId} = Rec ->
            Mod:over(Rec),
            case data_act:get_act(ActId) of
                #rec_act_time{clear_over = 1} ->
                    Key2 = act_db_mod:sel_ets_act_user_key(Key),
                    act_db_mod:del_ets_act_user(Key),
                    do_over(Key2, ActId);
                _ ->
                    Mod:refresh(UserId, ActId),
                    Key2 = act_db_mod:sel_ets_act_user_key(Key),
                    do_over(Key2, ActId)
            end;
        _ ->
            Key2 = act_db_mod:sel_ets_act_user_key(Key),
            do_over(Key2, ActId)
    end.

%% 登录预处理
login(OldPlayer) ->
    List = data_act:get_act_list(),
    login_2(List, OldPlayer).

login_2([Id|Tail], OldPlayer) ->
    Mod = reg_mod(Id),
    Player = Mod:login(OldPlayer),
    login_2(Tail, Player);
login_2([], Player) ->
    Player.

%% 登录包
login_packet(OldPlayer, OldPacket) ->
    List = data_act:get_act_list(),
    login_packet_2(List, OldPlayer, OldPacket, <<>>).

login_packet_2([ActId|Tail], OldPlayer, P, OldPacket) ->
    Mod = reg_mod(ActId),
    {Player, Packet} = Mod:login_packet(OldPlayer, ActId),
    login_packet_2(Tail, Player, P, <<OldPacket/binary, Packet/binary>>);
login_packet_2([], Player, P, Packet) ->
	%% 活动时间
	Packet2 = login_time_packet(),
    {Player, <<Packet2/binary, P/binary, Packet/binary>>}.

login_time_packet()->
	case ets:select(?CONST_ETS_ACT_TEMP, [{#ets_act_tmp{temp_id='_',act_id='_'},[],['$_']}]) of
		[]->
			<<>>;
		Match ->
			Fun = fun(#ets_act_tmp{act_id = ActId}, Acc)->
						  case act_db_mod:sel_ets_time(ActId) of
							  #ets_act_info{start_time=Stime, stop_time=Etime} ->
								  [{Stime, Etime, ActId}|Acc];
							  _ ->
								  Acc
						  end
				  end,
			Cycle = lists:foldl(Fun, [], Match),
			misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_TIME_INFO, ?MSG_FORMAT_YUNYING_ACTIVITY_SC_TIME_INFO, [Cycle])
	end.

zero(Player)->
	misc_packet:send(Player#player.user_id, login_time_packet()).


%% 下线处理
logout(OldPlayer) ->
    List = data_act:get_act_list(),
    logout_2(List, OldPlayer).

logout_2([Id|Tail], OldPlayer) ->
    Mod = reg_mod(Id),
    case Mod:logout(OldPlayer) of
        #player{} = NewPlayer ->
            logout_2(Tail, NewPlayer);
        _ ->
            logout_2(Tail, OldPlayer)
    end;
logout_2([], Player) ->
    Player.

%%

init_all() ->
    Now = misc:seconds(),
    L  = [data_act:get_act(Id) || Id  <- data_act:get_act_list()],
    L2 = act_db_mod:sel_db_time(),
    {TaskClockList, RecActTimeList} = mix(L, L2, []),
    init_old(TaskClockList, [], Now),
    init_new(RecActTimeList, [], Now),
    ?ok.

%% 起服时洗数据
init(#ets_act_info{id = Id, start_time = StartTime, stop_time = StopTime} = ActTime, Now) ->
    try
        Mod = reg_mod(ActTime),
		?MSG_DEBUG("time S:~p ,E:~p, Now:~p", [StartTime, StopTime, Now]),
        case chk_time(StartTime, StopTime, Now) of
            1 -> % 未开始
                Mod:over(Id),
                0;
            2 -> % 进行中
                case data_act:get_act(Id) of
                    #rec_act_time{time_type = TimeType} when ?CONST_ACT_OPEN =/= TimeType andalso ?CONST_ACT_MIX =/= TimeType ->
                        OpenDates = misc_sys:open_dates(),
                        if
                            30 < OpenDates ->
                                Mod:init(Id),
                                1;
                            ?true ->
                                Mod:over(Id),
                                0
                        end;
                    _ ->
                        Mod:init(Id),
                        1
                end;
            3 -> % 已结束
                Mod:over(Id),
                0
        end
    catch
        _:_ ->
            0
    end;
init(_, _) ->
    0.

%%------------------------------激活条件--------------------------------------------
%% 充钱
cash_in(UserId, Cash, Point) ->
    case lists:member(Point, ?CONST_SYS_POINT_WITHOUT_ACT) of
        ?true ->
            ok;
        ?false ->
            handle_cash_in(UserId, Cash, Point, ?null),
            ok
    end.

handle_cash_in(_UserId, _Cash, _Point, '$end_of_table') ->
    ok;
handle_cash_in(UserId, Cash, Point, Key) ->
    case act_db_mod:sel_ets_time_key(Key) of
        '$end_of_table' ->
            ok;
        Key2 ->
            ActInfo = act_db_mod:sel_ets_time(Key2),
            case ActInfo of
                #ets_act_info{is_open = 1} ->
                    Mod = reg_mod(ActInfo),
                    case catch Mod:join(cash_in, [UserId, Cash, Point, ActInfo]) of
                        ?ok ->
                            ok;
                        _X ->
                            ok
                    end,
                    handle_cash_in(UserId, Cash, Point, Key2);
                _ ->
                    handle_cash_in(UserId, Cash, Point, Key2)
            end
    end.

handle_cash_out(_UserId, _Cash, _Point, '$end_of_table') ->
    ok;
handle_cash_out(UserId, Cash, Point, Key) ->
    ActInfo = act_db_mod:sel_ets_time(Key),
    Mod = reg_mod(ActInfo),
    case catch Mod:join(cash_out, [UserId, Cash, Point, ActInfo]) of
        ?ok ->
            ok;
        _X ->
            ok
    end.

%% 消费物品
goods_out(UserId, GoodsList) ->
    ok.

%% other
other() ->
    ok.

record_key(UserId, ActId) ->
    {UserId, ActId}.

%%---------------------------------------------------------------------------------
get_act_user(UserId, ActId) ->
    case act_db_mod:sel_ets_act_user({UserId, ActId}) of
        #ets_act_user{} = EtsActUser ->
            EtsActUser;
        _ ->
            #rec_act_time{template = Cid} = data_act:get_act(ActId),
            ActList = data_act:get_temp(Cid),
            get_act_user_2(UserId, ActList, ActId)
    end.
get_act_user_2(UserId, [ActId|Tail], TargetActId) ->
    case act_db_mod:sel_ets_act_user({UserId, ActId}) of
        #ets_act_user{} = EtsActUser ->
            Key = record_key(UserId, ActId),
            act_db_mod:del_ets_act_user(Key),
            Key2 = record_key(UserId, TargetActId),
            act_db_mod:ins_ets_act_user(EtsActUser#ets_act_user{key = Key2, act_id = TargetActId}),
            EtsActUser;
        _ ->
            get_act_user_2(UserId, Tail, TargetActId)
    end;
get_act_user_2(_UserId, [], _TargetActId) -> ?null.

%% 活动开启?
%% in:模版id
%% out:true/false
is_open(TmpId) ->
    case act_db_mod:sel_ets_act_temp(TmpId) of
        #ets_act_tmp{act_id = ActId} -> 
            case act_db_mod:sel_ets_time(ActId) of
                #ets_act_info{is_open = 1} -> ?true;
                _ -> ?false
            end;
        _ -> ?false
    end.

%%
%% Local Functions
%%
mix([#rec_act_time{id = Id} = Rec|Tail], OldList, OldRecList) ->
    List = 
        case lists:keyfind(Id, #ets_act_info.id, OldList) of
            ?false ->
                [Rec|OldRecList];
            _ ->
                OldRecList
        end,
    mix(Tail, OldList, List);
mix([], OldList, OldRecList) ->
    {OldList, lists:sort(OldRecList)}.

init_new([#rec_act_time{id = ActId, template = Tid} = Data|Tail], OldList, Now) -> % 新的活动
    Rec = task_record(Data),
    List = 
        case catch init(Rec, Now) of
            1 ->
                act_db_mod:ins_ets_time(Rec#ets_act_info{is_open = 1}), 
                act_db_mod:ins_ets_act_temp(#ets_act_tmp{act_id = ActId, temp_id = Tid}),
                [Rec|OldList];
			_ ->
				ets:delete_object(?CONST_ETS_ACT_TEMP, #ets_act_tmp{act_id = ActId, temp_id = Tid}),
                act_db_mod:ins_ets_time(Rec#ets_act_info{is_open = 0}),
                OldList
        end,
    init_new(Tail, List, Now);
init_new([], List, _Now) ->
    List.

init_old([#ets_act_info{} = Rec|Tail], OldList, Now) -> % 旧的活动
    List = 
        case catch init(Rec, Now) of
            1 ->
                act_db_mod:ins_ets_time(Rec#ets_act_info{is_open = 1}), 
                [Rec|OldList];
            _ ->
                act_db_mod:ins_ets_time(Rec#ets_act_info{is_open = 0}),
                OldList
        end,
    init_old(Tail, List, Now);
init_old([], List, _Now) -> List.

task_record(#rec_act_time{is_open = 0}) ->
    [];
task_record(#rec_act_time{plat = Plat} = Rec) when [] =/= Plat ->
    case catch chk_plat(Plat) of
        true ->
            task_record(Rec#rec_act_time{plat = []});
        _ ->
            []
    end;
task_record(#rec_act_time{time_type = TimeType} = RecActTime) when ?CONST_ACT_NORMAL =:= TimeType orelse ?CONST_ACT_PLAN =:= TimeType ->
    #rec_act_time{
                  id = Id, 
                  time_start = {YYYY, MM, DD, H24, Mi, SS}, 
                  time_end = {YYYYE, MME, DDE, H24E, MiE, SSE},
                  clear_over = Co,
                  config_id = ConfigId,
                  reset_daily = Reset,
                  template = Template
                 } = RecActTime,
    T  = misc:date_time_to_stamp({YYYY, MM, DD, H24, Mi, SS}),
    TE = misc:date_time_to_stamp({YYYYE, MME, DDE, H24E, MiE, SSE}),
    #ets_act_info{
                    id=Id, 
                    start_time = T,
                    stop_time = TE,
                    clear_over = Co,
                    config_id = ConfigId,
                    reset_daily = Reset,
                    template = Template 
                   };
task_record(#rec_act_time{time_type = TimeType} = RecActTime) when ?CONST_ACT_OPEN =:= TimeType orelse ?CONST_ACT_MIX =:= TimeType ->
    #rec_act_time{
                    id             = Id, 
                    time_last_from = DFrom,
                    time_last_to   = DTo,
                    clear_over     = Co,
                    config_id      = ConfigId,
                    reset_daily    = Reset,
                    template       = Template 
                 } = RecActTime,
    StartTime = get_time(TimeType),
    T = misc:date_time_to_stamp(StartTime)+DFrom*86400,
    TE = misc:date_time_to_stamp(StartTime)+DTo*86400,
    #ets_act_info{
                id=Id, 
                start_time  = T,
                stop_time   = TE,
                clear_over  = Co,
                config_id   = ConfigId,
                reset_daily = Reset,
                template    = Template 
               }.

%% 检查平台限制
chk_plat(Plat) ->
    PlatId = config:read_deep([server, base, platform_id]),
    chk_plat_2(Plat, PlatId).
chk_plat_2([{?CONST_ACT_DISALLOW, List}|Tail], PlatId) ->
    case lists:member(PlatId, List) of
        ?true ->
            ?false;
        ?false ->
            chk_plat_2(Tail, PlatId)
    end;
chk_plat_2([{?CONST_ACT_ALLOW, List}|Tail], PlatId) ->
    case lists:member(PlatId, List) of
        ?true ->
            ?true;
        ?false ->
            chk_plat_2(Tail, PlatId)
    end;
chk_plat_2([], _) ->
    ?true.

chk_time(StartTime, _StopTime, Now) when Now < StartTime                            -> 1;
chk_time(StartTime, StopTime, Now) when StartTime =< Now andalso Now =< StopTime    -> 2;
chk_time(_StartTime, StopTime, Now) when Now > StopTime                             -> 3.

%% 注册函数
reg_mod(#ets_act_info{template = Id}) -> reg_mod2(Id);
reg_mod(Act) when is_integer(Act) ->
	Re = act_db_mod:sel_ets_time(Act),
	reg_mod(Re).
reg_mod2(1) -> act_turn_mod;
reg_mod2(2) -> act_card_ex_mod;
reg_mod2(3) -> act_limitMall_mod;
reg_mod2(_) -> act_turn_mod.

get_time(?CONST_ACT_OPEN) -> config:read_deep([server, release, start_time]);
get_time(?CONST_ACT_MIX) -> config:read_deep([server, release, combined_time]).
    
