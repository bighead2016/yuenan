%% Author: cobain
%% Created: 2012-7-6
%% Description: TODO: Add description to misc_packet
-module(misc_packet).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
%% AMF3 wire types
-define(AMF3_UNDEF,     16#00). 
-define(AMF3_NULL,      16#01). 
-define(AMF3_FALSE,     16#00).
-define(AMF3_TRUE,      16#01).
%% AMF3 variable-length integers are 29-bit
-define(AMF3_INT_MIN, 	-16#10000000). 
-define(AMF3_INT_MAX,  	 16#0fffffff).

%%
%% Exported Functions
%%
-export([send/2, pack/2, pack/3, unpack/5, unpack/6, send_tips/2]).
-export([encode/2, decode/2, send_cross/2]).
%%
%% API Functions
%%

send_cross(UserId, Packet) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            send(UserId, Packet);
        [CrossUser] ->
            Node = CrossUser#cross_in.node,
            rpc:call(Node, ?MODULE, send, [UserId, Packet])
    end.

%% 发送提示信息
send_tips(UserId, TipsCode) ->
    PacketTips   = message_api:msg_notice(TipsCode),
    send(UserId, PacketTips).

send(_Id, <<>>) -> ?true;
send(UserId, Packet) when is_number(UserId) andalso is_binary(Packet) ->
    Name = misc_app:net_name(UserId),
    case misc:where_is({local, Name}) of
    	
        Pid when is_pid(Pid) ->
            send(Pid, Packet);
        ?undefined ->
%%             ?MSG_ERROR("UserId=~p, Name:~p Packet:~p", [UserId, Name, Packet]),
			?ok
    end;

send(Pid, Packet) when is_pid(Pid) ->
%%     ?MSG_DEBUG("[~p]send>>~p", [is_process_alive(Pid), Packet]),
%%    ?ANALYSIS(x2, Pid, Packet),
	misc:send_to_pid(Pid, {send, Packet});
send(Id, Packet) ->
    ?MSG_ERROR("Id:~p Packet:~p", [Id, Packet]).

pack(MsgId, Format, Datas) ->
%%     ?MSG_ERROR("~p~n~p~n~p", [MsgId, Format, Datas]),
	BinData    = encode(Format, Datas),
	pack(MsgId, BinData).

pack(MsgId, BinData) ->
	Length 			= byte_size(BinData),
	{Zip, Binary}	= if
						  Length >= 512 -> {?CONST_SYS_TRUE, zlib:compress(BinData)};
						  ?true -> {?CONST_SYS_FALSE, BinData}
					  end,
	LengthZip		= byte_size(Binary),
	<<LengthZip:16/big-integer-unsigned,
	  MsgId:16/big-integer-unsigned,
	  Zip:1/big-integer-unsigned,
	  (MsgId + Length):7/big-integer-unsigned,
	  Binary/binary>>.

unpack(CheckSum, MsgId, Zip, Hex, BinaryZip) ->
	try
		Binary		= case Zip of
                          ?CONST_SYS_FALSE  -> BinaryZip;
						  ?CONST_SYS_TRUE   -> zlib:uncompress(BinaryZip)
					  end,
%% 		?MSG_PRINT("~nMsgId:~p CheckSum = ~p~n((Hex + MsgId + byte_size(Binary) + 19) rem 256) = ~p~n",
%% 				   [MsgId, CheckSum, ((Hex + MsgId + byte_size(Binary) + 19) rem 256)]),
		CheckSum 	= ((Hex + MsgId + byte_size(Binary) + 19) rem 256),
		{
		 ModPacket,
		 ModHandler
		}		    = gateway_dispatcher:dispatch(MsgId),
		MsgFormat   = ModPacket:packet_format(MsgId),
		Datas		= decode(Binary, MsgFormat),
		{?ok, ModHandler, MsgId, Datas}
	catch
		_Error:Reason ->
			?MSG_ERROR("BAD PACKET === MsgId:~p Binary:~p", [MsgId, BinaryZip]),
			?MSG_ERROR("Error:Reason ~p:~p",[Reason,erlang:get_stacktrace()]),
			{error, ?TIP_COMMON_PACKET_ERROR}
	end.

unpack(AppKey, AccSN, SN, Sing, MsgId, Binary) ->
	try
		{?ok, AccSN2}	= check_packet_sn(AccSN, SN),
		?ok 			= check_packet_sing(Sing, AppKey, Binary),
		{
		 ModPacket, ModHandler
		}		    	= gateway_dispatcher:dispatch(MsgId),
		MsgFormat   	= ModPacket:packet_format(MsgId),
		Datas			= decode(Binary, MsgFormat),
		{?ok, AccSN2, ModHandler, MsgId, Datas}
	catch
		throw:Return -> Return;
		_Error:Reason ->
			?MSG_ERROR("BAD PACKET === MsgId:~p Binary:~p", [MsgId, Binary]),
			?MSG_ERROR("Error:Reason ~p:~p", [Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_PACKET_ERROR}
	end.

check_packet_sn(SN, SN) -> {?ok, generate_packet_sn(SN)};
check_packet_sn(AccSN, SN) ->
	?MSG_ERROR("BAD PACKET SN === AccSN:~p SN:~p", [AccSN, SN]),
	throw({?error, check_packet_sn}).

check_packet_sing(_Sing, 0, _Body) -> ?ok;
check_packet_sing(Sing, AppKey, Body) ->
	case erlang:md5(misc:to_list(Body) ++ AppKey) of
		<<Sing:8/binary,_/binary>> -> ?ok;
		Sing2 ->
			?MSG_ERROR("~nBAD PACKET === Sing:~p Sing2:~p AppKey:~p Body:~p~n", [Sing, Sing2, AppKey, Body]),
			throw({?error, check_packet_sing})
	end.

generate_packet_sn(250) -> 1;
generate_packet_sn(SN) -> SN + 1.
	
%%
%% Local Functions
%%

%% 例子：misc_packet:encode({uint8, uint16, string, uint8}, [1,2,<<"aaa">>, 1]).
%% Result：<<1,0,2,0,3,97,97,97,1>>
%% 例子：misc_packet:encode({uint8, uint8, uint16, uint8, uint16}, {1,2,4,1,6}).
%% Result：<<1,2,0,4,1,0,6>>
%% 例子：misc_packet:encode({uint32, {uint8, uint16}}, [{2,5},{2,6}]).
%% Result：<<0,0,0,2,2,0,5,2,0,6>>
%% 例子：misc_packet:encode({uint32, {uint8, uint8, uint16}}, [{1,{1,{1,1,1},4},{1,{1,1,1},5},{1,{1,{1,1,1},6}]).
%% Result：<<0,0,0,3,1,2,0,4,1,2,0,5,1,2,0,6>>
%% 例子：misc_packet:encode({uint8, uint8, uint16, {uint8, {uint8, uint8, uint16}}, string}, [1,2,3,[{1,2,4},{1,2,5},{1,2,6}],<<"aaaaaaaa">>]).
%% Result：<<1,2,0,3,3,1,2,0,4,1,2,0,5,1,2,0,6,0,8,97,97,97,97,97,97,97,97>>

encode(Format, Datas) ->
    encode_val(Format, Datas, <<>>).

encode_val(?bool, ?true, Binary) ->
	<<?AMF3_TRUE, Binary/binary>>;
encode_val(?bool, ?false, Binary) ->
	<<?AMF3_FALSE, Binary/binary>>;
encode_val(?bool, ?CONST_SYS_TRUE, Binary) ->
	<<?AMF3_TRUE, Binary/binary>>;
encode_val(?bool, ?CONST_SYS_FALSE, Binary) ->
	<<?AMF3_FALSE, Binary/binary>>;
encode_val(?null, ?null, Binary) ->
	<<?AMF3_NULL, Binary/binary>>;
encode_val(?undefined, ?undefined, Binary) ->
	<<?AMF3_UNDEF, Binary/binary>>;
encode_val(?uint8, Val, Binary) ->
	<<Val:8/big-integer-unsigned, Binary/binary>>;
encode_val(?uint16,	Val, Binary) ->
	<<Val:16/big-integer-unsigned, Binary/binary>>;
encode_val(?uint32,	Val, Binary) ->
	<<Val:32/big-integer-unsigned, Binary/binary>>;
encode_val(?string, Val, Binary) when is_binary(Val) -> % FIXME 当字串为非binary时，传入有问题。
	Len = byte_size(Val),
	<<Len:16/big-integer-unsigned, Val:Len/binary, Binary/binary>>;
encode_val(?string, Val, Binary) -> % FIXME 当字串为非binary时，传入有问题。现在加这个暂时补救
	Bin = 
	try list_to_binary(Val)
	catch _:_ ->
		unicode:characters_to_binary(Val)
	end,
	Len = byte_size(Bin),
	<<Len:16/big-integer-unsigned, Bin:Len/binary, Binary/binary>>;

encode_val({?cycle, BodyFormat}, List, Binary)
  when is_tuple(BodyFormat) ->
%%     encode_cycle(?uint16, BodyFormat, List, Binary);
    encode_cycle(?uint16, BodyFormat, List, Binary);
encode_val(Format, Tuple, Binary)
  when is_tuple(Format) andalso is_tuple(Tuple) ->
    encode_tuple(Format, Tuple, Binary);
encode_val(Format, List, Binary)
  when is_tuple(Format) andalso is_list(List) ->
    encode_list(Format, lists:reverse(List), Binary).


encode_cycle(CountFormat, BodyFormat, List, Binary) ->
    Binary2 = encode_cycle_body(BodyFormat, lists:reverse(List), Binary),
    encode_val(CountFormat, length(List), Binary2).
encode_cycle_body(BodyFormat, [Tuple|List], Binary) when is_tuple(Tuple) ->
    Binary2 = encode_val(BodyFormat, Tuple, Binary),
    encode_cycle_body(BodyFormat, List, Binary2);
encode_cycle_body(_BodyFormat, [], Binary) ->
    Binary.
    
encode_list(Format, List, Binary) ->
%% 	?MSG_DEBUG("~nFormat:~p~nList:~p~n", [Format, List]),
%% 	?MSG_DEBUG("~nFormat:~p~nList:~p~n", [tuple_size(Format), length(List)]),
    Size = tuple_size(Format),
    encode_list(Size, Size, Format, List, Binary).

encode_list(_Counter, _Size, _Format, [], Binary) -> Binary;
encode_list(Counter, Size, Format, [Val|List], Binary) when Counter > 0 ->
    Type    = element(Counter, Format),
    Binary2 = encode_val(Type, Val, Binary),
    encode_list(Counter - 1, Size, Format, List, Binary2);
encode_list(_Counter, Size, Format, List, Binary) ->
    encode_list(Size, Size, Format, List, Binary).

encode_tuple(Format, Tuple, Binary) ->
    Size = tuple_size(Format),
    encode_tuple(Size, Size, Format, Tuple, Binary).
encode_tuple(Counter, Size, Format, Tuple, Binary) when Counter > 0 ->
    Type    = element(Counter, Format),
    Val     = element(Counter, Tuple),
    Binary2 = encode_val(Type, Val, Binary),
    encode_tuple(Counter - 1, Size, Format, Tuple, Binary2);
encode_tuple(_Counter, _Size, _Format, _Tuple, Binary) ->
    Binary.


%% 读取数据

%% 例子：misc_packet:decode(<<0,0,3,233,0,1,0,0,0,11,0,0,48,57,1,2,0,0,0,100,0,5,104,97,112,112,121,1>>, {uint32,uint16,uint32,uint32,uint8,uint8,uint32,string,bool}).
%% 返回：{1001,1,11,12345,1,2,100,<<"happy">>,true}
%% 例子：misc_packet:decode(<<0,0,0,3,2,0,4,1,0,4,2,0,4,1,0,5,2,0,4,1,0,6>>, {uint32, {uint8, uint16, uint8, uint16}}).
%% 返回：{3,[{2,4,1,4},{2,4,1,5},{2,4,1,6}]}
%% 例子：misc_packet:decode(<<0,0,0,1,2,0,4,1,0,4,2,0,6>>, {uint32, {uint8, {uint16, uint8}}, uint16}).
%% 返回：{1,{2,[{4,1},{4,2}]},6}
decode(Binary, Tuple) ->
    case decode_val(Binary, Tuple) of
        {Data, <<>>} -> Data;
        {Data, Binary} ->
            ?MSG_ERROR("Data:~p Binary:~p~n", [Data, Binary]),
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
	{Count, BinaryRest}		= decode_val(Binary, CountType),
	{Datas, BinaryRest2}	= decode_cycle(BinaryRest, [], 1, Count, CycleBody),
	{{Count, Datas}, BinaryRest2}.

decode_cycle(Binary, Datas, Idx, Count, CycleBody) when Idx =< Count ->
    {Val, BinaryRest} = decode_val(Binary, CycleBody),
    decode_cycle(BinaryRest, [Val|Datas], Idx + 1, Count, CycleBody);
decode_cycle(Binary, Datas, _Idx, _Count, _CycleBody) ->
    {lists:reverse(Datas), Binary}.







