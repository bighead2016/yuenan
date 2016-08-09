%%% a data machine who loves eating <Module>_data_generator.erl,
%%% and produces something strange to /src/data/data_<Module>.erl.
%%% enjoy it... 
%%% p.s.:
%%% 	1.data_generator
%%%        在const.generator.hrl里面写模块名
%%%        每个模块必需要有回调generate()
%%%     2.需要对生成后的data_*进行数据验证的话，
%%%        要在const.generator.hrl里面写生成调用的模块名
%%%        并在该模块中实现回调analye/0
%%%        返回值会被直接无视
%%%     3.例子: 根目录是sh
%%%        {
%%             2,            <- idx
%%             [    
%%                 {cld,"../src/mod_map", "#_data_generator"},      <- 命令行        
%%                 {r,".","#_data_generator", "generate", "."},     <- 命令行
%%                 {clm,"../src/data","data_#","../ebin"}],         <- 命令行
%%             [
%%                 npc            % npc
%%             ]
%%          },
%%          {
%%              idx, [命令行列表], [模块列表]
%%          }
%%          {命令,参数...} #会被模块名代替
%%          命令有
%%          {cld, erl文件路径,文件名}
%%          {cl,erl文件路径,文件名}
%%          {clm,erl文件路径,文件名,移动目标路径}
%%          {r,erl文件路径,调用函数名,返回根目标相对路径}
%%          c:编译;l:加载;d:删除;m:移动;r:运行
-module(data_machine).

%%
%% Include files
%%
-include("const.generator.hrl").
-include("const.common.hrl").

%% -define(RECORD_BASE_FILE, "../../include/record.base.data.hrl").
-define(LOG_LOADED(Mod), io:format("l:~p...~n", [Mod])).
-define(LOG_PROCESS(P), io:format("p:~p...~n", [P])).
-define(LOG_RUN(M), io:format("r:~p...~n", [M])).
-define(LOG_C(M), io:format("c:~p...~n", [M])).
-define(LOG_ERROR(Type, Why, Stack), io:format("~p:~p -> ~p...~n", [Type, Why, Stack])).
-define(MAX_IDX, 100).

%%
%% Exported Functions
%%
-export([main/0]).

%%
%% API Functions
%%

main() ->
    try
        ?LOG_PROCESS(get_time()),
        ok = do(0),
        stop()
    catch
        Type:Why ->
            ?LOG_ERROR(Type, Why, erlang:get_stacktrace()),
            ?LOG_PROCESS("sorry:error && end"),
            erlang:halt()
    end.

do(Process) when Process =< ?MAX_IDX ->
    case get_priority_list(Process) of
        null ->
            ok;
        {OpList, ModList} ->
            do_op_list(OpList, ModList),
            do(Process+1)
    end;
do(_) ->
    ok.

do_op_list([Op|Tail], ModList) ->
    do_op(Op, ModList),
    do_op_list(Tail, ModList);
do_op_list([], _) ->
    ok.

do_op(Op, [Mod|Tail]) ->
    RealOp = trans_op(Op, Mod),
    do_real_op(RealOp, Mod),
    do_op(Op, Tail);
do_op(_, []) ->
    ok.

do_real_op({cld, Src, Handler}, _) ->
    compile(Handler, Src),
    load(Handler),
    del(Handler);
do_real_op({cl, Src, Handler}, _) ->
    compile(Handler, Src),
    load(Handler);
do_real_op({clm, Src, Handler, TargetDir}, _) ->
    compile(Handler, Src),
    load(Handler),
    move(Handler, TargetDir); 
do_real_op({r, Src, Handler, Func, Ret, Ver}, _) ->
    goto(Src),
    run(Handler, Func, Ver),
    goto(Ret);
do_real_op(_, _) ->
    ok.

%% ------------------------ tools ------------------------------------
%% 转换路径
goto(".") ->
    ok;
goto(Path) ->
    c:cd(Path).

%% 编译
compile(Mod, Src) ->
    Mod2 = lists:concat([Src, "/", Mod, ".erl"]),
    ?LOG_C(Mod),
    c:c(Mod2, [{i, "../include/hrl"}, {i, "../include"}]).

%% 加载
load(Mod) ->
%%     ?LOG_LOADED(Mod),
    c:l(Mod).

%% 删除
del(Mod) ->
    BeamFile = lists:concat([Mod, ".beam"]),
    file:delete(BeamFile).

%% 运行
%% run(Mod, Func) ->
%%     ?LOG_RUN(Mod),
%%     Mod:Func().
run(Mod, Func, Ver) ->
    ?LOG_RUN(Mod),
    Mod:Func(Ver).

%% 移动
move(File, TargetDir) ->
    File2 = lists:concat([File, ".beam"]),
    TargetDir2 = lists:concat([TargetDir, "/", File2]),
    file:rename(File2, TargetDir2),
    ok.

%% 停
stop() ->
    erlang:halt().

%% 转换字命令行
trans_op({cld, Src, Add}, Mod) ->
    RealSrc         = to_real(Src, Mod),
    RealHandlerAtom = to_real_atom(Add, Mod),
    {cld, RealSrc, RealHandlerAtom};
trans_op({cl, Src, Add}, Mod) ->
    RealSrc         = to_real(Src, Mod),
    RealHandlerAtom = to_real_atom(Add, Mod),
    {cl, RealSrc, RealHandlerAtom};
trans_op({clm, Src, Add, TargetDir}, Mod) ->
    RealSrc         = to_real(Src, Mod),
    RealHandlerAtom = to_real_atom(Add, Mod),
    RealTargetDir   = to_real_atom(TargetDir, Mod),
    {clm, RealSrc, RealHandlerAtom, RealTargetDir};
trans_op({r, Src, Add, Func, Ret, Ver}, Mod) ->
    RealSrc         = to_real(Src, Mod),
    RealHandlerAtom = to_real_atom(Add, Mod),
    RealFuncAtom    = to_real_atom(Func, Mod),
    RealRet         = to_real(Ret, Mod),
    {r, RealSrc, RealHandlerAtom, RealFuncAtom, RealRet, Ver};
trans_op(X, _) ->
    X.

%% 
to_real(X, Mod) ->
    {Result, Be4, After} = find_sharp(X),
    concat(Result, Be4, Mod, After).

to_real_atom(X, Mod) ->
    {Result_Func, Be4_Func, After_Func} = find_sharp(X),
    RealFunc = concat(Result_Func, Be4_Func, Mod, After_Func),
    erlang:list_to_atom(RealFunc).

%% 查找#的位置
find_sharp(X) ->
    find_sharp(X, []).

find_sharp([$#|Tail], Be4) ->
    Be4_2 = lists:reverse(Be4),
    {1, Be4_2, Tail};
find_sharp([P|Tail], Be4) ->
    find_sharp(Tail, [P|Be4]);
find_sharp([], Be4) ->
    Be4_2 = lists:reverse(Be4),
    {0, Be4_2, []}.

%% 字串合成
concat(0, Be4, _Mod, []) ->
    Be4;
concat(1, Be4, Mod, []) ->
    lists:concat([Be4, Mod]);
concat(_, Be4, Mod, After) ->
    lists:concat([Be4, Mod, After]).

%% 读取时间
get_time() ->
	{{Y,M,D}, {H,Mi,S}} = calendar:local_time(),
	lists:concat([Y, "-", M, "-", D, "   ", H, ":", Mi, ":", S]).

%% 读取优先级列表
get_priority_list(Process) ->
    case lists:keyfind(Process, 1, ?POOR_GUY_LIST) of
        {_, OpList, ModList} -> {OpList, ModList};
        _                    -> null
    end.