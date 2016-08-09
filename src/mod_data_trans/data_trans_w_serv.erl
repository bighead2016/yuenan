%%% 咕噜
-module(data_trans_w_serv).

-behaviour(gen_server).

%% External exports
-export([start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("const.generator.hrl").

-record(state, {parent, dying_msg, name, ver}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(Pid, [FileRootName, Ver]) ->
    gen_server:start_link({local, FileRootName}, data_trans_w_serv, [Pid, FileRootName, Ver], []).

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
init([Pid, FileRootName, Ver]) ->
    data_trans_m_serv:push(?KEY_PROCESS, init, io_lib:format("~p|~p", [FileRootName, Ver])),
    trans_cast(Ver),
%%     kill_cast(),
    {ok, #state{parent = Pid, name = FileRootName, ver = Ver}}.

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
        {reply, Reply, State2} -> {reply, Reply, State2}
    catch _Error:_Reason ->
              {noreply, State}
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
        {noreply, State2} -> {noreply, State2};
        {stop, Reason, State2} -> {stop, normal, State2#state{dying_msg = Reason}}
    catch _Error:_Reason ->
              {noreply, State}
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
        {noreply, State2} -> {noreply, State2}
    catch _Error:_Reason ->
              {noreply, State}
    end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, State) ->
    Self = self(),
    gen_server:cast(State#state.parent, {die, State#state.dying_msg, Self, State#state.name}),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

do_cast(finish, State) ->
    {stop, finish, State};
do_cast({trans, Ver}, State) ->
    xlsx2yrl_mochi:start(State#state.parent, [erlang:atom_to_list(State#state.name), Ver]),
    finish_cast(),
    {noreply, State};
do_cast(_Msg, State) ->
    {noreply, State}.

do_info(_Info, State) ->
    {noreply, State}.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% ====================================================================
%% API functions
%% ====================================================================

finish_cast() ->
    gen_server:cast(self(), finish).

trans_cast(Ver) ->
    gen_server:cast(self(), {trans, Ver}).
