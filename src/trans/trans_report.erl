%%% 战报转换

-module(trans_report).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("record.data.hrl").
-include("record.player.hrl").

%% AMF3 wire types
-define(AMF3_UNDEF,     16#00). 
-define(AMF3_NULL,      16#01). 
-define(AMF3_FALSE,     16#00).
-define(AMF3_TRUE,      16#01).
%% AMF3 variable-length integers are 29-bit
-define(AMF3_INT_MIN,   -16#10000000). 
-define(AMF3_INT_MAX,    16#0fffffff).


%%
%% Exported Functions
%%
-export([trans_0303/0, trans_0303_2/0]).

%%
%% API Functions
%%

%% trans_report:trans_0303().
trans_0303() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`id`) from `game_copy_single_report`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `id`, `report` from `game_copy_single_report`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    0;
                {?ok, DataList} ->
                    Fun = fun([Id, ReportE], OldCount) ->
                                try
                                    ReportD = mysql_api:decode(ReportE),
                                    P  = handle_protocol(ReportD#ets_copy_single_report.bin_report, <<>>),
                                    ReportD2 = ReportD#ets_copy_single_report{bin_report = P},
                                    ReportE2 = mysql_api:encode(ReportD2),
                                    mysql_api:update(<<"update `game_copy_single_report` set `report` = ", ReportE2/binary,
                                                                     " where `id`=", (misc:to_binary(Id))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_ERROR("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end,
    ok.

%% trans_report:trans_0303_2().
trans_0303_2() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`id`) from `game_tower_report`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `id`, `report` from `game_tower_report`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    0;
                {?ok, DataList} ->
                    Fun = fun([Id, ReportE], OldCount) ->
                                try
                                    ReportD = mysql_api:decode(ReportE),
                                    P  = handle_protocol(ReportD#ets_tower_report.bin_report, <<>>),
                                    ReportD2 = ReportD#ets_tower_report{bin_report = P},
                                    ReportE2 = mysql_api:encode(ReportD2),
                                    mysql_api:update(<<"update `game_tower_report` set `report` = ", ReportE2/binary,
                                                                     " where `id`=", (misc:to_binary(Id))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_ERROR("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_tower_report` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_tower_report` count=0")
    end,
    ok.


%%
%% Local Functions
%%

handle_protocol(<<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary, Tail/binary>>, OldPacket) ->
    P = 
        try
            unpack(Len, Cmd, IsZip, Hex, Body)
        catch
            _:_ ->
                <<Len:16, Cmd:16, IsZip:1, Hex:7, Body:Len/binary>>
        end,
    P2 = encode(Cmd, misc:to_list(P)),
    handle_protocol(Tail, <<OldPacket/binary, P2/binary>>);
handle_protocol(_, P) ->
    P.

unpack(_CheckSum, MsgId, Zip, _Hex, BinaryZip) ->
    try
        Binary      = case Zip of
                          0  -> BinaryZip;
                          1   -> zlib:uncompress(BinaryZip)
                      end,
        decode(MsgId, Binary)
    catch
        Error:Reason ->
            ?MSG_SYS("~p|~p|~p~n~p", [MsgId, Error, Reason, erlang:get_stacktrace()]),
            <<>>
    end.

decode(MsgId, Binary) ->
    MsgFormat   = get_format(MsgId),
    decode_2(Binary, MsgFormat).

get_format(3012) ->
    {?uint32,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32,{?cycle,{?uint32,?uint8}},{?cycle,{?uint16}},?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32};
get_format(3100) ->
    {?uint32,?bool,?uint8,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16}},?uint16,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16}},?uint16};
get_format(3110) ->
    {?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16}},?uint16};
get_format(3140) ->
    {?uint8,?uint8,?uint8,?uint32,?uint32,?uint16};
get_format(3600) ->
    {?uint32,?uint8,{?cycle,{?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint8,?uint16,?uint8,?uint32,?uint8}}}}}}};
get_format(3610) ->
    {?uint8,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint8,?uint16,?uint8,?uint32,?uint8}}};
get_format(3620) ->
    {?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint16}}}},?uint8};
get_format(3652) ->
    {?uint8,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16}},?uint16,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}}}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16}},?uint16,{?cycle,{?uint8,{?cycle,{?uint32,?uint16}}}},{?cycle,{?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint8,?uint8,?uint8,?uint8}}}},{?cycle,{?uint8,{?cycle,{?uint16,?uint8,?uint8,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint8,?uint16,?uint8,?uint32,?uint8}}}}}}};
get_format(MsgId) ->
    battle_packet:packet_format(MsgId).

encode(3012, D) ->
    misc_packet:pack(3012, ?MSG_FORMAT_BATTLE_SC_OVER, D);
encode(3100, D) ->
    misc_packet:pack(3100, ?MSG_FORMAT_BATTLE_SC_START2, D);
encode(3110, D) ->
    misc_packet:pack(3110, ?MSG_FORMAT_BATTLE_UNITS_GROUP, D);
encode(3140, D) ->
    misc_packet:pack(3140, ?MSG_FORMAT_BATTLE_UNIT_MONSTER_GROUP, D);
encode(3600, D) ->
    misc_packet:pack(3600, ?MSG_FORMAT_BATTLE_SC_CMD_DATA, D);
encode(3610, D) ->
    misc_packet:pack(3610, ?MSG_FORMAT_BATTLE_GROUP_CMD_DATA, D);
encode(3620, D) ->
    misc_packet:pack(3620, ?MSG_FORMAT_BATTLE_SC_REFRESH_BOUT, D);
encode(3652, D) ->
    misc_packet:pack(3652, ?MSG_FORMAT_BATTLE_SC_REPORT_DATA, D);
encode(X, _) ->
%%     ?MSG_SYS("~p", [X]),
    <<>>.

%%
decode_2(Binary, Tuple) ->
    case decode_val(Binary, Tuple) of
        {Data, <<>>} -> Data;
        {Data, Binary} ->
            ?MSG_SYS("Data:~p Binary:~p~n", [Data, Binary]),
            Data
    end.

decode_val(<<?AMF3_TRUE, BinaryRest/binary>>, ?bool) ->
    {?true, BinaryRest};
decode_val(<<?AMF3_FALSE, BinaryRest/binary>>, ?bool) ->
    {?false, BinaryRest};
decode_val(<<?AMF3_NULL, BinaryRest/binary>>, ?null) ->
    {?null, BinaryRest};
decode_val(<<?AMF3_UNDEF, BinaryRest/binary>>, ?undefined) ->
    {?undefined, BinaryRest};
decode_val(<<Val:8/big-integer-unsigned,BinaryRest/binary>>, ?uint8) ->
    {Val, BinaryRest};
decode_val(<<Val:16/big-integer-unsigned,BinaryRest/binary>>, ?uint16) ->
    {Val, BinaryRest};
decode_val(<<Val:32/big-integer-unsigned,BinaryRest/binary>>, ?uint32) ->
    {Val, BinaryRest};
decode_val(<<Len:16/big-integer-unsigned, Val:Len/binary, BinaryRest/binary>>, ?string) ->
    {Val, BinaryRest};
decode_val(Binary, {?cycle, CycleBody}) when is_tuple(CycleBody) ->
    decode_cycle(Binary, ?uint16, CycleBody);
decode_val(Binary, Tuple) when is_tuple(Tuple) ->
    decode_tuple(Binary, Tuple).

decode_tuple(Binary, Tuple) ->
    Size   = tuple_size(Tuple),
    Datas  = erlang:make_tuple(Size, 0),
    decode_tuple(1, Size, Datas, Tuple, Binary).
decode_tuple(Idx, Size, Datas, Tuple, Binary) when Idx =< Size->
    {Val, BinaryRest} = decode_val(Binary, element(Idx, Tuple)),
    Datas2 = setelement(Idx, Datas, Val),
    decode_tuple(Idx + 1, Size, Datas2, Tuple, BinaryRest);
decode_tuple(_Idx, _Size, Data, _Tuple, Binary) -> {Data, Binary}.

decode_cycle(Binary, CountType, CycleBody) ->
    {Count, BinaryRest}     = decode_val(Binary, CountType),
    {Datas, BinaryRest2}    = decode_cycle(BinaryRest, [], 1, Count, CycleBody),
    {Datas, BinaryRest2}.

decode_cycle(Binary, Datas, Idx, Count, CycleBody) when Idx =< Count ->
    {Val, BinaryRest} = decode_val(Binary, CycleBody),
    decode_cycle(BinaryRest, [Val|Datas], Idx + 1, Count, CycleBody);
decode_cycle(Binary, Datas, _Idx, _Count, _CycleBody) ->
    {lists:reverse(Datas), Binary}.


    


