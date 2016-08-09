
-module(center_gift_media_card_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([start_link/0, start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([generate_code_cast/4, chk_gift_call/1, rollback_call/1, del_code_call/1]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
start_link(_, _) ->
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
    try
        process_flag(trap_exit, ?true),
        ok
    catch
        X:Y ->
            ?MSG_SYS("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end,
    {ok, #state{}}.

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
do_call({"chk_gift", Code}, _From, State) ->
    R = center_mod:check_gift(Code),
    {?reply, R, State};
do_call({"del_code", Code}, _From, State) ->
    R = center_mod:del_code(Code),
    {?reply, R, State};
do_call({"rollback", Code}, _From, State) ->
    R = center_mod:rollback(Code),
    {?reply, R, State};
do_call(Request, _From, State) ->
    Reply = ?ok,
    ?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.

do_cast({"gen", Key, Type, Count, ArgList}, State) ->
    center_mod:gen_code(Type, Key, Count, ArgList),
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

%% 生成激活码
generate_code_cast(_Key, Type, Count, ArgList) ->
    LKey = misc:to_list(config:read(platform_info, #rec_platform_info.login_key)),
    gen_server:cast(?MODULE, {"gen", LKey, Type, Count, ArgList}).

chk_gift_call(CodeUpper) -> 
    gen_server:call(?MODULE, {"chk_gift", CodeUpper}, ?CONST_TIMEOUT_CALL).

del_code_call(CodeUpper) -> 
    gen_server:call(?MODULE, {"del_code", CodeUpper}, ?CONST_TIMEOUT_CALL).

rollback_call(CodeUpper) -> 
    gen_server:call(?MODULE, {"rollback", CodeUpper}, ?CONST_TIMEOUT_CALL).

