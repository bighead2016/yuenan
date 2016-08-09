%% Author: cobain
%% Created: 2012-8-6
%% Description: TODO: Add description to goods_drop_api
-module(goods_drop_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([goods_drop/1 ,yunyingGood/2]).

%%
%% API Functions
%%
%% goods_drop_api:goods_drop(1).
goods_drop(DropId) ->
	goods_drop(DropId, 5).
%% 计算活动物品
funCheck([],Acc,_Time) ->
    Acc;
funCheck([{A_id,Good}|Tail] ,Acc,Time) ->
	{Begin,End} = data_welfare:get_deposit_active_time(A_id),
	if Time =< End andalso Time >= Begin ->
		   {Good2, _Sum} = transForm(Good, [], 0) ,
		   case misc_random:odds_one({Good2,?CONST_SYS_NUMBER_TEN_THOUSAND}) of
			   ?null ->  funCheck(Tail,Acc,Time);
			   Good3 ->
				   funCheck(Tail,Good3++Acc,Time)
		   end ;
	   ?true -> 
		   funCheck(Tail,Acc,Time)
	end.
funF2([],Acc) -> Acc;
funF2([{X,Y,Z,H}|Tail],Acc) ->
	case random:uniform(?CONST_SYS_NUMBER_TEN_THOUSAND)  of
		R when R < H ->  
			case goods_api:make(X,Y,Z) of
				GoodsList3 when is_list(GoodsList3) -> 
					funF2(Tail,GoodsList3++Acc);
				_ ->
					funF2(Tail,Acc)
			end;
		_ ->funF2(Tail,Acc)
	end
.
yunyingGood(A_data,Now) ->
    ActivityGoods = funCheck(A_data,[],Now),
%% 	?MSG_DEBUG(" ActivityGoods2222222~p~n",[ActivityGoods]),
	funF2(ActivityGoods,[]).

transForm([],Acc,Sum) ->
    {lists:reverse(Acc),Sum};
transForm([{G,H}|Gtail],Acc,Sum) ->
    transForm(Gtail,[{G,H+Sum}|Acc],H+Sum).
    
goods_drop(DropId, Count) when Count > 0 ->
	case data_goods:get_goods_drop(DropId) of
		?null -> [];
		#rec_goods_drop{data = GoodsDropData, type = Type, times = Times, activity_data = A_data} ->
            Now = misc:seconds(),
            ActivityGoods = yunyingGood(A_data,Now), %%检查运营掉落物品
             io:format("ActivityGoods:~p~n",[ActivityGoods]),
			case misc_random:odds_one(GoodsDropData) of
				?null -> [];
				GoodsData ->
					case goods_drop_ext(GoodsData, [], Type, Times) of
						{?error, ?TIP_GOODS_FORBID_DROP} ->
							goods_drop(DropId, Count - 1);
						GoodsList ->
                            GoodsList++ActivityGoods
					end
			end
	end;
goods_drop(_DropId, _Count) -> [].

goods_drop_2(DropId, Count, Acc) when Count > 0 ->
    Acc2 = 
        case goods_drop(DropId) of
            {?error, ?TIP_GOODS_FORBID_DROP} ->
                Acc;
            GoodsList -> GoodsList++Acc
        end,
    goods_drop_2(DropId, Count-1, Acc2);
goods_drop_2(_DropId, _Count, Acc) -> Acc.

goods_drop_ext(_, {?error, ?TIP_GOODS_FORBID_DROP}, _, _) -> {?error, ?TIP_GOODS_FORBID_DROP};
goods_drop_ext([{{GoodsId, IsBind, Count}, Odds}|GoodsData], Acc, ?CONST_GOODS_DROP_TYPE_NORMAL = Type, Times) ->
	Acc2	=
		case misc_random:odds(Odds, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
			?true ->
				case goods_api:make(GoodsId, IsBind, Count) of
					GoodsList when is_list(GoodsList) -> GoodsList ++ Acc;
					{?error, ?TIP_GOODS_FORBID_DROP} -> {?error, ?TIP_GOODS_FORBID_DROP};
					{?error, _ErrorCode} -> Acc
				end;
			?false -> Acc
		end,
	goods_drop_ext(GoodsData, Acc2, Type, Times);
goods_drop_ext([{{DropId, _, _}, Odds}|GoodsData], Acc, ?CONST_GOODS_DROP_TYPE_MULTI = Type, Times) ->
    Acc2    =
        case misc_random:odds(Odds, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
            ?true ->
                goods_drop_2(DropId, Times, Acc);
            ?false -> Acc
        end,
    goods_drop_ext(GoodsData, Acc2, Type, Times);
goods_drop_ext([], Acc, _, _) ->
	Acc.
%%
%% Local Functions
%%

