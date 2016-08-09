%%% 放弃立即打包机制
%%% 转成最后才进行打包
%%% [Protocol, args]
-module(misc_packet_2).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").

-define(MAX_PROTOCOL, 99999).

%%
%% Exported Functions
%%
-export([pack/1, generate_dispatch/0]).

%%
%% API Functions
%%
 
pack([]) -> ?ok;
pack(MsgList) ->
    pack(MsgList, <<>>).
    
pack([MsgId, ArgList|Tail], BinData) ->
    MsgFormat = 
        case gateway_dispatcher:dispatch(MsgId) of
            {?error, _MsgId} ->
                <<>>;
            {Mod, _Handler} ->
                packet_formatter:p(Mod, MsgId)
        end,
    BinData2  = misc_packet:pack(MsgId, MsgFormat, ArgList),
    BinData3  = <<BinData/binary, BinData2/binary>>,
    pack(Tail, BinData3);
pack([], BinData) -> BinData.

generate_dispatch() ->
    generate_dispatch(1, []).
generate_dispatch(MsgId, ModList) when MsgId < ?MAX_PROTOCOL ->
    ModList2 = 
        case gateway_dispatcher:dispatch(MsgId) of
            {?error, _MsgId} ->
                ModList;
            {Mod, _Handler} ->
                case lists:member(Mod, ModList) of
                    ?true ->
                        ModList;
                    ?false ->
                        [Mod|ModList]
                end
        end,
    generate_dispatch(MsgId+1, ModList2);
generate_dispatch(?MAX_PROTOCOL, ModList) ->
    gen_packet_formatter(ModList).

gen_packet_formatter(ModList) ->
    Head = "-module(packet_formatter). ",
    Export = "-export([p/2]). ",
    Body = gen_packet_body(ModList, ""),
    Tail = "p(_, _) -> err. ",
    Module = lists:append([Head, Export, Body, Tail]),
    {Mod,Code} = dynamic_compile:from_string(Module),
    code:load_binary(Mod, "packet_formatter.erl", Code).

gen_packet_body([Mod|Tail], Body) -> 
    ModL  = erlang:atom_to_list(Mod),
    Body2 = lists:append(["p(", ModL, ", X) -> ", ModL, ":packet_format(X); "]),
    Body3 = lists:append([Body, Body2]),
    gen_packet_body(Tail, Body3);
gen_packet_body([], Body) ->
    Body.
    

%% 去重合并
%% 1.同协议号的处理
%% remove_



