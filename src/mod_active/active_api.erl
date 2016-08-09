%%% 活动接口
%%% 活动的处理方式很简单，每个活动有个id，每个id会对应一个状态
%%% 然后在就是判定“开”与“关”的时候有个接口
%%% end.
-module(active_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%%
%% Exported Functions
%%
-export([
         active_begin/6, active_end/7, close/2,
         is_opened/1, login_packet/2, can_enter/1,
         open/1, open/2, close/1, insert/1, insert/3,
         read_by_type/1, read/1,
		 msg_begin/2,
		 msg_end/2,
		 msg_begin_pre/2,
		 calc_pre_time/3,
         active_begin_pre_fifteen/2,
		 active_begin_pre_ten/2,
		 active_begin_pre_five/2,
		 active_begin_pre_one/5,
         get_active_last/1
        ]).

%%
%% API Functions
%%

%% 登录
login_packet(Player, OldPacket) ->
	case boss_api:check_boss_end(Player) of
		?false ->
			ActiveIdList    = select_type(?CONST_ACTIVE_STATE_ON),
			PacketActive    = msg_begin(ActiveIdList, <<>>),
			MsPre           = ets:fun2ms(fun(#ets_active{type = A, state = ?CONST_ACTIVE_STATE_PRE_0, begin_time = C}) -> {A, C};
                                            (#ets_active{type = A, state = ?CONST_ACTIVE_STATE_PRE_1, begin_time = C}) -> {A, C};
											(#ets_active{type = A, state = ?CONST_ACTIVE_STATE_PRE_2, begin_time = C}) -> {A, C};
											(#ets_active{type = A, state = ?CONST_ACTIVE_STATE_PRE_3, begin_time = C}) -> {A, C}
										 end),
			ActivePreList   = ets_api:select(?CONST_ETS_ACTIVE, MsPre),
			PacketPre       = packet_pre_active(ActivePreList, <<>>),
			NewPacket       = <<OldPacket/binary, PacketActive/binary, PacketPre/binary>>,
			{Player, NewPacket};
		?true ->
			{Player, OldPacket}
	end.

packet_pre_active([{Type, BeginStamp}|PreList], Packet) ->
    Packet1 = msg_begin_pre(Type, BeginStamp),
    Packet2 = <<Packet/binary, Packet1/binary>>,
    packet_pre_active(PreList, Packet2);
packet_pre_active([_Other|PreList], Packet) ->
    packet_pre_active(PreList, Packet);
packet_pre_active([], Packet) ->
    Packet.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_active_last(Type) ->
    ActiveRec = data_active:get_active(Type),
    [Hb] = ActiveRec#rec_active.hour_b,
    [Mb] = ActiveRec#rec_active.min_b,
    [He] = ActiveRec#rec_active.hour_e,
    [Me] = ActiveRec#rec_active.min_e, 
    (He - Hb) * ?CONST_SYS_ONE_HOUR_SECONED + (Me - Mb) * 60.

calc_pre_time(MinBegin, HourBegin, MinP) ->
	[MinB|_] = MinBegin,
	Fun		 = fun(Hour) ->
					   case Hour - 1 >= 0 of
						   ?true -> Hour - 1;
						   ?false -> 23
					   end
			   end,
	case MinB - MinP >= 0 of
		?true -> {[MinB - MinP], HourBegin};
		?false -> {[MinB + 60 - MinP], lists:map(Fun, HourBegin)}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   提前广播    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 活动提前十五分钟开启图标
active_begin_pre_fifteen(Type, StandardState) ->
	case lookup(Type) of
		#ets_active{type = Type, state = StandardState} -> ?ok;
		_ -> 
            SpecialList = [?CONST_ACTIVE_GUILD_PVP],
             case lists:member(Type, SpecialList) of 
                ?true -> 
                    Packet1 = message_api:msg_notice(?TIP_ACTIVE_PRE_CAN_ENTER, [{?TIP_SYS_ACTIVE, misc:to_list(Type)},{?TIP_SYS_COMM, misc:to_list(?CONST_ACTIVE_PRE_TIME_15)}]),
                    guild_pvp_api:on([1]);
                ?false -> 
                    Packet1          = message_api:msg_notice(?TIP_ACTIVE_PRE_MINS, [{?TIP_SYS_ACTIVE, misc:to_list(Type)}, {?TIP_SYS_COMM, misc:to_list(?CONST_ACTIVE_PRE_TIME_15)}])
             end,
			BeginStamp		= calc_time_stamp(15),
			update_state_begin(Type, StandardState, BeginStamp),
			
			Packet			= msg_begin_pre(Type, BeginStamp),
			misc_app:broadcast_world_2(<<Packet/binary, Packet1/binary>>)
	end.


%% 活动提前十分钟开启图标
active_begin_pre_ten(Type, StandardState) ->
    case Type == ?CONST_ACTIVE_CAMP_PVP of
        true ->
            camp_pvp_counter_serv:reset_cast();
        _ ->
            ok
    end,
    case lookup(Type) of
		#ets_active{type = Type, state = StandardState} -> ?ok;
		_ ->
            Packet1 = message_api:msg_notice(?TIP_ACTIVE_PRE_MINS, [{?TIP_SYS_ACTIVE, misc:to_list(Type)},{?TIP_SYS_COMM, misc:to_list(?CONST_ACTIVE_PRE_TIME_10)}]),
			BeginStamp 		= calc_time_stamp(10),
            update_state_begin(Type, StandardState, BeginStamp),
			Packet     		= msg_begin_pre(Type, BeginStamp),
			misc_app:broadcast_world_2(<<Packet/binary, Packet1/binary>>)
	end.

active_begin_pre_five(Type, StandardState) ->
	case lookup(Type) of
		#ets_active{type = Type, state = StandardState} -> ?ok;
		_ ->
			BeginStamp 		= calc_time_stamp(5),
            update_state_begin(Type, StandardState, BeginStamp),
			ActivePreList	= select_type_time(StandardState),
			Packet			= packet_pre_active(ActivePreList, <<>>),
			Packet1 		= message_api:msg_notice(?TIP_ACTIVE_PRE_MINS_2, 
                                                     [{?TIP_SYS_ACTIVE, misc:to_list(Type)},{?TIP_SYS_COMM, misc:to_list(?CONST_ACTIVE_PRE_TIME_5)}]),
			misc_app:broadcast_world_2(<<Packet/binary, Packet1/binary>>)
	end.

active_begin_pre_one(Type, StandardState, Module, Func, Args) when Type =:= ?CONST_ACTIVE_BOSS1 
    orelse Type =:= ?CONST_ACTIVE_BOSS2 
    orelse Type =:= ?CONST_ACTIVE_BOSS3
    orelse Type =:= ?CONST_ACTIVE_BOSS4 ->
	case lookup(Type) of
		#ets_active{type = Type, state = StandardState} -> ?ok;
		_ ->
			BeginStamp		= calc_time_stamp(1),
            update_state_begin(Type, StandardState, BeginStamp),
			active_begin_pre_one_ext(Type, ?false, Module, Func, Args)
	end;
active_begin_pre_one(Type, StandardStateTemp, Module, Func, Args) ->
	SpecialList		= [?CONST_ACTIVE_CAMP_PVP,
					   ?CONST_ACTIVE_WORLD],
	Flag			= lists:member(Type, SpecialList),
    StandardState	= case Flag of ?true -> ?CONST_ACTIVE_STATE_ON; ?false -> StandardStateTemp end,
	case lookup(Type) of
		#ets_active{type = Type, state = StandardState} -> ?ok;
		_ ->
			BeginStamp		= calc_time_stamp(1),
            update_state_begin(Type, StandardState, BeginStamp),
			active_begin_pre_one_ext(Type, Flag, Module, Func, Args)
	end.

active_begin_pre_one_ext(Type, ?false, Module, Func, Args) when Type =:= ?CONST_ACTIVE_BOSS1 
    orelse Type =:= ?CONST_ACTIVE_BOSS2 
    orelse Type =:= ?CONST_ACTIVE_BOSS3
    orelse Type =:= ?CONST_ACTIVE_BOSS4 ->
    	ActivePreList	= select_type_time(?CONST_ACTIVE_STATE_PRE_3),
    	Packet  		= packet_pre_active(ActivePreList, <<>>),
    	Packet1 		= message_api:msg_notice(?TIP_ACTIVE_PRE_CAN_ENTER, 
                                                 [{14, misc:to_list(Type)},{100, misc:to_list(?CONST_ACTIVE_PRE_TIME_1)}]),
    	misc_app:broadcast_world_2(<<Packet/binary, Packet1/binary>>),
%%		?MSG_DEBUG("444444444444444444444444444444~p", [{Module, Func}]),
%% 		Module:Func();
		try Module:Func(Args)
		catch _:_ -> {?error, ?TIP_COMMON_BAD_ARG}
		end;
active_begin_pre_one_ext(Type, ?true, Module, Func, Args) -> %% 乱天下
	ActivePreList	= select_type_time(?CONST_ACTIVE_STATE_PRE_3),
	Packet  		= packet_pre_active(ActivePreList, <<>>),
    update_state_begin(Type, ?CONST_ACTIVE_STATE_ON, 0),
	Packet1 		= message_api:msg_notice(?TIP_ACTIVE_PRE_CAN_ENTER, 
                                             [{?TIP_SYS_ACTIVE, misc:to_list(Type)},{?TIP_SYS_COMM, misc:to_list(?CONST_ACTIVE_PRE_TIME_1)}]),
	misc_app:broadcast_world_2(<<Packet/binary, Packet1/binary>>),
	try Module:Func(Args)
	catch _:_ -> {?error, ?TIP_COMMON_BAD_ARG}
	end;
active_begin_pre_one_ext(Type, ?false, _Module, _Func, _Args) ->
	MsPre		  	= ets:fun2ms(fun(#ets_active{type = A, state = B, begin_time = C}) when B =:= ?CONST_ACTIVE_STATE_PRE_3 -> {A, C} end),
	ActivePreList 	= ets_api:select(?CONST_ETS_ACTIVE, MsPre),
	Packet  		= packet_pre_active(ActivePreList, <<>>),
	Packet1 		= message_api:msg_notice(?TIP_ACTIVE_PRE_MINS_2, [{?TIP_SYS_ACTIVE, misc:to_list(Type)},{?TIP_SYS_COMM, misc:to_list(?CONST_ACTIVE_PRE_TIME_1)}]),
	misc_app:broadcast_world_2(<<Packet/binary, Packet1/binary>>).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 活动开始
%% active_begin(Type, StandardState, Module, Func, Args, MsgId) when
%%     Type =:= ?CONST_ACTIVE_BOSS1 
%%     orelse Type =:= ?CONST_ACTIVE_BOSS2 
%%     orelse Type =:= ?CONST_ACTIVE_BOSS3
%%     orelse Type =:= ?CONST_ACTIVE_BOSS4 ->
%%     case lookup(Type) of
%%         #ets_active{type = Type, state = StandardState} -> 
%%             ?ok;
%%         _ ->
%%             open(Type),
%%             Packet = msg_begin(Type, MsgId),
%%             misc_app:broadcast_world_2(Packet),
%%             ?ok
%%     end;
active_begin(Type, StandardState, Module, Func, Args, MsgId) ->
	case lookup(Type) of
		#ets_active{type = Type, state = StandardState} -> 
            ?ok;
		_ ->
            case Type == ?CONST_ACTIVE_GUILD_PVP andalso not guild_pvp_mod:check_open() of
                true ->
                    ok;
                _ ->
                    open(Type),
                    Packet = msg_begin(Type, MsgId),
                    misc_app:broadcast_world_2(Packet),
                    try
                        Module:Func(Args),
                        ?ok
                    catch
                        _:_ ->
                            ?ok
                    end
            end
    end.

%% 活动结束
active_end(Type, StandardState, Module, Func, Args, MsgId, Rela) ->
%%	?MSG_DEBUG("~n 4444444444444444444~p", [{Module, Func, Args}]),
	case lookup(Type) of
		#ets_active{type = Type, state = StandardState} -> 
%%			?MSG_DEBUG("~n 4444444444444444444~p", [{Module, Func, Args}]),
            ?ok;
        _ ->
            close([Type|Rela]), % 要关调所有相关的
            Packet = msg_end(Type, MsgId), % 但是发就只发当前的
            misc_app:broadcast_world_2(Packet),
            try
%%				?MSG_DEBUG("~n 4444444444444444444~p", [{Module, Func, Args}]),
                Module:Func(Args),
                ?ok
            catch
                _:_ ->
                    ?ok
            end
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 宴会准备广播
%% party_ready_broadcast() ->
%% 	Packet = msg_begin(?CONST_ACTIVE_TYPE_PARTY, ?TIP_GUILD_PARTY_READY_BRO3),
%%     misc_app:broadcast_world(Packet).

%% 开启活动
open(Type) ->
    update_state_begin(Type, ?CONST_ACTIVE_STATE_ON, 0).

open(Type, Id) ->
	StandardState	= ?CONST_ACTIVE_STATE_ON,
    RecActive = read(Id),
    Module = RecActive#rec_active.module_b,
    Func   = RecActive#rec_active.func_b,
    Args   = RecActive#rec_active.args_b,
    MsgId  = RecActive#rec_active.msg_b,
    active_begin(Type, StandardState, Module, Func, Args, MsgId).

%% 关闭活动
close([Type|Tail]) ->
    close(Type),
    close(Tail);
close([]) ->
    ?ok;
close(Type) ->
    update_state_begin(Type, ?CONST_ACTIVE_STATE_OFF, 0). 

close(Type, Id) ->
	StandardState	= ?CONST_ACTIVE_STATE_OFF,
    RecActive = read(Id),
    Module = RecActive#rec_active.module_e,
    Func   = RecActive#rec_active.func_e,
    Args   = RecActive#rec_active.args_e,
    MsgId  = RecActive#rec_active.msg_e,
    Rela   = RecActive#rec_active.rela,
    active_end(Type, StandardState, Module, Func, Args, MsgId, Rela).
    
%% 读取活动数据
read(Id) ->
    data_active:get_active(Id).

%% 从类型读取活动数据
read_by_type(Type) ->
    data_active:get_active_by_type(Type).

%% 开启了?
%% active_api:is_opened(1).
is_opened(Type) ->
    case ets_api:lookup(?CONST_ETS_ACTIVE, Type) of
        #ets_active{state = ?CONST_ACTIVE_STATE_ON} ->
            ?CONST_SYS_TRUE;
        _ ->
            ?CONST_SYS_FALSE
    end.

%% 可进?
%% active_api:can_enter(1).
can_enter(Type) ->
    SpecialList = [?CONST_ACTIVE_BOSS1, ?CONST_ACTIVE_BOSS2, 
                   ?CONST_ACTIVE_BOSS3, ?CONST_ACTIVE_BOSS4,
                   ?CONST_ACTIVE_CAMP_PVP,
                   ?CONST_ACTIVE_WORLD],
    CanEnter = lists:member(Type, SpecialList),
    case ets_api:lookup(?CONST_ETS_ACTIVE, Type) of
        #ets_active{state = ?CONST_ACTIVE_STATE_ON} ->
            ?CONST_SYS_TRUE;
        #ets_active{state = ?CONST_ACTIVE_STATE_PRE_3} when ?true =:= CanEnter ->
            ?CONST_SYS_TRUE;
        _ ->
            ?CONST_SYS_FALSE
    end.

%% 插入新的活动
insert(Type) ->
    ets_api:insert(?CONST_ETS_ACTIVE, #ets_active{type = Type, state = ?CONST_ACTIVE_STATE_OFF, begin_time = 0, rate = 1}).
insert(Type, State, BeginTime) ->
    ets_api:insert(?CONST_ETS_ACTIVE, #ets_active{type = Type, state = State, begin_time = BeginTime, rate = 1}).

%% 更新活动状态和时间
update_state_begin(Type, State, BeginTime) ->
    ets_api:update_element(?CONST_ETS_ACTIVE, Type, [{#ets_active.begin_time, BeginTime}, {#ets_active.state, State}]).

lookup(Type) ->
	ets_api:lookup(?CONST_ETS_ACTIVE, Type).

%% 读取对应活动
select_type_time(State) ->
    MsPre           = ets:fun2ms(fun(#ets_active{type = A, state = B, begin_time = C}) when B =:= State -> {A, C} end),
    ets_api:select(?CONST_ETS_ACTIVE, MsPre).
select_type(State) ->
    MsPre           = ets:fun2ms(fun(#ets_active{type = A, state = B}) when B =:= State -> A end),
    ets_api:select(?CONST_ETS_ACTIVE, MsPre).

%%
%% Local Functions
%%
%% 计算时间
calc_time_stamp(PreMin) when is_integer(PreMin) ->
    Now = misc:seconds(),
    Now + PreMin * 60;
calc_time_stamp(_) ->
    misc:seconds().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  协议  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 活动开启
%%[Type]
msg_begin([Type|Tail], OldPacket) ->
    RecActive = read_by_type(Type),
    MsgId     = RecActive#rec_active.msg_b,
    Packet    = msg_begin(Type, MsgId),
    NewPacket = <<OldPacket/binary, Packet/binary>>,
    msg_begin(Tail, NewPacket);
msg_begin([], Packet) -> Packet;
msg_begin(Type, MsgId) ->
    misc_packet:pack(?MSG_ID_ACTIVE_BEGIN, ?MSG_FORMAT_ACTIVE_BEGIN, [Type, MsgId]).

%% 活动关闭
%%[Type]
msg_end(Type, MsgId) ->
    misc_packet:pack(?MSG_ID_ACTIVE_END, ?MSG_FORMAT_ACTIVE_END, [Type, MsgId]).

%% 活动开启前10分钟图标显示
msg_begin_pre(Type, BeginStamp) ->
	misc_packet:pack(?MSG_ID_ACTIVE_PREPARE, ?MSG_FORMAT_ACTIVE_PREPARE, [Type, BeginStamp]).
