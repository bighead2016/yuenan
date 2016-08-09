%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2012-11-5
%%% -------------------------------------------------------------------
-module(logger_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/2]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(SERVER, ?MODULE).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
start_link(LoggerSupName, Cores) ->
	supervisor:start_link({local, LoggerSupName}, ?MODULE, [Cores]).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init([Cores]) ->
	process_flag(trap_exit, ?true),
	List			= [error, player, chat, other],
	ChildSpecList	= child_spec_list(List, [], Cores),
    {?ok, {{one_for_one, 100, 5}, ChildSpecList}}.

child_spec_list([LoggerType|List], Acc, Cores) ->
	LoggerName	= sg_logger_name(LoggerType),
	LogsDir     = ?CONST_LOG_DIR, %config:read(logs, logs_dir),
	NamePre     = misc:to_list(?CONST_LOG_FILE_NAME_PRE), %config:read(logs, logs_file_name_pre),
	LogsLv      = loglevel:get_log_lv(), %config:read(logs, logs_lv),
	ChildSpec	= misc_app:child_spec(LoggerName, sg_logger, 
                                      [LoggerType, LogsDir, NamePre, LogsLv], 
                                      permanent, 1000, supervisor, Cores),
	child_spec_list(List, [ChildSpec|Acc], Cores);
child_spec_list([], Acc, _Cores) -> Acc.
%% ====================================================================
%% Internal functions
%% ====================================================================
sg_logger_name(LoggerType) ->
	misc:to_atom("sg_logger_" ++ misc:to_list(LoggerType)).







