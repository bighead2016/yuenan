
-module(logger_h).

-behaviour(gen_event).

%%
%% Include files
%%
-include("../../include/const.common.hrl").

%% gen_event callbacks
-export([reopen_log/0, rotate_log/1, log_index/1]).
-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2, code_change/3]).

-define(DEFAULT_FILE_DATE, {1970, 1, 1}).
-define(DEFAULT_SPLIT_SYMBOL, "_").
-define(DEFAULT_SPLIT_CHAR, "-").
-define(DEFAULT_FILE_EXT, ".log").

-define(NO_LOG,   #rec_lv{idx = 0, type = no_log,   desc = "no_log"}).
-define(ERROR,    #rec_lv{idx = 1, type = error,    desc = "error"}).
-define(PLAYER,   #rec_lv{idx = 1, type = player,   desc = "player"}).
-define(CHAT,	  #rec_lv{idx = 1, type = chat,     desc = "chat"}).
-define(WARNING,  #rec_lv{idx = 1, type = warning,  desc = "warning"}).
-define(DEBUG,    #rec_lv{idx = 2, type = debug,    desc = "debug"}).
-define(BATTLE,   #rec_lv{idx = 3, type = battle,   desc = "battle"}).

-define(RECLV_LIST_ERROR,	[?ERROR]).
-define(RECLV_LIST_PLAYER,	[?PLAYER]).
-define(RECLV_LIST_CHAT,	[?CHAT]).
-define(RECLV_LIST_OTHER,	[
							 ?WARNING,
							 ?DEBUG,
							 ?BATTLE
							]).

-record(rec_lv, {idx, type, desc}).
-record(state,  {log_type, fd, log_dir, file_name_pre, log_lv, date, idx}).

%%%----------------------------------------------------------------------
%%% Callback functions from gen_event
%%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%% Func: init/1
%% Param: [{file_root_name, FileRootName}, {lv, Lv}]
%% Returns: {ok, State}          |
%%          Other
%%----------------------------------------------------------------------
init([LoggerType, Dir, FileNamePre, LogLv]) ->
	try
		process_flag(trap_exit, true),
		LoggerList		= rec_logger_list(LoggerType),
		Fd      		= erlang:make_tuple(length(LoggerList), 0),
		{Date, Time}	= get_time(),
		LogIndex		= log_index(Time),
		State   		= #state{log_type = LoggerType, fd = Fd, log_dir = Dir, file_name_pre = FileNamePre, log_lv = LogLv, date = Date, idx = LogIndex},
		case create_logs(State, LoggerList) of
			{ok, State2}    -> {ok, State2};
			{error, Reason} -> {error, Reason}
		end
	catch
		Type:Error ->
			?MSG_PRINT("~nType:~p~nError:~p~nStrace:~p~nProcessInfo:~p~n",
					   [Type, Error, erlang:get_stacktrace(), erlang:process_info(self())]),
			{?stop, {Type, Error}}
	end.

get_time() ->
    {MegaSecs, Secs, _} = erlang:now(),
    SecondsTemp         = MegaSecs * 1000000 + Secs,
    misc:seconds_to_localtime(SecondsTemp).

rec_logger_list(error)	-> ?RECLV_LIST_ERROR;
rec_logger_list(player) ->?RECLV_LIST_PLAYER;
rec_logger_list(chat)	-> ?RECLV_LIST_CHAT;
rec_logger_list(null)	-> [];
rec_logger_list(_)		-> ?RECLV_LIST_OTHER.

create_logs(State, [RecLv|Tail]) ->
    case create_log(RecLv, State) of
        {ok, State2} ->
            create_logs(State2, Tail);
        {error, Reason} ->
            {error, Reason}
    end;
create_logs(State, []) -> {ok, State}.

create_log(RecLv, State) when RecLv#rec_lv.type =:= chat ->
    RootDir 	= State#state.log_dir,
	TypeDir		= RecLv#rec_lv.desc,
    FileName    = log_name(State#state.file_name_pre, State#state.date, TypeDir, State#state.idx),
    FullName    = RootDir ++ "/" ++ TypeDir ++ "/" ++ FileName,
	ResultRoot	=
		case file:make_dir(RootDir) of
			ok -> ok;
			{error, eexist} -> ok;
			{error, RootReason} -> {error, RootReason}
		end,
    case ResultRoot of
        ok ->
			case file:make_dir(RootDir ++ "/" ++ TypeDir) of
				ok -> open_log_file(FullName, RecLv, State);
				{error, eexist} -> open_log_file(FullName, RecLv, State);
				{error, TypeReason} -> {error, TypeReason}
			end;
        {error, Reason} -> {error, Reason}
    end;
create_log(RecLv, State) ->
    RootDir 	= State#state.log_dir,
	TypeDir		= RecLv#rec_lv.desc,
	DateDir		= log_date_dir(State#state.date),
    FileName    = log_name(State#state.file_name_pre, State#state.date, TypeDir, State#state.idx),
    FullName    = RootDir ++ "/" ++ TypeDir ++ "/" ++ DateDir ++ "/" ++ FileName,
	ResultRoot	=
		case file:make_dir(RootDir) of
			ok -> ok;
			{error, eexist} -> ok;
			{error, RootReason} -> {error, RootReason}
		end,
    case ResultRoot of
        ok ->
			ResultType	=
				case file:make_dir(RootDir ++ "/" ++ TypeDir) of
					ok -> ok;
					{error, eexist} -> ok;
					{error, TypeReason} -> {error, TypeReason}
				end,
            case ResultType of
                ok ->
					ResultDate	=
						case file:make_dir(RootDir ++ "/" ++ TypeDir ++ "/" ++ DateDir) of
							ok -> ok;
							{error, eexist} -> ok;
							{error, DateReason} -> {error, DateReason}
						end,
					case ResultDate of
						ok -> open_log_file(FullName, RecLv, State);
						{error, Reason} -> {error, Reason}
					end;
                {error, Reason} -> {error, Reason}
            end;
        {error, Reason} -> {error, Reason}
    end.

open_log_file(FullName, RecLv, State) ->
    case file:open(FullName, [append, raw]) of
        {ok, Fd} ->
            Fd2 = setelement(RecLv#rec_lv.idx, State#state.fd, Fd),
            {ok, State#state{fd = Fd2}};
        {error, Reason} ->
            close_logs(State#state.fd),
            {error, Reason}
    end.


%% 关一堆文件

close_logs([Fd|Tail]) ->
    close_log(Fd),
    close_logs(Tail);
close_logs(FdTuple) when is_tuple(FdTuple) ->
    close_logs(misc:to_list(FdTuple));
close_logs([]) -> ok.

close_log(Fd) ->
    file:close(Fd).
%% 内部输出日志
innerlog(Type, Self, Module, Line, Format, Args, State) ->
	Event	= {Type, group_leader(), {Self, "~p|~p|~p|"++Format++"~n", [Self, Module, Line]++Args}},
	write_event_proxy(State, {get_time(), Event}).
%%----------------------------------------------------------------------
%% Func: handle_event/2
%% Returns: {ok, State}                                |
%%          {swap_handler, Args1, State1, Mod2, Args2} |
%%          remove_handler                              
%%----------------------------------------------------------------------
handle_event(Event, State) ->
    write_event_proxy(State, {get_time(), Event}).

%%----------------------------------------------------------------------
%% Func: handle_call/2
%% Returns: {ok, Reply, State}                                |
%%          {swap_handler, Reply, Args1, State1, Mod2, Args2} |
%%          {remove_handler, Reply}                            
%%----------------------------------------------------------------------
handle_call(_Request, State) ->
    Reply = ok,
    {ok, Reply, State}.

%%----------------------------------------------------------------------
%% Func: handle_info/2
%% Returns: {ok, State}                                |
%%          {swap_handler, Args1, State1, Mod2, Args2} |
%%          remove_handler                              
%%----------------------------------------------------------------------
handle_info({'EXIT', _Fd, _Reason}, _State) ->
    remove_handler;
handle_info({emulator, _GL, reopen}, State) ->
	LoggerList	= rec_logger_list(State#state.log_type),
	case create_logs(State, LoggerList) of
        {ok, State2} ->
			close_logs(State#state.fd),
			{ok, State2};
        {error, Reason} ->
			innerlog(error, self(), ?MODULE, ?LINE, "~p", [{error, Reason}], State)
    end;
handle_info({emulator, GL, Chars}, State) ->
    write_event_proxy(State, {get_time(), {emulator, GL, Chars}});
handle_info(_Info, State) ->
    {ok, State}.

%%----------------------------------------------------------------------
%% Func: terminate/2
%% Purpose: Shutdown the server
%% Returns: any
%%----------------------------------------------------------------------
terminate(Reason, State) ->
	{ok, State2}	= innerlog(error, self(), ?MODULE, ?LINE, "STOP Reason:~p", [Reason], State),
    close_logs(State2#state.fd),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

reopen_log() ->
    sg_logger ! {emulator, noproc, reopen}.

%%%----------------------------------------------------------------------
%%% Internal functions
%%%----------------------------------------------------------------------

write_event_proxy(State = #state{log_type = LoggerType, fd = Fds, idx = Idx}, {{Date, Time}, {Type, GL, {Pid, Format, Args}}}) ->
	case log_index(Time) of
		Idx ->
			LoggerList	= rec_logger_list(LoggerType),
			case get_fd(Type, Fds, LoggerList) of
				Fd = {file_descriptor, prim_file, {_Port, _}} ->
					write_event(Fd, {{Date, Time}, {Type, GL, {Pid, Format, Args}}}),
					{?ok, State};
				_Any -> {?ok, State}
			end;
		_ ->
			{?ok, State2}	= change_logs(State, Date, Time),
			innerlog(error, self(), ?MODULE, ?LINE, "LOGGER CHANGE LOG...DateTime:~p~n", [{Date, Time}], State2),
			write_event_proxy(State2, {{Date, Time}, {Type, GL, {Pid, Format, Args}}})
	end;
write_event_proxy(State, Event) ->
	innerlog(error, self(), ?MODULE, ?LINE, "LOGGER BAD EVENT...Event:~p~n", [Event], State),
	{?ok, State}.

get_fd(Type, FdTuple, [#rec_lv{idx = Idx, type = Type}|_List]) ->
    element(Idx, FdTuple);
get_fd(Type, FdTuple, [_H|List]) ->
    get_fd(Type, FdTuple, List);
get_fd(_Type, _FdTuple, []) -> 0.

% Copied from erlang_logger_file_h.erl
write_event(Fd, {Time, {error, _GL, {Pid, Format, Args}}}) ->
    T = write_time3(Time, "E"),
    case catch io_lib:format(add_node(Format,Pid), Args) of
    S when is_list(S) ->
        ?MSG_PRINT(io_lib:format(T ++ S, [])),
        file:write(Fd, io_lib:format(T ++ S, []));
    _ ->
        F = add_node("ERROR: ~p - ~p~n", Pid),
        ?MSG_PRINT(io_lib:format(T ++ F, [Format,Args])),
        file:write(Fd, io_lib:format(T ++ F, [Format,Args]))
    end;
write_event(Fd, {Time, {player, _GL, {Pid, Format, Args}}}) ->
    _T = write_time(Time, "PLAYER"),
    case catch io_lib:format(add_node(Format,Pid), Args) of
    S when is_list(S) ->
%%         ?MSG_PRINT(io_lib:format(S, [])),
        logger_fmt_factory:format(Args), % XXX
        file:write(Fd, io_lib:format(S, []));
    _ ->
        F = add_node("PLAYER: ~p - ~p~n", Pid),
%%         ?MSG_PRINT(io_lib:format(F, [Format,Args])),
        logger_fmt_factory:format(Args), % XXX
        file:write(Fd, io_lib:format(F, [Format,Args]))
    end;
write_event(Fd, {Time, {chat, _GL, {Pid, Format, Args}}}) ->
    _T = write_time(Time, "CHAT"),
    case catch io_lib:format(add_node(Format,Pid), Args) of
    S when is_list(S) ->
        ?MSG_PRINT(io_lib:format(S, [])),
        file:write(Fd, io_lib:format(S, []));
    _ ->
        F = add_node("CHAT: ~p - ~p~n", Pid),
        ?MSG_PRINT(io_lib:format(F, [Format,Args])),
        file:write(Fd, io_lib:format(F, [Format,Args]))
    end;
write_event(Fd, {Time, {debug, _GL, {Pid, Format, Args}}}) ->
    T = write_time3(Time, "D"),
    case catch io_lib:format(add_node(Format,Pid), Args) of
    S when is_list(S) ->
        ?MSG_PRINT(io_lib:format(T ++ S, [])),
        file:write(Fd, io_lib:format(T ++ S, []));
    _ ->
        F = add_node("DEBUG: ~p - ~p~n", Pid),
        ?MSG_PRINT(io_lib:format(T ++ F, [Format,Args])),
        file:write(Fd, io_lib:format(T ++ F, [Format,Args]))
    end;
write_event(Fd, {Time, {warning, _GL, {Pid, Format, Args}}}) ->
    T = write_time(Time, "WARNING"),
    case catch io_lib:format(add_node(Format,Pid), Args) of
    S when is_list(S) ->
        ?MSG_PRINT(io_lib:format(T ++ S, [])),
        file:write(Fd, io_lib:format(T ++ S, []));
    _ ->
        F = add_node("WARNING: ~p - ~p~n", Pid),
        ?MSG_PRINT(io_lib:format(T ++ F, [Format,Args])),
        file:write(Fd, io_lib:format(T ++ F, [Format,Args]))
    end;
write_event(Fd, {Time, {battle, _GL, {Pid, Format, Args}}}) ->
    T = write_time2(Time, "BATTLE"),
    case catch io_lib:format(add_node(Format,Pid), Args) of
    S when is_list(S) ->
        ?MSG_PRINT(io_lib:format(T ++ S, [])),
        file:write(Fd, io_lib:format(T ++ S, []));
    _ ->
        F = add_node("BATTLE: ~p - ~p~n", Pid),
        ?MSG_PRINT(io_lib:format(T ++ F, [Format,Args])),
        file:write(Fd, io_lib:format(T ++ F, [Format,Args]))
    end;
write_event(Fd, {Time, {error_report, _GL, {Pid, std_error, Rep}}}) ->
    T = write_time(Time),
    S = format_report(Rep),
    file:write(Fd, io_lib:format(T ++ S ++ add_node("", Pid), []));
write_event(Fd, {Time, {info_report, _GL, {Pid, std_info, Rep}}}) ->
    T = write_time(Time, "INFO REPORT"),
    S = format_report(Rep),
    file:write(Fd, io_lib:format(T ++ S ++ add_node("", Pid), []));
write_event(Fd, {Time, {info_msg, _GL, {Pid, Format, Args}}}) ->
    T = write_time(Time, "INFO REPORT"),
    case catch io_lib:format(add_node(Format,Pid), Args) of
    S when is_list(S) ->
        file:write(Fd, io_lib:format(T ++ S, []));
    _ ->
        F = add_node("ERROR: ~p - ~p~n", Pid),
        file:write(Fd, io_lib:format(T ++ F, [Format,Args]))
    end;
write_event(Fd, {Time, {emulator, _GL, Chars}}) ->
    T = write_time(Time),
    case catch io_lib:format(Chars, []) of
    S when is_list(S) ->
        file:write(Fd, io_lib:format(T ++ S, []));
    _ ->
        file:write(Fd, io_lib:format(T ++ "ERROR: ~p ~n", [Chars]))
    end;
write_event(_, _) ->
    ?MSG_PRINT("null~n"),
    ok.

format_report(Rep) when is_list(Rep) ->
    case string_p(Rep) of
    true -> io_lib:format("~s~n",[Rep]);
    _ -> format_rep(Rep)
    end;
format_report(Rep) ->
    io_lib:format("~p~n",[Rep]).

format_rep([{Tag,Data}|Rep]) ->
    io_lib:format("    ~p: ~p~n",[Tag,Data]) ++ format_rep(Rep);
format_rep([Other|Rep]) ->
    io_lib:format("    ~p~n",[Other]) ++ format_rep(Rep);
format_rep(_) ->
    [].

add_node(X, Pid) when is_atom(X) ->
    add_node(atom_to_list(X), Pid);
add_node(X, Pid) when node(Pid) /= node() ->
    lists:concat([X,"** at node ",node(Pid)," **~n"]);
add_node(X, _) ->
    X.

string_p([]) ->
    false;
string_p(Term) ->
    string_p1(Term).

string_p1([H|T]) when is_integer(H), H >= $\s, H < 255 ->
    string_p1(T);
string_p1([$\n|T]) -> string_p1(T);
string_p1([$\r|T]) -> string_p1(T);
string_p1([$\t|T]) -> string_p1(T);
string_p1([$\v|T]) -> string_p1(T);
string_p1([$\b|T]) -> string_p1(T);
string_p1([$\f|T]) -> string_p1(T);
string_p1([$\e|T]) -> string_p1(T);
string_p1([H|T]) when is_list(H) ->
    case string_p1(H) of
    true -> string_p1(T);
    _    -> false
    end;
string_p1([]) -> true;
string_p1(_) ->  false.

write_time(Time) -> write_time(Time, "ERROR REPORT").

write_time({{Y,Mo,D},{H,Mi,S}}, Type) ->
    io_lib:format("~n~s|~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w|===~n",
          [Type, Y, Mo, D, H, Mi, S]).

write_time3({_,{H,Mi,S}}, Type) ->
    io_lib:format("~n~s|~.2.0w:~.2.0w:~.2.0w|",
          [Type, H, Mi, S]).

write_time2({{Y,Mo,D},{H,Mi,S}}, Type) ->
    io_lib:format("~n~s|~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w|===\t",
          [Type, Y, Mo, D, H, Mi, S]).

%% @doc Rename the log file if exists, to "*-old.log".
%% This is needed in systems when the file must be closed before rotation (Windows).
%% On most Unix-like system, the file can be renamed from the command line and
%% the log can directly be reopened.
%% @spec (Filename::string()) -> ok
rotate_log(Filename) ->
    case file:read_file_info(Filename) of
    {ok, _FileInfo} ->
        RotationName = filename:rootname(Filename),
        file:rename(Filename, [RotationName, "-old.log"]),
        ok;
    {error, _Reason} ->
        ok
    end.

%% 变更日志日期，同时转换打开的文件
%% 要是不成功的话，将继续在旧的文件中写
%% @return {ok, NewState} -> 成功
%%         {error, OldState} -> 失败
change_logs(State, Date, Time) ->
	State2	= State#state{date = Date, idx = log_index(Time)},
    try
		LoggerList	= rec_logger_list(State#state.log_type),
        case create_logs(State2, LoggerList) of
            {ok, NewState} ->
				close_logs(State2#state.fd),
                {ok, NewState};
            {error, Reason} ->
                innerlog(error, self(), ?MODULE, ?LINE, "~p", [{error, Reason}], State2)
        end
    catch
        Type:Why ->
			innerlog(error, self(), ?MODULE, ?LINE, "Type:~p Why:~p Stack:~p", [Type, Why, erlang:get_stacktrace()], State2)
    end.

log_date_dir({Y, M, D}) ->
	Y2	= io_lib:format("~.4.0w", [Y]),
	M2	= io_lib:format("~.2.0w", [M]),
	D2	= io_lib:format("~.2.0w", [D]),
	lists:concat([Y2, M2, D2]).

%% 日志文件名
log_name(_FileNamePre, {Y, M, D}, "chat", _Idx) ->
	Y2		= io_lib:format("~.4.0w", [Y]),
	M2		= io_lib:format("~.2.0w", [M]),
	D2		= io_lib:format("~.2.0w", [D]),
    lists:concat([wwsg, ?DEFAULT_SPLIT_SYMBOL, Y2, M2, D2, ?DEFAULT_FILE_EXT]);
log_name(FileNamePre, {Y, M, D}, Desc, Idx) ->
	Y2		= io_lib:format("~.4.0w", [Y]),
	M2		= io_lib:format("~.2.0w", [M]),
	D2		= io_lib:format("~.2.0w", [D]),
	Idx2	= io_lib:format("~.3.0w", [Idx]),
    lists:concat([FileNamePre,	?DEFAULT_SPLIT_SYMBOL,
                  Desc,			?DEFAULT_SPLIT_SYMBOL,
                  Y2,			?DEFAULT_SPLIT_CHAR,
                  M2,			?DEFAULT_SPLIT_CHAR,
                  D2,			?DEFAULT_SPLIT_SYMBOL,
				  Idx2,			?DEFAULT_FILE_EXT]).

%% logger_h:log_index(misc:time()).
log_index({H, M, S}) ->
	(H * 3600 + M * 60 + S) div 1800.

