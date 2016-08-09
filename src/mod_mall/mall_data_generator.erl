%% Author: Administrator
%% Created: 2012-8-1
%% Description: TODO: Add description to mall_data_generator
-module(mall_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions

%% mall_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_mall(get_mall, Ver),
	FunDatas2 = generate_discount_list(get_discount_list, Ver),
	FunDatas3 = generate_mall_sale(get_mall_sale, Ver),
	FunDatas4 = generate_mall_ride(get_mall_ride, Ver),
	misc_app:write_erl_file(data_mall,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1,FunDatas2,FunDatas3,FunDatas4], Ver).

%% generate_mall(FunName)
generate_mall(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mall/mall.yrl"),
	generate_mall(FunName, Datas, []).
generate_mall(FunName, [Data|Datas], Acc) when is_record(Data, rec_mall) ->
	Key		= {Data#rec_mall.type, Data#rec_mall.goods_id},
	Value	= Data,
	When	= ?null,
	generate_mall(FunName, Datas, [{Key, Value, When}|Acc]);
generate_mall(FunName, [], Acc) -> {FunName, Acc}.

%% generate_discount_list(FunName)
generate_discount_list(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mall/mall.yrl"),
	generate_discount_list(FunName, Datas, []).

generate_discount_list(FunName, [Data|Datas], Acc) when is_record(Data, rec_mall) ->
	case Data#rec_mall.type of
		?CONST_MALL_DISCOUNT ->
			Value	= {		   								
					   Data,			   			
					   Data#rec_mall.odds
					  },
			generate_discount_list(FunName, Datas, [Value|Acc]);
		_ ->
			generate_discount_list(FunName, Datas, Acc)
	end;
generate_discount_list(FunName, [], Acc) -> 
	Key		= ?CONST_MALL_DISCOUNT,
	Value	= misc_random:odds_list_init(?MODULE, ?LINE, Acc, ?CONST_SYS_NUMBER_TEN_THOUSAND),
	When	= ?null,
	{FunName, [{Key, Value, When}]}.

generate_mall_sale(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mall/mall_sale.yrl"),
	generate_mall_sale(FunName, Datas, []).
generate_mall_sale(FunName, [Data|Datas], Acc) when is_record(Data, rec_mall_sale) ->
	Key		= Data#rec_mall_sale.id,
	StartTime 	= Data#rec_mall_sale.start_time,
	EndTime 	= Data#rec_mall_sale.end_time,
	Value	= Data#rec_mall_sale{
								 start_time = misc:date_time_to_stamp(StartTime),
								 end_time	= misc:date_time_to_stamp(EndTime)
								 },
	When	= ?null,
	generate_mall_sale(FunName, Datas, [{Key, Value, When}|Acc]);
generate_mall_sale(FunName, [], Acc) -> {FunName, Acc}.

generate_mall_ride(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mall/mall_ride.yrl"),
	generate_mall_ride(FunName, Datas, []).
generate_mall_ride(FunName, [Data|Datas], Acc) when is_record(Data, rec_mall_ride) ->
	Key		= Data#rec_mall_ride.id, 
	Value	= Data,
	When	= ?null,
	generate_mall_ride(FunName, Datas, [{Key, Value, When}|Acc]);
generate_mall_ride(FunName, [], Acc) -> {FunName, Acc}.


%%
%% Local Functions
%%

