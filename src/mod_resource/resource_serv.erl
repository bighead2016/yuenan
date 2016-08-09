%% 奖池
-module(resource_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2, read_bgold/0, read_list/0, update_pool_cast/1, win_cast/3, win_bcash_cast/3,read_bcash/0,read_bcash_list/0,
		 read_exp/0,read_list_exp/0,win_exp_cast/3,get_big_award_cast/1,put_big_award_cast/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
%% buff_serv:start_link(buff_serv, 1).
start_link(ServName, _Cores) -> 
	misc_app:gen_server_start_link(ServName, ?MODULE, []).

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
	%% 随机数种子
	?RANDOM_SEED,
    resource_mod:init_pool(),
    {?ok, #state{}}.

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

do_cast({update_pool, BGoldAdd}, State) ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, bgold) of
        {_, BGoldT} ->
            ets_api:insert(?CONST_ETS_RES_POOL, {bgold, min(BGoldT+BGoldAdd, ?CONST_RESOURCE_POOL_MAX)});
        _ ->
            ets_api:insert(?CONST_ETS_RES_POOL, {bgold, min(?CONST_RESOURCE_POOL_MIN+BGoldAdd, ?CONST_RESOURCE_POOL_MAX)})
    end,
	{?noreply, State};
do_cast({win, UserId, UserName, BGold}, State) ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, list) of
        {_, List} ->
            Len = erlang:length(List),
            List2 = 
                if
                    Len > ?CONST_RESOURCE_LUCK_DOG_LIST ->
                        [_|Tail] = List ++ [{UserId, UserName, BGold,1}],
                        Tail;
                    ?true ->
                        List ++ [{UserId, UserName, BGold,1}]
                end,
            ets_api:insert(?CONST_ETS_RES_POOL, {list, List2});
        _ ->
            ets_api:insert(?CONST_ETS_RES_POOL, {list, []})
    end,
    case ets_api:lookup(?CONST_ETS_RES_POOL, bgold) of
        {_, BGoldT} ->
%%             case new_serv_api:is_new_serv(3) of
%%                 ?true ->
                    ets_api:insert(?CONST_ETS_RES_POOL, {bgold, max(BGoldT-BGold, ?CONST_RESOURCE_POOL_MIN)});
%%                 ?false ->
%%                     ets_api:insert(?CONST_ETS_RES_POOL, {bgold, max(BGoldT-BGold, 0)})
%%             end;
        _ ->
%%             case new_serv_api:is_new_serv(3) of
%%                 ?true ->
                    ets_api:insert(?CONST_ETS_RES_POOL, {bgold, ?CONST_RESOURCE_POOL_MIN})
%%                 ?false ->
%%                     ets_api:insert(?CONST_ETS_RES_POOL, {bgold, max(?CONST_RESOURCE_POOL_MIN-BGold, 0)})
%%             end
    end,
	{?noreply, State};

do_cast({win_bcash, UserId, UserName, BCash}, State) ->
	case ets_api:lookup(?CONST_ETS_RES_POOL, bcash_list) of
		{_, List} ->
			Len = erlang:length(List),
			List2 = 
				if
					Len > ?CONST_RESOURCE_LUCK_DOG_LIST ->
						[_|Tail] = List ++ [{UserId, UserName, BCash,2}],
						Tail;
					?true ->
						List ++ [{UserId, UserName, BCash,2}]
				end,
			ets_api:insert(?CONST_ETS_RES_POOL, {bcash_list, List2});
		_ ->
			ets_api:insert(?CONST_ETS_RES_POOL, {bcash_list, []})
	end,
	case ets_api:lookup(?CONST_ETS_RES_POOL, bcash) of
		{_, BCashT} ->
			ets_api:insert(?CONST_ETS_RES_POOL, {bcash, max(BCashT-BCash, ?CONST_RESOURCE_POOL_BCASH_MIN)});
		_ ->
			ets_api:insert(?CONST_ETS_RES_POOL, {bcash, ?CONST_RESOURCE_POOL_BCASH_MIN})
	end,
    ListPacket = resource_api:msg_sc_winning([{UserId, UserName, BCash,2}], <<>>),
	misc_app:broadcast_world_2(ListPacket),
	{?noreply, State};

do_cast({win_exp, UserId, UserName, Exp}, State) ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, list_exp) of
        {_, List} ->
            Len = erlang:length(List),
            List2 = 
                if
                    Len > ?CONST_RESOURCE_LUCK_DOG_LIST ->
                        [_|Tail] = List ++ [{UserId, UserName,Exp ,3 }],
                        Tail;
                    ?true ->
                        List ++ [{UserId, UserName,Exp ,3}]
                end,
            ets_api:insert(?CONST_ETS_RES_POOL, {list_exp, List2});
        _ ->
            ets_api:insert(?CONST_ETS_RES_POOL, {list_exp, []})
    end,
	case ets_api:lookup(?CONST_ETS_RES_POOL, exp) of
		{_, ExpT} ->
			ets_api:insert(?CONST_ETS_RES_POOL, {exp, max(ExpT-Exp, ?CONST_RESOURCE_POOL_EXP_MIN)});
		_ ->
			ets_api:insert(?CONST_ETS_RES_POOL, {exp, ?CONST_RESOURCE_POOL_EXP_MIN})
	end,
	{?noreply, State};

do_cast({get_big_award_cast, UserId}, State) ->
	case get(big_award) of
		undefined ->
			nil;
		{UserId,UserName,Num,Type} ->
			BigAwardPacket = resource_api:msg_sc_big_award(UserId,UserName,Num,Type),
			misc_packet:send(UserId, BigAwardPacket);
		_ ->
			nil
	end,
	{?noreply, State};

do_cast({put_big_award_cast, BigAward}, State) ->
	put(big_award, BigAward),
	{?noreply, State};

do_cast(add_bcash,State)->
	case resource_api:check_start_server_same_day() of
		true ->
			ets_api:insert(?CONST_ETS_RES_POOL, {bcash, ?CONST_RESOURCE_POOL_BCASH_MIN});
		false ->
			BCashAdd = random:uniform(41)+9,
			case ets_api:lookup(?CONST_ETS_RES_POOL, bcash) of
				{_, BCash} ->
					ets_api:insert(?CONST_ETS_RES_POOL, {bcash, min(BCash+BCashAdd, ?CONST_RESOURCE_POOL_BCASH_MAX)});
				_ ->
					ets_api:insert(?CONST_ETS_RES_POOL, {bcash, min(?CONST_RESOURCE_POOL_BCASH_MIN+BCashAdd, ?CONST_RESOURCE_POOL_BCASH_MAX)})
			end
	end,
	{?noreply, State};
do_cast(update_exp_pool, State) ->
	case resource_api:check_start_server_same_day() of
		true ->
			case ets_api:lookup(?CONST_ETS_RES_POOL, exp) of
				{_, ExpT} ->
					if ExpT==0 ->
						   nil;
					   true ->
						   ets_api:insert(?CONST_ETS_RES_POOL, {exp,?CONST_RESOURCE_POOL_EXP_MIN})
					end;
				_->
					ets_api:insert(?CONST_ETS_RES_POOL, {exp,?CONST_RESOURCE_POOL_EXP_MIN})
			end;
		false ->
			ExpAdd = misc_random:random(?CONST_RESOURCE_POOL_EXP_INTERVAL_MIN,?CONST_RESOURCE_POOL_EXP_INTERVAL_MAX),
			case ets_api:lookup(?CONST_ETS_RES_POOL, exp) of
				{_, ExpT} ->
					ets_api:insert(?CONST_ETS_RES_POOL, {exp, min(ExpT+ExpAdd, ?CONST_RESOURCE_POOL_EXP_MAX)});
				_ ->
					ets_api:insert(?CONST_ETS_RES_POOL, {exp, min(?CONST_RESOURCE_POOL_EXP_MIN+ExpAdd, ?CONST_RESOURCE_POOL_EXP_MAX)})
			end
	end,
	{?noreply, State};
do_cast(Msg, State) ->
	?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
	{?noreply, State}.

do_info(Info, State) ->
	?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

read_bgold() ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, bgold) of
        {_, BGold} ->
            BGold;
        _ ->
            0
    end.

read_list() ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, list) of
        {_, List} ->
            List;
        _ ->
            0
    end.

read_bcash()->
	    case ets_api:lookup(?CONST_ETS_RES_POOL, bcash) of
        {_, BCash} ->
            BCash;
        _ ->
            0
    end.
read_bcash_list() ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, bcash_list) of
        {_, List} ->
            List;
        _ ->
            0
    end.

read_exp() ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, exp) of
        {_, Exp} ->
            Exp;
        _ ->
            0
    end.

read_list_exp() ->
    case ets_api:lookup(?CONST_ETS_RES_POOL, list_exp) of
        {_, List} ->
            List;
        _ ->
            0
    end.

update_pool_cast(BGold) ->
    gen_server:cast(?MODULE, {update_pool, BGold}).

win_cast(UserId, UserName, BGold) ->
    gen_server:cast(?MODULE, {win, UserId, UserName, BGold}).

win_bcash_cast(UserId, UserName, BCash)->
	gen_server:cast(?MODULE, {win_bcash, UserId, UserName, BCash}).

win_exp_cast(UserId, UserName, Exp) ->
	gen_server:cast(?MODULE, {win_exp, UserId, UserName, Exp}).

get_big_award_cast(UserId) ->
	gen_server:cast(?MODULE,{get_big_award_cast, UserId}).

put_big_award_cast({UserId,UserName,Num,Type}) ->
	gen_server:cast(?MODULE,{put_big_award_cast, {UserId,UserName,Num,Type}}).