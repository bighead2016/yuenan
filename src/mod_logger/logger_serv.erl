%%% -------------------------------------------------------------------
%%% Author  : huwei
%%% Description :
%%%
%%% Created : 2012-12-7
%%% -------------------------------------------------------------------
-module(logger_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/4, gc/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(SrvName, Cores, Nth, Len) ->
	misc_app:gen_server_start_link(SrvName, ?MODULE, [Cores, Nth, Len]).

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
init([_, Nth, Len]) ->
	case start_logs() of
		?ok ->
			?MSG_PRINT("~p started..........~p/~p", [?MODULE, Nth, Len]),
			{ok, #state{}};
		Result -> Result
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
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(gc, State) ->
    erlang:garbage_collect(),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
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
%% logger_serv:start_logs().
start_logs() ->
	LogsDir	= ?CONST_LOG_DIR, % config:read(logs, logs_dir),
	NamePre = misc:to_list(?CONST_LOG_FILE_NAME_PRE), %config:read(logs, logs_file_name_pre),
	LogsLv  = loglevel:get_log_lv(),
    loglevel:set(LogsDir, NamePre, LogsLv).

gc() ->
    gen_server:cast(sg_logger_player, gc),
    gen_server:cast(sg_logger_error, gc),
    gen_server:cast(sg_logger_other, gc).