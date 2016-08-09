%%% 管理者
-module(data_trans_m_serv).

-behaviour(gen_server).

%% External exports
-export([start_link/0]).
-export([push/3, pull/1, pull/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("const.generator.hrl").

%% --------------------------------------------------------------------

-record(state, {ver}).

%% ====================================================================
%% External functions
%% ====================================================================
%% buff_serv:start_link(buff_serv, 1).
start_link() -> 
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
    process_flag(trap_exit, true),
    ets:new(?ETS_FL, [set,public,named_table,{keypos, 1},{write_concurrency,true}]),
    ets:new(?ETS_CHILDREN, [set,public,named_table,{keypos, 1},{write_concurrency,true}]),
    init_fds(?FD_LIST),
    
    {_, Cwd} = file:get_cwd(),
    Pre = string:rchr(Cwd, $/),
    Pre2 = Pre + 1,
    Per = erlang:length(Cwd),
    Len = Per - Pre,
    Ver = string:substr(Cwd, Pre2, Len),
    
    start_disappear(Ver),
    {ok, #state{ver = Ver}}.

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
    catch Error:Reason ->
              ?P("~p|~p~n~p", [Error, Reason, erlang:get_stacktrace()]),
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
        {stop, _Reason, State2} -> {stop, normal, State2}
    catch Error:Reason ->
              ?P("~p|~p~n~p", [Error, Reason, erlang:get_stacktrace()]),
              push(?KEY_ERROR, error, io_lib:format("~p|~p|~p|~p~n~p", 
                                                    [?MODULE, ?LINE, Error, Reason, erlang:get_stacktrace()])),
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
        {noreply, State2} -> {noreply, State2};
        {stop, Reason, State2} -> {stop, Reason, State2}
    catch Error:Reason ->
              ?P("~p|~p~n~p", [Error, Reason, erlang:get_stacktrace()]),
              {noreply, State}
    end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    handle_hrl(),
    del_remind_dir("./", [".xlsx", ".svn", ".app"]),
    push(?KEY_PROCESS, die, io_lib:format("oh no...", [])),
    close_all(),
    halt().

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


do_cast({die, Reason, Pid, Name}, State) ->
    ets:delete(?ETS_CHILDREN, Pid),
    Size = ets:info(?ETS_CHILDREN, size),
    data_trans_m_serv:push(?KEY_PROCESS, stop, io_lib:format("~p|~p", [Name, Reason])),
    RemindList = pull(?KEY_TMP, ?DIC_FILE_LIST),
    if
        Size =< 0 andalso [] =:= RemindList ->
            {stop, normal, State};
        true ->
            Self = self(), 
            gen_server:cast(Self, continue),
            {noreply, State}
    end;
do_cast(continue, State) ->
    start_disappear_continue(State#state.ver),
    {noreply, State};
do_cast(_Msg, State) ->
    {noreply, State}.

do_info({ok, PidChild, {FileRootName, {progress, ProgressDelta}}}, State) ->
    case ets:lookup(?ETS_CHILDREN, PidChild) of
        [{_, _, Count, Max, _}] ->
            NewCount = Count+ProgressDelta,
%%             ?P("~p is ~p/~p.", [FileRootName, Count+ProgressDelta, Max]),
            ets:update_element(?ETS_CHILDREN, PidChild, [{3, NewCount}]),
            data_trans_m_serv:push(?KEY_PROCESS, now, io_lib:format("~p is ~p/~p.", [FileRootName, NewCount, Max]));
        _ ->
            ok
    end,
    {noreply, State};
do_info({ok, _PidFinishedChild, {stop, _RecordName}}, State) ->
    {noreply, State};
do_info({ok, PidChild, {_FileRootName, {init, Total}}}, State) ->
    ets:update_element(?ETS_CHILDREN, PidChild, [{4, Total}]),
    {noreply, State};
do_info({ok, _PidFinishedChild, {error, RecordName}}, State) ->
    data_trans_m_serv:push(?KEY_ERROR, error, io_lib:format("~p", [RecordName])),
    {noreply, State};
do_info({ok, PidChild, {check, FileRootName}}, State) ->
    ets:update_element(?ETS_CHILDREN, PidChild, [{5, 1}]),
    ?P("[~s]check ok", [FileRootName]),
    data_trans_m_serv:push(?KEY_PROCESS, check, io_lib:format("[~s] correct.", [FileRootName])),
    {noreply, State};
do_info({error, PidChild, {check, FileRootName, Type, Why, Stack}}, State) ->
%%     ets:update_element(?ETS_CHILDREN, PidChild, [{5, 1}]),
    ets:delete(?ETS_CHILDREN, PidChild),
    ?P("[~s]check err[~p|~p]~n~p", [FileRootName, Type, Why, Stack]),
    data_trans_m_serv:push(?KEY_ERROR, check, io_lib:format("[~s|~p|~p]~n~p", [FileRootName, Type, Why, Stack])),
    {noreply, State};
do_info({ok, _PidFinishedChild, _RecordName}, State) ->
    {noreply, State};
do_info(_Info, State) ->
    {noreply, State}.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

handle_hrl() ->
    HrlFileList = filelib:wildcard("*.hrl"),
    file:delete(?RECORD_BASE_FILE),
    case file:open(?RECORD_BASE_FILE, [read, write]) of
        {ok, Fd} ->
            handle_hrl(Fd, HrlFileList),
            file:close(Fd),
            ok;
        {error, Reason} ->
            ?P("!err:~p", [Reason])
    end.

handle_hrl(Fd, [Filename|Tail]) ->
    file:write(Fd, io_lib:format("-include(\"~s\").~n", [Filename])),
    file:copy(Filename, lists:concat([?PATH_HRL, Filename])),
    handle_hrl(Fd, Tail);
handle_hrl(_Fd, []) ->
    ok.

%% ====================================================================
%% API functions
%% ====================================================================
start_disappear(Ver) ->
    EffFileList = read_effective_list(?DEFAULT_CONFIG),
    push(?KEY_TMP, ?DIC_FILE_LIST, EffFileList),
    start_disappear_2(EffFileList, Ver).
start_disappear_2([Filename|Tail] = FList, Ver) ->
    Count = ets:info(?ETS_CHILDREN, size), 
    ?P(">>~p", [Filename]),
    if
        Count < ?PROCESS_LIMIT ->
            FileRootName = filename:rootname(Filename),
            file:make_dir(FileRootName),
            zip:unzip(Filename, [{cwd, FileRootName}]),
            Pid = self(),
            Atom = erlang:list_to_atom(FileRootName),
            case data_trans_w_serv:start_link(Pid, [Atom, Ver]) of
                {ok, PidChild} ->
                    push(?KEY_TMP, children, {PidChild, Atom, 0, 0, 0}),
                    push(?KEY_TMP, ?DIC_FILE_LIST, Tail);
                _ ->
                    ok
            end,
            start_disappear_2(Tail, Ver);
        true ->
            push(?KEY_TMP, ?DIC_FILE_LIST, FList)
    end;
start_disappear_2([], _Ver) ->
    ok.

start_disappear() ->
    EffFileList = read_effective_list(?DEFAULT_CONFIG),
    push(?KEY_TMP, ?DIC_FILE_LIST, EffFileList),
    start_disappear_2(EffFileList).
start_disappear_2([Filename|Tail] = FList) ->
    Count = ets:info(?ETS_CHILDREN, size), 
    ?P(">>~p", [Filename]),
    if
        Count < ?PROCESS_LIMIT ->
            FileRootName = filename:rootname(Filename),
            file:make_dir(FileRootName),
            zip:unzip(Filename, [{cwd, FileRootName}]),
            Pid = self(),
            Atom = erlang:list_to_atom(FileRootName),
            case data_trans_w_serv:start_link(Pid, [Atom, 1]) of
                {ok, PidChild} ->
                    push(?KEY_TMP, children, {PidChild, Atom, 0, 0, 0}),
                    push(?KEY_TMP, ?DIC_FILE_LIST, Tail);
                _ ->
                    ok
            end,
            start_disappear_2(Tail);
        true ->
            push(?KEY_TMP, ?DIC_FILE_LIST, FList)
    end;
start_disappear_2([]) ->
    ok.

start_disappear_continue(Ver) ->
    case pull(?KEY_TMP, ?DIC_FILE_LIST) of
        [Filename|Tail] ->
            ?P(">>~p", [Filename]),
            push(?KEY_TMP, ?DIC_FILE_LIST, Tail),
            FileRootName = filename:rootname(Filename),
            file:make_dir(FileRootName),
            zip:unzip(Filename, [{cwd, FileRootName}]),
            Pid = self(),
            Atom = erlang:list_to_atom(FileRootName),
            case data_trans_w_serv:start_link(Pid, [Atom, Ver]) of
                {ok, PidChild} ->
                    push(?KEY_TMP, children, {PidChild, Atom, 0, 0, 0});
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

%% ====================================================================
%% Internal functions
%% ====================================================================
read_effective_list(ConfigFilename) ->
    FileRootNameT = filename:rootname(ConfigFilename),
    file:make_dir(FileRootNameT),
    zip:unzip(ConfigFilename, [{cwd, FileRootNameT}]),
    FileList  = get_list(FileRootNameT),
    select_regular(FileList, []).

select_regular(["~"++_Filename|Tail], OldList) ->
    select_regular(Tail, OldList);
select_regular([Filename|Tail], OldList) ->
    case filelib:is_regular(Filename) of
        true ->
            case filename:extension(Filename) of
                ".xlsx" ->
                    select_regular(Tail, [Filename|OldList]);
                _ ->
                    push(?KEY_ERROR, err, io_lib:format("no this file[~p]", [Filename])),     
                    select_regular(Tail, OldList)
            end;
        false ->
            push(?KEY_ERROR, err, io_lib:format("no this file[~p]", [Filename])),
            select_regular(Tail, OldList)
    end;
select_regular([], List) ->
    List.

get_list(FileRootName) ->
    FileList = xlsx_tools:start(FileRootName),
    push(?KEY_BACK, ?DIC_FILE_LIST, io_lib:format("~p", [FileList])),
    FileList.

push(?KEY_TMP, children, {Pid, Name, Count, Max, IsChecked}) -> 
    ets:insert(?ETS_CHILDREN, {Pid, Name, Count, Max, IsChecked});
push(?KEY_TMP, K, V) -> put(K, V);
push(Key, K, V) -> 
    case ets:lookup(?ETS_FL, Key) of
        [{_, _, Fd}] ->
            file:write(Fd, io_lib:format("~p="++V++"~n", [K]));
        _ ->
            ok
    end.

pull(?KEY_TMP) -> get().

pull(?KEY_TMP, K) -> get(K);
pull(?KEY_DEBUG, _K) -> ok;
pull(?KEY_PROCESS, _K) -> ok;
pull(?KEY_ERROR, _K) -> ok;
pull(?KEY_BACK, _K) -> ok.

%% 初始化文件io
init_fds([{Key, Filename}|Tail]) ->
    FileFullName = ?PATH_LOG++Filename,
    case file:open(FileFullName, [read, write]) of
        {ok, Fd} ->
            ets:insert(?ETS_FL, {Key, FileFullName, Fd}),
            ok;
        {error, Reason} ->
            ?P("!err:~p|~p|~p", [Key, Filename, Reason]),
            ok
    end,
    init_fds(Tail);
init_fds([]) ->
    ok.

close_all() ->
    FdList = ets:tab2list(?ETS_FL),
    close(FdList).
close([{_, _, Fd}|Tail]) ->
    file:close(Fd),
    close(Tail);
close([]) ->
    ok.

%% dfs删除无用的目录与文件
del_remind_dir(Dir, IgnoreList) when Dir =/= ".svn" ->
    case file:list_dir(Dir) of
        {ok, FileNames} ->
            del_dirs_dfs(Dir, FileNames, IgnoreList);
        {error, Reason} ->
            throw({list_dir_error, Reason})
    end;
del_remind_dir(_Dir, _IgnoreList) ->
    ok.

del_dirs_dfs(ParentName, [FileName|Tail], IgnoreDirList) when FileName =/= ".svn" ->
    case file:list_dir(ParentName++FileName) of
        {ok, FileNames} ->
            NewParentName = ParentName++FileName++"/",
            del_dirs_dfs(NewParentName, FileNames, IgnoreDirList),
            file:del_dir(ParentName ++ FileName),
            del_dirs_dfs(ParentName, Tail, IgnoreDirList);
        {error, _Reason} ->
            case lists:member(filename:extension(FileName), IgnoreDirList) of
                true ->
                    skip;
                false ->
                    file:delete(ParentName++FileName)
            end,
            del_dirs_dfs(ParentName, Tail, IgnoreDirList)
    end;
del_dirs_dfs(ParentName, [_FileName|Tail], IgnoreDirList) -> % .svn
    del_dirs_dfs(ParentName, Tail, IgnoreDirList);
del_dirs_dfs(_ParentName, [], _IgnoreDirList) ->
    ok.