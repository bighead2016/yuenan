%% Author: Administrator
%% Created: 2012-9-14
%% Description: TODO: Add description to convoy_data_generator
-module(commerce_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([generate/1, buff/3, factor/0]).

%%
%% API Functions
%%
%% commerce_data_generator:generate().
generate(Ver) ->
	FunDatas1	= generate_caravan_info(get_caravan_info, Ver),
	FunDatas2	= generate_commerce_cost(get_commerce_cost, Ver),
	FunDatas6	= generate_commmerce_base(get_commerce_base, Ver),
	misc_app:write_erl_file(data_commerce,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas6], Ver).

%%
%% Local Functions
%%
%% commerce_data_generator:generate_caravan_info(get_caravan_info).
generate_caravan_info(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/commerce/caravan.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_caravan_info(FunName, Datas2, []).
generate_caravan_info(FunName, [Data|Datas], Acc) when is_record(Data, rec_caravan) ->
	Key			= Data#rec_caravan.quality,
	Probability	= misc_random:odds_list_init(?MODULE, ?LINE, Data#rec_caravan.refresh, 10000),
	Duration	= Data#rec_caravan.duration * 60,
	Value		= Data#rec_caravan{refresh	= Probability,
								   duration	= Duration},
	When		= ?null,
	generate_caravan_info(FunName, Datas, [{Key, Value, When}|Acc]);
generate_caravan_info(FunName, [], Acc) -> {FunName, Acc}.

%% commerce_data_generator:generate_commerce_cost(get_commerce_cost).
generate_commerce_cost(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/commerce/commerce.cost.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_commerce_cost(FunName, Datas2, []).
generate_commerce_cost(FunName, [Data|Datas], Acc) when is_record(Data, rec_commerce_cost) ->
	Key		= Data#rec_commerce_cost.category,
	Duration	= Data#rec_commerce_cost.duration * 60,
	Value	= Data#rec_commerce_cost{duration = Duration},
	When	= ?null,
	generate_commerce_cost(FunName, Datas, [{Key, Value, When}|Acc]);
generate_commerce_cost(FunName, [], Acc) -> {FunName, Acc}.

generate_commmerce_base(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/commerce/commerce.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_commmerce_base(FunName, Datas2, []).
generate_commmerce_base(FunName, [Data|Datas], Acc) when is_record(Data, rec_commerce) ->
	Key		= Data#rec_commerce.lv,
	Value	= Data,
	When	= ?null,
	generate_commmerce_base(FunName, Datas, [{Key, Value, When}|Acc]);
generate_commmerce_base(FunName, [], Acc) ->{FunName, Acc}.

%% 
buff([MarketHead | MarketTail], GuildList, Acc) when is_list(GuildList) ->
	NewAcc	= buff(MarketHead, GuildList, []),
%% 	?MSG_DEBUG("~nMarketHead=~p~nMarketTail=~p~nGuildList=~p~nNewAcc=~p~nAcc=~p~n", [MarketHead, MarketTail, GuildList, NewAcc, Acc]),
	buff(MarketTail, GuildList, Acc ++ NewAcc);
buff(MarketList, [GuildHead | GuildTail], Acc) when is_list(MarketList) ->
	NewAcc	= buff(MarketList, GuildHead, []),
%% 	?MSG_DEBUG("~nMarketList=~p~nGuildHead=~p~nGuildTail=~p~nNewAcc=~p~nAcc=~p~n", [MarketList, GuildHead, GuildTail, NewAcc, Acc]),
	buff(MarketList, GuildTail, Acc ++ NewAcc);
buff([], GuildList, Acc) when is_list(GuildList) ->
%% 	?MSG_DEBUG("~nGuildList=~p~nAcc=~p~n", [GuildList, Acc]),
	lists:usort(Acc);
buff(MarketList, [], Acc) when is_list(MarketList) ->
%% 	?MSG_DEBUG("~nMarketList=~p~nAcc=~p~n", [MarketList, Acc]),
	lists:usort(Acc);
buff([], [], Acc) ->
	lists:usort(Acc);
buff(MarketValue, [GuildHead | GuildTail], Acc) when is_integer(MarketValue) ->
	buff(MarketValue, GuildTail, Acc ++ [MarketValue * GuildHead]);
buff(MarketValue, [], Acc) when is_integer(MarketValue) ->
	Acc;
buff([MarketHead | MarketTail], GuildValue, Acc) when is_integer(GuildValue) ->
	buff(MarketTail, GuildValue, Acc ++ [MarketHead * GuildValue]);
buff([], GuildValue, Acc) when is_integer(GuildValue) ->
	Acc.

factor() ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ "/commerce/caravan.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	factor(Datas2, []).
factor([Data | Datas], Acc) when is_record(Data, rec_caravan) ->
	factor(Datas, [Data#rec_caravan.factor | Acc]);
factor([], Acc) ->
	Acc.