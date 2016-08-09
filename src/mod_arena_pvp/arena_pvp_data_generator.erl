%% Author: Administrator
%% Created: 2012-12-22
%% Description: TODO: Add description to arena_pvp_data_generator
-module(arena_pvp_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([make_cross_list/1]).

%%
%% API Functions
%%

%% arena_pvp_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_odds(get_odds, Ver),
	FunDatas2 = {get_reward, "arena_pvp", "arena_pvp_reward.yrl", [#rec_arena_pvp_reward.rank], ?MODULE, ?null, ?null}, % 竞技场-排名奖励
	FunDatas3 = {get_shop, "arena_pvp", "arena_pvp_shop.yrl", [#rec_arena_pvp_shop.id], ?MODULE, ?null, ?null}, % 竞技场-兑换商店
	FunDatas4 = {get_score, "arena_pvp", "arena_pvp_score.yrl", [#rec_arena_pvp_score.times], ?MODULE, ?null, ?null}, % 竞技场-胜利积分
	FunDatas5 = {get_card, "arena_pvp", "arena_pvp_card.yrl", [#rec_arena_pvp_card.lv], ?MODULE, ?null, ?null}, % 竞技场-胜利卡牌奖励
    FunDatas6 = {get_cross, "arena_pvp", "arena_pvp_cross.yrl", [#rec_arena_pvp_cross.server_index], ?MODULE, ?null, ?null}, % 竞技场-排名奖励
    FunDatas7 = {get_cross_list, "arena_pvp", "arena_pvp_cross.yrl", ?null, ?MODULE, make_cross_list, ?null},
	misc_app:make_gener(data_arena_pvp,						
							[],
							[
                             FunDatas1, FunDatas2, FunDatas3, FunDatas4,
                             FunDatas5, FunDatas6, FunDatas7
							], Ver).

%竞技场-匹配几率
generate_odds(FunName, Ver) ->
	MapDatas 	= misc_app:get_data_list_rev(?DIR_YRL_ROOT ++ Ver ++ "/arena_pvp/arena_pvp_odds.yrl"),
	Key		= ?null,
	
	When	= ?null,
	F			= fun(Data,List) when is_record(Data, rec_arena_pvp_odds) ->
						  [{
							{Data#rec_arena_pvp_odds.minus_lv, 
							Data#rec_arena_pvp_odds.add_lv},
							Data#rec_arena_pvp_odds.odds
							}|List]
				  end,
	List2	= lists:foldl(F, [], MapDatas),					  
	Value	= misc_random:odds_list_init(?MODULE, ?LINE, List2, ?CONST_SYS_NUMBER_TEN_THOUSAND),
	{FunName,[{Key, Value, When}]}.

%%
make_cross_list(List) ->
    make_cross_list(List, []).
    
make_cross_list([#rec_arena_pvp_cross{camp_index = CampIdx, server_index = Sid}|Tail], OldList) ->
    L = 
        case lists:keytake(CampIdx, 1, OldList) of
            {value, {_, X}, OldList2} ->
                [{CampIdx, [Sid|X]}|OldList2];
            _ ->
                [{CampIdx, [Sid]}|OldList]
        end,
    make_cross_list(Tail, L);
make_cross_list([], L) ->
    L.
