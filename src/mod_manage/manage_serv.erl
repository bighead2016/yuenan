%%
-module(manage_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.man.hrl").

-record(state, {socket, pid}).
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([get_center_node_call/1, get_master_node_call/1, get_combine_list_call/2]).

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
init(_) ->
    process_flag(trap_exit, ?true),
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
handle_call({center_node, PlatId}, _From, State) ->
    Reply = manage_api:lookup_houtai_node(PlatId, 0),
    {?reply, Reply, State};
handle_call({master_node, PlatId}, _From, State) ->
    Reply = 
        if
            1 =:= PlatId -> % 4399 特殊
                manage_api:lookup_houtai_node(PlatId, 16);
            ?true ->
                manage_api:lookup_houtai_node(PlatId, 1)
        end,
    {?reply, Reply, State};
handle_call({combine_list, PlatId, Sid}, _From, State) ->
    Reply = 
        case ets_api:lookup(?CONST_ETS_MAN_HOUTAI, {PlatId, Sid}) of
            #ets_man_houtai{combine = CombineList} ->
                CombineList;
            _ ->
                [Sid]
        end,
    {?reply, Reply, State};
handle_call(_Request, _From, State) ->
    Reply = ?ok,
    {?reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    try do_cast(Msg, State) of
        {?noreply, State2} -> 
            {?noreply, State2};
        {?stop, Reason, State3} -> 
            {?stop, Reason, State3}
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
handle_info(_Info, State) ->
    {?noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(?normal, _State) ->
    ?ok;
terminate(Reason, State) ->
    ?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]),
    ?ok.

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

do_cast(close, State) ->
    {?stop, ?normal, State};
do_cast(_Msg, State) ->
    {?noreply, State}.


%%
get_center_node_call(PlatId) ->
    gen_server:call(?MODULE, {center_node, PlatId}, 5000).

%%
get_master_node_call(PlatId) ->
    gen_server:call(?MODULE, {master_node, PlatId}, 5000).

%%
get_combine_list_call(PlatId, Sid) ->
    gen_server:call(?MODULE, {combine_list, PlatId, Sid}, 5000).
    

