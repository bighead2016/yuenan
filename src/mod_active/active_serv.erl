%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2013-6-25
%%% -------------------------------------------------------------------
-module(active_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2, active_list_call/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
				acitve	= [],		%% 活动时间列表
				tref  	= ?null		%% 定时
			   }).
-type timestamp() :: pos_integer().
%% 定时任务
-record(task_clock, {id,
					 min, hour, day,
					 month, week,
					 exem, exef, exea,
					 last_exec :: timestamp(),
			   		 is_config :: boolean()}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, _Cores) -> 
	misc_app:gen_server_start_link(ServName, ?MODULE, []).

%% 列出当前活动
%% active_serv:active_list_call().
active_list_call() ->
	gen_server:call(?MODULE, active_list, ?CONST_TIMEOUT_CALL).
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
	try
		process_flag(trap_exit, ?true),
		%% 随机数种子
		?RANDOM_SEED,
		TRef		= erlang:send_after(?CONST_TIME_SECOND_MSEC, self(), interval),
		State		= init_active(#state{}),
		{?ok, State#state{tref = TRef}}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {Error, Reason}
	end.

init_active(State) ->
	[active_api:insert((data_active:get_active(Id))#rec_active.type) || Id  <- data_active:get_active_list()],
	ActiveList	= data_active:get_active_time_table(),
    ActiveList2 = data_active:get_active_rate(),
	init_active(State, ActiveList++ActiveList2).

init_active(State, [Data|Datas]) ->
	State2	= task_record(Data, State),
	init_active(State2, Datas);
init_active(State, []) -> State.
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
do_call(active_list, _From, State) ->
    Reply = State#state.acitve,
    {reply, Reply, State};
do_call(Request, _From, State) ->
	?MSG_ERROR("Request:~p   State:~p", [Request, State]),
	Reply = ?ok,
    {?reply, Reply, State}.

do_cast(Msg, State) ->
	?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
	{?noreply, State}.

do_info(interval, State) ->
	erlang:cancel_timer(State#state.tref),
	interval_active(State),
    {?noreply, State#state{tref = erlang:send_after(?CONST_TIME_SECOND_MSEC, self(), interval)}};
do_info(Info, State) ->
	?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
interval_active(State) ->
	{Date, Time}	= ?CONST_FUNC_DATE_TIME,
	Week			= misc:week(Date),
	interval_active(State#state.acitve, Date, Time, Week).


interval_active([TaskClock|ClockList], Date, Time, Week) ->
	interval_active_ext(TaskClock, Date, Time, Week),
	interval_active(ClockList, Date, Time, Week);
interval_active([], _Date, _Time, _Week) -> ?ok.

interval_active_ext(Task, Date, Time, Week)
  when is_record(Task, task_clock)->
	case check_time(Task, Date, Time, Week) of
		?true ->
			catch erlang:spawn(Task#task_clock.exem, Task#task_clock.exef, Task#task_clock.exea);
		_ -> Task
	end;
interval_active_ext(Task, _Date, _Time, _Week) -> Task.

%% 时间检查
check_time(Task, {_Y,M,D}, {H,I,_S}, Week) ->
	CheckList = [{Task#task_clock.week, Week},
				 {Task#task_clock.min, I},
				 {Task#task_clock.hour, H},
				 {Task#task_clock.day, D},
				 {Task#task_clock.month,M}],
	check_time(CheckList).

check_time([H|T]) ->
	case check_time2(H) of
		?true  -> check_time(T);
		?false -> ?false
	end;
check_time([]) -> ?true.

check_time2({[], _NowTime}) -> ?true;
check_time2({TaskTime, NowTime}) -> lists:member(NowTime, TaskTime).

task_record({ID, Min, Hour, Day, Month, Week, M, F, A}, State) ->
	Task = #task_clock{id=ID,
					   min = Min, hour = Hour, day = Day,
					   month = Month, week = Week,
					   exem = M, exef = F, exea = A,
					   last_exec = 0},
	TaskClock = [Task|State#state.acitve],
	State#state{acitve = TaskClock}.



