
%%% 作坊强化队列接口
-module(furnace_queue_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").

%%
%% Exported Functions
%%
-export([refresh_queue/1, refresh_queue/2, refresh/1, get_free_queue/1, push_queue/3,
         list_queue/2,
		 add_queue/2,
         clear_cd/3, sort_queue/2]).

%%
%% API Functions
%%

%% 初始化强化队列
refresh_queue(N) ->
    refresh_queue(N, []).
refresh_queue(0, _Queues) -> {?CONST_SYS_TRUE, []};
refresh_queue(N, Queues) ->
	refresh_queue(N, 1, Queues).
refresh_queue(N, AccN, Queues) when N >= AccN ->
	case lists:keymember(AccN, #furnace_cd.id, Queues) of
		?true -> refresh_queue(N, AccN + 1, Queues);
		?false -> 
			refresh_queue(N, AccN + 1, [#furnace_cd{id = AccN, deadline = 0}|Queues])
	end;
refresh_queue(_N, _AccN, Queues) -> {?CONST_SYS_FALSE, Queues}.

%% 刷新cd
refresh(FurnaceData) ->
    case FurnaceData#furnace_data.queues_flag of
        ?CONST_SYS_FALSE ->
            CdList 		= FurnaceData#furnace_data.queues,
            Now 		= misc:seconds(),
            NewCdList 	= refresh(CdList, Now, []),
            FurnaceData#furnace_data{queues = NewCdList};
        ?CONST_SYS_TRUE ->
            FurnaceData
    end.

refresh([FurnaceCd|Tail], Now, CdList) ->
    DeadLine 		= FurnaceCd#furnace_cd.deadline,
    Delta 			= Now - DeadLine,
    NewFurnaceCd 	= 
        case Delta of
            Now -> % 已清
                FurnaceCd;
            T when T =< 0 ->
                FurnaceCd;
            T when T > 0 ->
                FurnaceCd#furnace_cd{deadline = 0}
        end,
    NewCdList 		= [NewFurnaceCd|CdList],
    refresh(Tail, Now, NewCdList);
refresh([], _, CdList) ->
    CdList.
        
%% 读取可用队列
get_free_queue(FurnaceData) ->
    TempQueues 	= FurnaceData#furnace_data.queues,
	Queues     	= lists:sort( (fun sort_queue/2), TempQueues),
    Now 		= misc:seconds(),
    case get_free_queue(Queues, Now) of
        Queue when is_record(Queue, furnace_cd) ->
            Queue;
        _ ->
            ?null
    end.

get_free_queue([Queue|Tail], Now) ->
    DeadLine 	= Queue#furnace_cd.deadline,
    case is_free(DeadLine, Now) of
		?CONST_SYS_TRUE -> Queue;
        _ -> get_free_queue(Tail, Now)
    end;
get_free_queue([], _) ->
    ?null.

%% 队列号排序
sort_queue(QueueL, QueueR)
  when QueueL#furnace_cd.id > QueueR#furnace_cd.id ->
		?false;
sort_queue(QueueL, QueueR)
  when QueueL#furnace_cd.id =< QueueR#furnace_cd.id ->
		?true.

%% 该队列空闲
is_free(0, _Now) -> ?CONST_SYS_TRUE;% 过了
is_free(DeadLine, Now) when DeadLine =< Now -> % 过了
    ?CONST_SYS_TRUE;
is_free(DeadLine, Now) ->
    Delta = DeadLine - Now,
    if
        Delta =< ?CONST_FURNACE_TIME_MAX_QUEUE ->
            ?CONST_SYS_TRUE;
        ?true ->
            ?CONST_SYS_FALSE
    end.

%% 进队
push_queue(IsFurCd, Queue, FurnaceData) ->
    Queues 		= FurnaceData#furnace_data.queues,
    QueueId 	= Queue#furnace_cd.id,
    DeadLine 	= Queue#furnace_cd.deadline,
	Now 		= misc:seconds(),
    NewDeadLine = 
        if
			IsFurCd =:= ?CONST_SYS_TRUE ->
				0;
            DeadLine <  Now ->
                Now + ?CONST_FURNACE_TIME_CD;
            ?true ->
                DeadLine + ?CONST_FURNACE_TIME_CD
        end,
    Queue2 		= Queue#furnace_cd{deadline = NewDeadLine},
    Queues2 	= lists:keyreplace(QueueId, #furnace_cd.id, Queues, Queue2),
    NewFurnaceData = FurnaceData#furnace_data{queues = Queues2},
    {NewFurnaceData, NewDeadLine}.
  

%% 列出队列
list_queue(Type, Furnace) ->
	case Furnace#furnace_data.queues_flag of
		?CONST_SYS_FALSE ->
			F = fun(#furnace_cd{id = QueueId, deadline = DeadLine}, AccPacket) ->
						Packet = furnace_api:msg_stren_queue_return(QueueId, DeadLine, Type, ?CONST_SYS_TRUE),
						<<AccPacket/binary, Packet/binary>>
				end,
			lists:foldl(F, <<>>, Furnace#furnace_data.queues);
		?CONST_SYS_TRUE -> furnace_api:msg_sc_cancel_stren_queue()
	end.

%% 增加一个强化队列
add_queue(Player, FurnaceData) ->
	Queues 		= FurnaceData#furnace_data.queues,
	Len 		= erlang:length(Queues),
	case add_queue_check(Player, Len) of
		?ok ->
			
			Queue = #furnace_cd{id = Len + 1, deadline = 0},
			NewQueues = [Queue|Queues],
			FurnaceData#furnace_data{queues = NewQueues};
		{?error, Result} ->
			Packet = message_api:msg_notice(Result),
			misc_packet:send(Player#player.net_pid, Packet),
			?error
	end.

%% 增加强化队列检查
add_queue_check(Player, QueueNum) ->
	Vip 		= player_api:get_vip_lv(Player),
	MaxNum 		= player_vip_api:get_furnace_queues(Vip),
	case (QueueNum >= ?CONST_FURNACE_STREN_QUEUE_MAX) of
		?true ->
			{?error, ?TIP_FURNACE_QUEUE_LIMIT};	%队列已到上限
		?false ->
			case (QueueNum < MaxNum) of
				?true ->
					?ok;
				?false ->
					{?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}
			end
	end.

%% 清除队列cd
%% {?ok, NewFurnaceData}/{?error, FurnaceData}
clear_cd(UserId, FurnaceData, QueueId) ->
    Queues 		= FurnaceData#furnace_data.queues,
    case lists:keytake(QueueId, #furnace_cd.id, Queues) of
        {value, Queue, Queues2} ->
            DeadLine = Queue#furnace_cd.deadline,
            Now = misc:seconds(),
            if
                0 =:= DeadLine ->
                    PacketErr = message_api:msg_notice(?TIP_FURNACE_NO_CD),
                    misc_packet:send(UserId, PacketErr),
                    {?error, FurnaceData};
                Now >= DeadLine ->
                    PacketErr = message_api:msg_notice(?TIP_FURNACE_NO_CD),
                    misc_packet:send(UserId, PacketErr),
                    {?error, FurnaceData};
                Now < DeadLine ->
                    Delta = DeadLine - Now,
                    CostTotal = misc:ceil(Delta / ?CONST_FURNACE_CD_PER_CASH),
                    case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, CostTotal, ?CONST_COST_FURNACE_CLEAR_CD) of
                        ?ok ->
                            NewQueue = Queue#furnace_cd{deadline = 0},
                            NewQueues = [NewQueue|Queues2],
                            NewFurnaceData = FurnaceData#furnace_data{queues = NewQueues},
                            {?ok, NewFurnaceData};
                        _ ->
                            {?error, FurnaceData}
                    end
            end;
        ?false ->
            PacketErr = message_api:msg_notice(?TIP_FURNACE_QUEUE_NOT_EXIST),
            misc_packet:send(UserId, PacketErr),
            {?error, FurnaceData}
    end.

%% %% 清除所有cd
%% clear_all_cd(FurnaceData) ->
%%     Queues = FurnaceData#furnace_data.queues,
%%     F = fun(Queue, OldQueues) ->
%%                 [Queue#furnace_cd{deadline = 0}|OldQueues]
%%         end,
%%     lists:foldl(F, [], Queues).

%%
%% Local Functions
%%

