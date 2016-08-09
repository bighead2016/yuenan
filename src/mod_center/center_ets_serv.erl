%%% 
-module(center_ets_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.data.hrl").
-include("record.man.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores) -> 
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    %% 
    process_flag(trap_exit, ?true),
    L = [
             {?CONST_ETS_SHARED_ACCOUNT,        1},
             {?CONST_ETS_CROSS_NODE_INFO,       #ets_cross_node_info.serv},
%%              {?CONST_ETS_CENTER_NODE_INFO,      #ets_center_node_info.sid},
             {?CONST_ETS_TOWER_REPORT,          #ets_tower_report.id},
             {?CONST_ETS_TOWER_REPORT_IDX,      #ets_tower_report_idx.camp_id},
             {?CONST_ETS_COPY_SINGLE_REPORT,    #ets_copy_single_report.id},
             {?CONST_ETS_COPY_SINGLE_REPORT_IDX,#ets_copy_single_report_idx.copy_id},
             {?CONST_ETS_CROSS_ARENA_MEMBER,    #ets_cross_arena_member.player_id},
             {?CONST_ETS_CROSS_ARENA_PHASE,     #cross_arena_phase.phase},
			 {?CONST_ETS_CROSS_ARENA_REPORT,	#cross_arena_report.id},
			 {?CONST_ETS_CROSS_ARENA_GROUP_REPORT, #cross_arena_group_report.phase_group},
			 {?CONST_ETS_CROSS_ARENA_ROBOT,		#cross_arena_robot_member.player_id},
			 {?CONST_ETS_PLAYER_CODES,		    #ets_player_code.code},
             {?CONST_ETS_GUN_CASH_GLOBAL,       #ets_gun_cash_global.account},
             {?CONST_ETS_GAMBLE_ROOM_MINI, 		#ets_gamble_room_mini.key},
			 {?CONST_ETS_SERV_INFO,				#ets_serv_info.sid},			% 跨服服务器信息表
			 {?CONST_ETS_MATCH_RANK,			#ets_match_rank.rank},			% 闯关比赛排行榜
			 {?CONST_ETS_MATCH_COPY_IDX,		#ets_match_copy_idx.copy_id},	% 闯关比赛关卡排行榜
             {?CONST_ETS_MAN_HOUTAI,            #ets_man_houtai.key}            % 中心服结点信息
            ],
	try
		init_ets(L),
		center_api:init(),
		{?ok, #state{}}
	catch
		T:R ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [T, R, erlang:get_stacktrace()]),
			{?error, R}
	end.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(Request, From, State) ->
    try do_call(Request, From, State) of
        {?reply, Reply, State2} -> {?reply, Reply, State2}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State}
    end.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    try do_cast(Msg, State) of
        {?noreply, State2} -> {?noreply, State2}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State}
    end.
    

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
    try do_info(Info, State) of
        {?noreply, State2} -> {?noreply, State2}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State}
    end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    case Reason of
        shutdown -> ?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
        _ -> ?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]), ?ok
    end.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_call(Request, _From, State) ->
    Reply = ?ok,
    ?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.

do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
    {?noreply, State}.

do_info(Info, State) ->
    ?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

init_ets([{Ets, Pos}|Tail]) ->
    ets_api:new(Ets, Pos),
    init_ets(Tail);
init_ets([]) ->
    ok.