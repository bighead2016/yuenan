-module(loglevel).

-export([set/0, set/1, get/0, get_log_lv/0]).

-include("const.common.hrl").
-include("const.define.hrl").
 
-define(ERROR_LOGGER, "sg_logger").

%% Error levels:
-define(LOG_LEVELS,[
					{0,		no_log, 	"No log"},
					{1, 	error, 		"Error"},
					{2, 	player, 	"Player"},
					{3, 	chat, 		"Chat"},
					{4, 	debug, 		"Debug"},
					{5, 	warning, 	"Warning"},
                    {6,     battle,     "Battle"}
				   ]).

get() ->
    Level = logger:get(),
    case lists:keysearch(Level, 1, ?LOG_LEVELS) of
        {value, Result} -> Result;
        _ -> erlang:error({no_such_loglevel, Level})
    end.

get_log_lv() ->
    case config:read_deep([server, base, debug]) of
        ?CONST_SYS_TRUE ->
            config:read_deep([server, debug, logs_lv]);
        _ ->
            config:read_deep([server, release, logs_lv])
    end.

set() ->
    LogsLv = get_log_lv(),
    set(LogsLv).
set(LogsLv) when is_atom(LogsLv) ->
    set(level_to_integer(LogsLv));
set(LogsLv) when is_integer(LogsLv) ->
    try
        {Mod,Code} = dynamic_compile:from_string(logger_src(LogsLv)),
        code:load_binary(Mod, ?ERROR_LOGGER ++ ".erl", Code),
		?ok
    catch
        Type:Error -> ?MSG_SYS("Error compiling logger (~p): ~p~n", [Type, Error]), {Type, Error}
    end;
set(_LogsLv) ->
    exit("Loglevel must be an integer").

level_to_integer(Level) ->
    case lists:keysearch(Level, 2, ?LOG_LEVELS) of
        {value, {Int, Level, _Desc}} -> Int;
        _ -> erlang:error({no_such_loglevel, Level})
    end.

%% --------------------------------------------------------------
%% Code of the mcs logger, dynamically compiled and loaded
%% This allows to dynamically change log level while keeping a
%% very efficient code.
logger_src(Loglevel) ->
    L = integer_to_list(Loglevel),
    Head = "  -module(logger). ",
    Export = "  -export([debug_msg/4, warning_msg/4, chat_msg/4, player_msg/4, error_msg/4, battle_msg/2, get/0]).  ",
    Get = "  get() -> " ++ L ++ ".  ",
    
    BattleLogger = "  battle_msg(Format, Arg) -> notify(sgger_other, battle, \"S->|\"++Format++\"|~n\",Args).  ",
    BattleLoggerNon = "  battle_msg(_Format, _Arg) -> ok.  ",
    
    DebugLogger = "  debug_msg(Module, Line, Format, Args) -> notify(sg_logger_other,debug,\"~p|~p|~p|\"++Format++\"~n\",[self(), Module, Line]++Args).  ",
    DebugLoggerNon = "  debug_msg(_,_,_,_) -> ok.  ",
    
    WarningLogger = "  warning_msg(Module, Line, Format, Args) -> notify(sg_logger_other, warning,\"W(~p:~p:~p) : \"++Format++\"~n\",[self(), Module, Line]++Args).  ",
    WarningLoggerNon = "  warning_msg(_,_,_,_) -> ok.  ",
    
    ChatLogger = "  chat_msg(_Module, _Line, Format, Args) -> notify(sg_logger_chat, chat,\"\"++Format++\"~n\",Args).  ",
    ChatLoggerNon = "  chat_msg(_,_,_,_) -> ok.  ",
    
    PlayerLogger = "  player_msg(_Module, _Line, Format, Args) -> notify(sg_logger_player, player,\"\"++Format++\"~n\",Args).  ",
    PlayerLoggerNon = "  player_msg(_,_,_,_) -> ok.  ",
    
    ErrorLogger =  "  error_msg(Module, Line, Format, Args) ->
                        case Args of
                            %% start with : ** Node php
                            [42,42,32,78,111,100,101,32,112,104,112|_] ->
                                ok;
                            _ ->
                                notify(sg_logger_error, error,
                                   \"~p|~p|~p|\"++Format++\"~n\",
                                   [self(), Module, Line]++Args)
                        end.  ",
    ErrorLoggerNon = "  error_msg(_,_,_,_) -> ok.  ",
    
%%     CriticalLogger = "critical_msg(Module, Line, Format, Args) -> notify(sg_logger_other, critical,\"C(~p:~p:~p) : \"++Format++\"~n\",[self(), Module, Line]++Args). \n ",
%%     CriticalLoggerNon = "critical_msg(_,_,_,_) -> ok. \n ",
    
    Notify =  "  %% Distribute the message to the Erlang error logger 
               notify(LoggerName, Type, Format, Args) ->
                            LoggerMsg = {Type, group_leader(), {self(), Format, Args}},
                            gen_event:notify(LoggerName, LoggerMsg). ",
    
    L1 =    [
             {1, ErrorLogger},
             {2, PlayerLogger},
             {3, ChatLogger}, 
             {4, DebugLogger}, 
             {5, WarningLogger}, 
             {6, BattleLogger} 
            ],
    L2 =    [
             {1, ErrorLoggerNon},
             {2, PlayerLoggerNon},
             {3, ChatLoggerNon}, 
             {4, DebugLoggerNon}, 
             {5, WarningLoggerNon}, 
             {6, BattleLoggerNon} 
            ],
    
    L3 = get_logger_list(Loglevel, L1, L2, []),
    Content = Head ++ Export ++ Get ++ L3 ++ Notify,
%%     ?MSG_SYS("~n~n~n~n~n~n~n~p", [Content]),
    Content.

get_logger_list(Lv, [{Lv1, L1C}|Tail], L2, OldL3) when Lv1 =< Lv ->
    get_logger_list(Lv, Tail, L2, OldL3++L1C);
get_logger_list(Lv, [{Lv1, _L1C}|Tail], L2, OldL3) ->
    case lists:keyfind(Lv1, 1, L2) of
        {_, L2C} ->
            get_logger_list(Lv, Tail, L2, OldL3++L2C);
        _ ->
            get_logger_list(Lv, Tail, L2, OldL3)
    end;
get_logger_list(_Lv, [], _L2, L3) ->
    L3.
