%% 协议分析器
-module(analysis).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-define(P(Format, Data),
        ?MSG_DEBUG("send|"++Format++"|", Data)).
-define(H(Data),
        ?MSG_DEBUG("handler -> |ModHandler=~p, MsgId=~p, Datas=~p|", Data)).
-define(y_list,       [
                       {copy_single_handler, [0]}
                      ]).
-define(X_LIST,       [
                       {3120, x_unpack2}
                      ]).

%%
%% Exported Functions
%%
-export([x/1, x2/2, x3/3, x4/2, y/3, z/2, d/1, s/3, s1/2, sp/1, n/1,
         dump/0, dump2/0, topN/1]).
-export([x_unpack2/5]).

%%
%% API Functions
%%
x(<<>>) ->
    ?P("<<>>", []);
x(<<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>) ->
    x_unpack(Len, Cmd, IsZip, Hex, Body),
    x(Tail, 1).

x(<<>>, _) ->
    ok;
x(<<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>, IsNext) ->
    x_unpack(Len, Cmd, IsZip, Hex, Body),
    x(Tail, IsNext).

x3(_M, _L, <<>>) ->
    ?P("<<>>", []);
x3(M, L, <<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>) ->
    case misc_packet:unpack(0, Cmd, IsZip, Hex, Body) of
        {?ok, _ModHandler, _MsgId, Datas} ->
            ?P("M=~p, L=~p, Len=~p, Cmd=~p, IsZip=~p, Hex=~p~n|Body=~p|Data=~p", [M, L, Len, Cmd, IsZip =:= 1, Hex, Body, Datas]);
        X ->
            ?P("M=~p, L=~p, Len=~p, Cmd=~p, IsZip=~p, Hex=~p~n|X=~p", [M, L, Len, Cmd, IsZip =:= 1, Hex, X])
    end,
    x3(M, L, Tail, 1).

x3(_M, _L, <<>>, _) ->
    ok;
x3(M, L, <<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>, IsNext) ->
    case misc_packet:unpack(0, Cmd, IsZip, Hex, Body) of
        {?ok, _ModHandler, _MsgId, Datas} ->
            ?P("M=~p, L=~p, Len=~p, Cmd=~p, IsZip=~p, Hex=~p~n|Body=~p|Data=~p", [M, L, Len, Cmd, IsZip =:= 1, Hex, Body, Datas]);
        X ->
            ?P("M=~p, L=~p, Len=~p, Cmd=~p, IsZip=~p, Hex=~p~n|X=~p", [M, L, Len, Cmd, IsZip =:= 1, Hex, X])
    end,
    x3(M, L, Tail, IsNext).

x2(Pid, Packet) when is_pid(Pid) ->
    Name = n(Pid),
    x2(Name, Packet);
x2(Pid, Packet) when is_integer(Pid) ->
    Name = n(self()),
    x2(Name, Packet);
x2(_Name, <<>>) ->
    ?P("<<>>", []);
x2(Name, <<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>) ->
    x_unpack(Name, Len, Cmd, IsZip, Hex, Body),
%%     case lists:keyfind(Cmd, 1, ?X_LIST) of
%%         {_, Func} ->
%%             Func(Len, Cmd, IsZip, Hex, Body);
%%         ?false ->
%%             ?ok
%%     end,
    x2(Name, Tail, 1).

x2(_Name, <<>>, _) ->
    ?ok;
x2(Name, <<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>, IsNext) ->
    x_unpack(Name, Len, Cmd, IsZip, Hex, Body),
%%     case lists:keyfind(Cmd, 1, ?X_LIST) of
%%         {_, Func} ->
%%             Func(Len, Cmd, IsZip, Hex, Body);
%%         ?false ->
%%             ?ok
%%     end,
    x2(Name, Tail, IsNext).

x_unpack(_Len, Cmd, IsZip, Hex, Body) ->
    case misc_packet:unpack(0, Cmd, IsZip, Hex, Body) of
        {?ok, _ModHandler, _MsgId, Datas} ->
%% 			ok;
%%             ?P("Len=~p, Cmd=~p, IsZip=~p, Hex=~p~n|Body=~p|Data=~p", [Len, Cmd, IsZip =:= 1, Hex, Body, Datas]);
            ?P("Cmd=~p|Data=~w", [Cmd, Datas]);
        X ->
%% 			ok
%%             ?P("Len=~p, Cmd=~p, IsZip=~p, Hex=~p~n|X=~p", [Len, Cmd, IsZip =:= 1, Hex, X])
            ?P("Cmd=~p|X=~w", [Cmd, X])
    end.
x_unpack(Name, _Len, Cmd, IsZip, Hex, Body) ->
    case unpack(0, Cmd, IsZip, Hex, Body) of
        {?ok, _ModHandler, _MsgId, Datas} ->
            ?P("~p|~p|~w", [Name, Cmd, Datas]);
        X ->
            ?P("~p|~p|~w", [Name, Cmd, X])
    end.

x_unpack2(Len, Cmd, IsZip, Hex, Body) ->
    case unpack(0, Cmd, IsZip, Hex, Body) of
        {?ok, _ModHandler, _MsgId, Datas} ->
            ?P("Data=~w", [Datas]);
        X ->
            ?P("Len=~p, Cmd=~p, IsZip=~p, Hex=~p~n|X=~p", [Len, Cmd, IsZip =:= 1, Hex, X])
    end.

unpack(_CheckSum, MsgId, Zip, _Hex, BinaryZip) ->
    try
        Binary      = case Zip of
                          0  -> BinaryZip;
                          1   -> zlib:uncompress(BinaryZip)
                      end,
        {
         ModPacket,
         ModHandler
        }           = gateway_dispatcher:dispatch(MsgId),
        MsgFormat   = ModPacket:packet_format(MsgId),
        Datas       = misc_packet:decode(Binary, MsgFormat),
        {?ok, ModHandler, MsgId, Datas}
    catch
        _Error:Reason ->
            ?P("BAD PACKET === MsgId:~p Binary:~p", [MsgId, BinaryZip]),
            ?P("Error:Reason ~p:~p",[Reason,erlang:get_stacktrace()])
    end.

y(ModHandler, MsgId, Datas) ->
    case lists:keyfind(ModHandler, 1, ?y_list) of
        {_, MsgIdList} ->
            case lists:member(MsgId, MsgIdList) of
                ?true ->
                    ?H([ModHandler, MsgId, Datas]);
                ?false when MsgIdList =:= [0] ->
                    ?H([ModHandler, MsgId, Datas]);
                ?false ->
                    ?ok
            end;
        _ ->
            ?ok
    end.

%% 统计每个包的长度
x4(<<>>, SizeList) ->
    SizeList;
x4(<<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>, SizeList) ->
    Packet = <<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary>>,
    Mem = calc_size(Packet),
    Unit = {Cmd, Mem, IsZip},    
    x4(Tail, [Unit|SizeList]).

%% 统计每个包的长度
x5(<<>>, SizeList) ->
    SizeList;
x5(<<Len:16, Cmd:16, _IsZip:1, _Hex:7, _Body:Len/binary, Tail/binary>>, SizeList) ->
    x5(Tail, [Cmd|SizeList]).
        
z({Name, Mod, Fun}, {Arg1, Arg2, Arg3}) ->
    Before0 = statistics(runtime),
    Val = (catch Mod:Fun(Arg1, Arg2, Arg3)),
    After0 = statistics(runtime),
    {Before_c, _} = Before0,
    {After_c, _} = After0,
    Mem0 = erts_debug:flat_size(Val)*erlang:system_info(wordsize),
    Mem = lists:flatten(io_lib:format( "~.1f kB" , [Mem0 /1024])),
    ?MSG_ERROR(" ~30s: ~10.2f s ~12s",
            [Name,(After_c- Before_c) / 1000, Mem]),
    Val;
z({Name, Mod, Fun}, St) ->
    Before0 = statistics(runtime),
    Val = (catch Mod:Fun(St)),
    After0 = statistics(runtime),
    {Before_c, _} = Before0,
    {After_c, _} = After0,
    Mem0 = erts_debug:flat_size(Val)*erlang:system_info(wordsize),
    Mem = lists:flatten(io_lib:format( "~.1f kB" , [Mem0 /1024])),
    ?MSG_ERROR(" ~30s: ~10.2f s ~12s\n",
            [Name,(After_c- Before_c) / 1000, Mem]),
    Val.

d(_Sql) -> ok.
%%     spawn(fun() -> ?MSG_DEBUG("sql=~p", [Sql]) end).

s(Tip, {T10, T11, T12}, {T20, T21, T22}) ->
    T13 = T10 * 100000 * 100000 + T11 * 1000000 + T12,
    T23 = T20 * 100000 * 100000 + T21 * 1000000 + T22,
    Td = T23 - T13,
    spawn(fun() -> ?MSG_ERROR("~p:~p", [Tip, Td]) end).

%% size of packets, which send it in a time
s1(Pid, Packeted) ->
    Name = n(Pid),
    SizeList = x4(Packeted, []),
    MemP = calc_size(Packeted),
    F = fun({Cmd, Mem, 0}, Nth) ->
                ?MSG_DEBUG("~s[~p]\t|~p[~p]:~p B", [Name, Nth, Cmd, 'unziped', Mem]),
                Nth + 1;
           ({Cmd, Mem, 1}, Nth) ->
                ?MSG_DEBUG("~s[~p]\t|~p[~p]:~p B", [Name, Nth, Cmd, 'ziped', Mem]),
                Nth + 1
        end,
    lists:foldl(F, 1, SizeList),
    ?MSG_DEBUG("total:size=~p B--------------------------------------------", [MemP]).

%% 
calc_size(X) ->
    bit_size(X) / 8. %erts_debug:flat_size(X),

n(Pid) ->
    case erlang:process_info(Pid, registered_name) of
        [] ->
            erlang:pid_to_list(Pid);
        undefined ->
            erlang:pid_to_list(Pid);
        {_, Name} ->
            Name
    end.

sp(Packet) ->
    Now = misc:seconds(),
    case get(time) of
        ?undefined ->
            List = x5(Packet, []),
            put(time, {Now, 1, List});
        {Now, Times, List} ->
            List2 = x5(Packet, []),
            put(time, {Now, Times+1, [List|List2]});
        {Now2, Times, List} ->
            List2 = x5(Packet, []),
            put(time, {Now, 1, List2}),
            ?MSG_DEBUG("~p:~p packets:~w", [Now2, Times, List])
    end.

dump() ->
    spawn(fun() -> etop:start([{output, text}, {interval, 10}, {lines, 1}, {sort, reductions}]) end). 

dump2() ->
    Now = misc:seconds(),
    etop:config(sort, runtime), 
    etop:dump(io_lib:format("etop_runtime_~w", [Now])),
    etop:config(sort, memory), 
    etop:dump(io_lib:format("etop_memory_~w", [Now])),
    etop:config(sort, reductions), 
    etop:dump(io_lib:format("etop_reductions_~w", [Now])),
    etop:config(sort, msg_q),
    etop:dump(io_lib:format("etop_msg_q_~w", [Now])).

topN(N) ->
    X = [{M, P, erlang:process_info(P, [registered_name, initial_call, current_function, dictionary]), B}||{P, M, B}<-
        lists:sublist(lists:reverse(lists:keysort(2, processes_sorted_by_binary())), N)],
    ?MSG_DEBUG("~p", [X]),
    X.

processes_sorted_by_binary() ->
    [case erlang:process_info(P, binary) of
        {_, Bins} ->
            SortedBins = lists:usort(Bins),
            {_, Sizes, _} = lists:unzip3(SortedBins),
            {P, lists:sum(Sizes), []};
        _ ->
            {P, 0, []}
    end||P<- erlang:processes()
    ].