%% Author: zero
%% Created: 2012-8-17
%% Description: TODO: Add description to npc_api
-module(npc_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([npc/3]).

%%
%% API Functions
%%
npc(Player, _NpcId, _Func) ->
	{?ok, Player}.

%% %% NPC功能--仓库 
%% do_npc(Player, _NpcId, ?CONST_MAP_NPC_FUNC_DEPOT, _Arg1, _Arg2) ->
%%     {?ok, Player};
%% %% NPC功能--商店 
%% do_npc(Player, _NpcId, ?CONST_MAP_NPC_FUNC_SHOP, _Arg1, _Arg2) ->
%%     Packet = shop_api:list_repurchase(Player#player.shop_temp_list),
%%     misc_packet:send(Player#player.user_id, Packet),
%%     {?ok, Player};
%% %% NPC功能--活动 
%% do_npc(Player, _NpcId, ?CONST_MAP_NPC_FUNC_ACTIVITY, _Arg1, _Arg2) ->
%%     {?ok, Player};
%% %% NPC功能--酒馆 
%% do_npc(Player, _NpcId, ?CONST_MAP_NPC_FUNC_PUB, _Arg1, _Arg2) ->
%%     {?ok, Player};
%% %% NPC功能--任务 
%% do_npc(Player, _NpcId, ?CONST_MAP_NPC_FUNC_TASK, _Arg1, _Arg2) ->
%%     {?ok, Player};
%% %% NPC功能--新手指导员 
%% do_npc(Player, _NpcId, ?CONST_MAP_NPC_FUNC_GUIDE, _Arg1, _Arg2) ->
%%     {?ok, Player};
%% %% NPC功能--采集
%% do_npc(Player, _NpcId, ?CONST_MAP_NPC_FUNC_COLLECT, GoodsId, _Arg2) ->
%%     GoodsList = goods_api:make(GoodsId, ?CONST_GOODS_BIND, 1),
%%     case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_COLLECT_GET, 1, 1, 0, 0, 1, 1, []) of
%%         {?ok, NewPlayer, _, _Packet} ->
%%             {?ok, NewPlayer};
%%         {?error, ErrorCode} ->
%%             {?error, ErrorCode}
%%     end;
%% do_npc(Player, _, _, _, _) ->
%%     {?ok, Player}.


%%
%% Local Functions
%%

