-module(multi_translator).
%% -export([start/0, start_2/0]).
%% -include("../../include/const.generator.hrl").
%% 
%% -define(RECORD_BASE_FILE, "../include/record.base.data.hrl").
%% 
%% -define(PRINT_LINE(Format, Args),  %% console输出
%%         io:format("[~w|~w]:" ++ Format ++ "~n", [?MODULE, ?LINE] ++ Args)).
%% -define(FNAME_2(RecordName),
%%         lists:concat([RecordName, ".hrl"])).
%% -define(FNAME_3(RecordName),  
%%         lists:concat(["../include/", RecordName, ".hrl"])).
%% -define(COPY_FILE(FileName), 
%%     file:copy({?FNAME_2(FileName), [read, raw]}, {?FNAME_3("record.base.data"), [append, raw]})).
%% 
%% -define(DEFAULT_CONFIG, "server_config.xlsx").
%% 
%% start() ->
%%     FileList = 
%%         case file:list_dir(".") of
%%             {ok, List} ->
%%                 List;
%%             _ ->
%%                 []
%%         end,
%%     FileList2 = lists:filter(fun(X) -> filelib:is_file(X) end, FileList),
%%     del_file(?RECORD_BASE_FILE),
%%     del_remind_dir("../yrl/", [".svn"]),
%%     del_remind_dir("../data/", [".xlsx", ".svn", ".beam"]),
%%     F = fun("~"++_FileName) ->
%%                 skip;
%%            (FileName) ->
%%                 case filename:extension(FileName) of
%%                     ".xlsx" ->
%%                         FileRootName = filename:rootname(FileName),
%%                         file:make_dir(FileRootName),
%%                         zip:unzip(FileName, [{cwd, FileRootName}]),
%%                         Pid = self(),
%%                         PidChild = erlang:spawn_link(xlsx2yrl2, start, [Pid, FileRootName]), % XXX
%% %%                         PidChild = erlang:spawn_link(xlsx2yrl, start, [Pid, FileRootName, 10000]), % XXX
%%                         case get(pid_list) of
%%                             undefined ->
%%                                 put(pid_list, [PidChild]);
%%                             PidList ->
%%                                 put(pid_list, [PidChild|PidList])
%%                         end;
%%                     _ ->
%%                         skip
%%                 end
%%         end,
%%     lists:foreach(F, FileList2),
%%     get_msg().
%% 
%% start_2() ->
%%     FileRootNameT = filename:rootname(?DEFAULT_CONFIG),
%%     file:make_dir(FileRootNameT),
%%     zip:unzip(?DEFAULT_CONFIG, [{cwd, FileRootNameT}]),
%%     FileList  = get_list(FileRootNameT),
%%     FileList2 = lists:filter(fun(X) -> filelib:is_file(X) end, FileList),
%%     del_file(?RECORD_BASE_FILE),
%%     del_remind_dir("../yrl/", [".svn"]),
%%     del_remind_dir("../data/", [".xlsx", ".svn", ".beam"]),
%%     F = fun("~"++_FileName) ->
%%                 skip;
%%            (FileName) ->
%%                 case filename:extension(FileName) of
%%                     ".xlsx" ->
%%                         FileRootName = filename:rootname(FileName),
%%                         file:make_dir(FileRootName),
%%                         zip:unzip(FileName, [{cwd, FileRootName}]),
%%                         Pid = self(),
%%                         PidChild = erlang:spawn_link(xlsx2yrl2, start, [Pid, FileRootName]), % XXX
%% %%                         PidChild = erlang:spawn_link(xlsx2yrl, start, [Pid, FileRootName, 10000]), % XXX
%%                         case get(pid_list) of
%%                             undefined ->
%%                                 put(pid_list, [PidChild]);
%%                             PidList ->
%%                                 put(pid_list, [PidChild|PidList])
%%                         end;
%%                     _ ->
%%                         skip
%%                 end
%%         end,
%%     lists:foreach(F, FileList2),
%%     get_msg().
%% 
%% 
%% 
%% del_file(File) ->
%%     case file:delete(File) of % 先删除，再生成
%%                 _ ->
%%                     ok
%%     end.
%% 
%% %% 收取各子进程处理完成的消息
%% get_msg() ->
%%     receive
%%         {ok, PidChild, {_FileRootName, {init, Total}}} ->
%%             put({progress, PidChild}, {Total, 0}),
%%             get_msg();
%%         {ok, PidChild, {FileRootName, {progress, ProgressDelta}}} ->
%%             case get({progress, PidChild}) of
%%                 undefined ->
%%                     ok;
%%                 {Total, Progress} ->
%%                     put({progress, PidChild}, {Total, Progress+ProgressDelta}),
%%                     ?PRINT_LINE("now:~p is ~p/~p.", [FileRootName, Progress+ProgressDelta, Total])
%%             end,
%%             get_msg();
%%         {ok, _PidFinishedChild, {error, _RecordName}} ->
%%             get_msg();
%%         {ok, PidFinishedChild, {stop, RecordName}} ->
%%             TList = get(pid_list),
%%             NewList = lists:delete(PidFinishedChild, TList),
%%             put(pid_list, NewList),
%%             ?COPY_FILE(RecordName),
%%             if
%%                 erlang:length(NewList) =< 0 ->
%%                     del_remind_dir("./", [".xlsx", ".svn"]);
%%                     ok;
%%                 true ->
%%                     get_msg()
%%             end;
%%         {ok, PidFinishedChild, RecordName} ->
%%             TList = get(pid_list),
%%             NewList = lists:delete(PidFinishedChild, TList),
%%             put(pid_list, NewList),
%%             ?COPY_FILE(RecordName),
%%             if
%%                 erlang:length(NewList) =< 0 ->
%%                     del_remind_dir("./", [".xlsx", ".svn"]);
%%                     ok;
%%                 true ->
%%                     get_msg()
%%             end;
%%         _M ->
%%             get_msg()
%% %%     end.
%%     end,
%%     erlang:halt().
%% 
%% %% dfs删除无用的目录与文件
%% del_remind_dir(Dir, IgnoreList) when Dir =/= ".svn" ->
%%     case file:list_dir(Dir) of
%%         {ok, FileNames} ->
%%             del_dirs_dfs(Dir, FileNames, IgnoreList);
%%         {error, Reason} ->
%%             throw({list_dir_error, Reason})
%%     end;
%% del_remind_dir(_Dir, _IgnoreList) ->
%%     ok.
%% 
%% del_dirs_dfs(ParentName, [FileName|Tail], IgnoreDirList) when FileName =/= ".svn" ->
%%     case file:list_dir(ParentName++FileName) of
%%         {ok, FileNames} ->
%%             NewParentName = ParentName++FileName++"/",
%%             del_dirs_dfs(NewParentName, FileNames, IgnoreDirList),
%%             file:del_dir(ParentName ++ FileName),
%%             del_dirs_dfs(ParentName, Tail, IgnoreDirList);
%%         {error, _Reason} ->
%%             case lists:member(filename:extension(FileName), IgnoreDirList) of
%%                 true ->
%%                     skip;
%%                 false ->
%%                     file:delete(ParentName++FileName)
%%             end,
%%             del_dirs_dfs(ParentName, Tail, IgnoreDirList)
%%     end;
%% del_dirs_dfs(ParentName, [_FileName|Tail], IgnoreDirList) -> % .svn
%%     del_dirs_dfs(ParentName, Tail, IgnoreDirList);
%% del_dirs_dfs(_ParentName, [], _IgnoreDirList) ->
%%     ok.
%% 
%% 
