%% Author: cobain
%% Created: 2012-7-10
%% Description: TODO: Add description to crond_serv
-module(crond_center_serv).

%%
%% Include files
%%
-include("const.common.hrl").

%% gen_server callbacks
-export([start_link/2, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% --------------------------------------------------------------------
%% External exports
-export([clock_add_cast/9, clock_del_cast/1, clock_list_call/0,
		 interval_add_cast/5, interval_del_cast/1, interval_list_call/0,
		 reload_cast/0]).

-type timestamp() :: pos_integer().
%% 定时任务
-record(task_clock, {id,
					 min, hour, day,
					 month, week,
					 exem, exef, exea,
					 last_exec :: timestamp(),
			   		 is_config :: boolean()}).
%% 间隔任务 
-record(task_interval,{id,
					   interval,
					   exem, exef, exea,
			   		   last_exec :: timestamp(),
					   is_config :: boolean()}).

%% crond 状态
-record(state,{tref  			= ?null,	%% 定时
			   total 			= 0,	  	%% 开启到现在用的秒数
			   task_interval 	= [] :: [#task_interval{}],
			   task_clock    	= [] :: [#task_clock{}]}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(SrvName, Cores) ->
	misc_app:gen_server_start_link(SrvName, ?MODULE, [Cores]).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {?ok, State}          |
%%          {?ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([_Cores]) ->
	%% 
	process_flag(trap_exit, ?true),
	%% 随机数种子
	?RANDOM_SEED,
	TRef		= erlang:send_after(1000, self(), interval),
    Diff        = 
        try
            misc:seconds() rem 60 %, % 解决时间差
        catch
            X:Y ->
                ?MSG_SYS("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
        end,
    {?ok, task_init(#state{tref = TRef, total = Diff})}.


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
handle_call(clist, _From, State) ->
    Reply = State#state.task_clock,
    {reply, Reply, State};
handle_call(ilist, _From, State) ->
    Reply = State#state.task_interval,
    {reply, Reply, State};
handle_call(Request, _From, State) ->
	?MSG_ERROR("Request:~p Strace:~p",[Request, erlang:get_stacktrace()]),
    Reply = ?ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({cadd, TaskID,Min,Hour,Day,Month,Week,Module,Function,Args}, State) ->
	State2 	= task_record({TaskID,Min,Hour,Day,Month,Week,{Module,Function,Args}}, State, ?false),
	{noreply, State2};
handle_cast({iadd, TaskID,Interval,Module,Function,Args}, State) ->
	State2 	= task_record({TaskID,Interval,{Module,Function,Args}}, State, ?false),
	{noreply, State2};
handle_cast({cdel, TaskId},State) ->	
	Task	= lists:foldl(fun(Data, Task2) when is_record(Data,task_clock)   andalso Data#task_clock.id /= TaskId  -> [Data|Task2];
							 (_Data,Task2) -> Task2
						  end,[],State#state.task_clock),
	State2	= State#state{task_clock=Task},
	{noreply, State2};
handle_cast({idel, TaskId}, State) ->
	Task	= lists:foldl(fun(Data, Task2) when is_record(Data,task_interval) andalso Data#task_interval.id /= TaskId  -> [Data|Task2];
							 (_Data,Task2) -> Task2
						  end,[],State#state.task_interval),
	State2	= State#state{task_interval=Task},
	{noreply, State2};
handle_cast(reload, State) ->
	erlang:cancel_timer(State#state.tref),
	TRef		= erlang:send_after(1000, self(), interval),
	Interval 	= [T || T <- State#state.task_interval, T#task_interval.is_config =/= ?true],
	Clock 		= [T || T <- State#state.task_clock, 	T#task_clock.is_config    =/= ?true],
	State2		= #state{tref = TRef, task_interval = Interval, task_clock = Clock},
	State3		= task_init(State2),
    Diff        = misc:seconds() rem 60,
    State4      = State3#state{total = Diff},
	?MSG_PRINT(" Server Restart ok ",[]),
    {noreply, State4};
handle_cast(Msg, State) ->
	?MSG_ERROR("Msg:~p Strace:~p",[Msg, erlang:get_stacktrace()]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(interval, State) ->
	erlang:cancel_timer(State#state.tref),
	State2		= task_run(State),
    {noreply, State2#state{tref = erlang:send_after(1000, ?MODULE, interval)}};
handle_info(Info, State) ->
	?MSG_ERROR("Info:~p Strace:~p",[Info, erlang:get_stacktrace()]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server) 
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	case Reason of
		shutdown ->
			?MSG_ERROR("STOP Reason:~p", [Reason]);
		_ ->
			?MSG_ERROR("~nSTOP Reason:~w~nStrace:~p~nProcessInfo:~p~n",
					   [Reason, erlang:get_stacktrace(), erlang:process_info(self())])
	end,
	erlang:cancel_timer(State#state.tref).

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {?ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% 从yrl加载初始配置
task_init(State) ->	
	{?ok, FileList} = file:list_dir(?DIR_CRONTAB_ROOT),
	Fun				= fun("center."++_ = FileBaseName)->
							  FileName = ?DIR_CRONTAB_ROOT ++ FileBaseName,
							  case filename:extension(FileBaseName) of
								  ".yrl" -> FileName;
								  _ -> ?false
							  end;
                         (_) ->
                            ?false
					  end,
	FileList2		= lists:map(Fun, FileList),
	lists:foldl(fun task_file/2, State, FileList2).

task_file(FileName, State)->
	case filelib:is_file(FileName) of
		?true ->
			Data		= misc_app:load_file(FileName),
			DataList 	= if is_list(Data) -> Data;
							 ?true -> [Data]
						  end,
			lists:foldl(fun task_record/2, State, DataList);
		_ -> State
	end.

task_record(Data, State)->
	task_record(Data, State, ?true).
task_record({ID, Interval, {M, F, A}}, State, IsConfig) ->
	Task = #task_interval{id = ID, interval = Interval,
						  exem = M, exef = F, exea = A,
						  last_exec = 0, is_config = IsConfig},
	TaskInterval = [Task|State#state.task_interval],
	State#state{task_interval = TaskInterval};
task_record({ID, Min, Hour, Day, Month, Week, {M, F, A}}, State, IsConfig) ->
	Task = #task_clock{id=ID,
					   min = Min, hour = Hour, day = Day,
					   month = Month, week = Week,
					   exem = M, exef = F, exea = A,
					   last_exec = 0, is_config = IsConfig},
	TaskClock = [Task|State#state.task_clock],
	State#state{task_clock = TaskClock};
task_record(_Data,State,_IsYrl)->
	State.

%% 扫描任务列表，执行可执行的任务
task_run(State)->
	Total			= State#state.total + 1,
	Interval		= task_run_interval(State#state.task_interval, Total, []),
	Clock 			= if
						  (Total rem 60) =:= 0 ->
							  {Date, Time}	= ?CONST_FUNC_DATE_TIME,
							  Week			= misc:week(Date),
							  task_run_clock(State#state.task_clock, Total, Date, Time, Week, []);
						  ?true -> State#state.task_clock
					  end,
	State#state{total = Total, task_interval = Interval, task_clock = Clock}.

task_run_interval([Task|Interval], Total, Acc) ->
	TaskNew = task_run_interval(Task, Total),
	task_run_interval(Interval, Total, [TaskNew|Acc]);
task_run_interval([], _Total, Acc) -> Acc.

task_run_interval(Task, Total)
  when is_record(Task, task_interval)->
	if
		(Total rem Task#task_interval.interval) =:= 0 ->
			erlang:spawn(Task#task_interval.exem,
						 Task#task_interval.exef,
						 Task#task_interval.exea),
			Task#task_interval{last_exec = Total};
		?true -> 
            Task
	end;
task_run_interval(Task, _Total) -> 
    Task.

task_run_clock([Task|Clock], Total, Date, Time, Week, Acc) ->
	TaskNew = task_run_clock(Task, Total, Date, Time, Week),
	task_run_clock(Clock, Total, Date, Time, Week, [TaskNew|Acc]);
task_run_clock([], _Total, _Date, _Time, _Week, Acc) -> Acc.

task_run_clock(Task, Total, Date, Time, Week)
  when is_record(Task, task_clock)->
	case check_time(Task, Date, Time, Week) of
		?true ->
			erlang:spawn(Task#task_clock.exem,
						 Task#task_clock.exef,
						 Task#task_clock.exea),
			Task#task_clock{last_exec = Total};
		_ -> Task
	end;
task_run_clock(Task, _Total, _Date, _Time, _Week) -> Task.

%% 时间检查
check_time(Task, {_Y,M,D}, {H,I,_S}, Week) ->
	CheckList = [{Task#task_clock.min, I}, {Task#task_clock.hour, H}, {Task#task_clock.day, D}, 
				 {Task#task_clock.month,M},{Task#task_clock.week, Week}],
	check_time(CheckList).

check_time([])    -> ?true;
check_time([H|T]) ->
	case check_time2(H) of
		?true  -> check_time(T);
		?false -> ?false
	end.
check_time2({[],      _NowTime}) -> ?true;
check_time2({TaskTime, NowTime}) -> lists:member(NowTime, TaskTime).



%% 列出当前任务
clock_list_call() ->
	gen_server:call(?MODULE, clist, ?CONST_TIMEOUT_CALL).
%% 添加一个任务
clock_add_cast(TaskID,Min,Hour,Day,Month,Week,Module,Function,Args) ->
	gen_server:cast(?MODULE, {cadd, TaskID,Min,Hour,Day,Month,Week,Module,Function,Args}).
%% 删除一个任务(参数要与添加任务时提供的参数相同)
clock_del_cast(TaskId) ->
	gen_server:cast(?MODULE, {cdel, TaskId}).
%% 列出当前任务
interval_list_call() ->
	gen_server:call(?MODULE, ilist, ?CONST_TIMEOUT_CALL).
%% 添加一个任务
interval_add_cast(TaskID,Interval,Module,Function,Args) ->
	gen_server:cast(?MODULE, {iadd, TaskID,Interval,Module,Function,Args}).
%% 删除一个任务(参数要与添加任务时提供的参数相同)
interval_del_cast(TaskId) ->
	gen_server:cast(?MODULE, {idel, TaskId}).
%% 重载配置文件
reload_cast() ->
	gen_server:cast(?MODULE, reload). 