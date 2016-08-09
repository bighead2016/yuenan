%% @author liuyujian
%% @doc @todo Add description to archery_api.


-module(archery_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([send_reward/0,save_archery/1,flush_offline_2/2,flush_offline/2]).
-export([clear_acc/1]).
-export([get_history_reword/1]).

%% 领取之前的累积奖励,上线的时候和0时在线的时候
get_history_reword(Player)->
	catch archery_mod:get_archery_ets(Player),
	Player.
%% 把没有领取的累积奖励领了
clear_acc(Player)->
	Arch = archery_mod:get_archery_ets(Player),
	archery_mod:retArrow(Player#player.user_id,  Arch#ets_archery_info.arrow, ?CONST_ARCHERY_LIMIT_BUY).
%% 0点发送前10奖励, 并发放奖励(先不放出这个功能)
send_reward()->
	archery_reward_server:clear_list(),
	?ok;
send_reward()->
	try
		case archery_mod:get_top_list() of
			[] ->%没人
				?ok;
			Data ->
				%% 清archery_reward_server
				archery_reward_server:clear_list(),
				Data1 = misc:to_list(Data),
				lists:map(fun({X,Y,_Z}) -> % X名次， Y玩家名 ，Z分数
								  {GoodsList, Coin, Meritorious} = archery_mod:get_reward_rank(X),
								  %% 发物品
								  MailGoods = lists:foldl(fun({GoodsId, Bind, Count},Acc)->
																  goods_api:make(GoodsId, Bind, Count)++Acc
														  end, [], GoodsList),
								  GoodsIdList = mail_api:get_goods_id(MailGoods, []),
								  Content       = [{[{misc:to_list(X)}]}]++[{GoodsIdList}],
								  %%                               ?MSG_DEBUG("rank,user_name,goods ~p~n", [[X,Y,Content]]),  
								  mail_api:send_interest_mail_to_one2(Y, <<"">>, 
																	  <<"">>, ?CONST_MAIL_ARCHERY_RANK, 
																	  Content, MailGoods, 0, 0, 0, ?CONST_COST_ARCHERY_MAIL),
								  case player_api:get_user_id_by_name  (Y) of 
									  {?ok, UserId} ->
										  case player_api:check_online(UserId) of
											  ?true ->
												  player_api:process_send(UserId, ?MODULE, flush_offline_2, {UserId,Meritorious,Coin});
											  _ -> 
												  %% 玩家离线时.
												  player_offline_api:offline(?MODULE, UserId, {UserId,Meritorious,Coin})
										  end;
									  {?error, ?TIP_COMMON_NO_THIS_PLAYER}->
										  pass
								  end
						  end
						  ,Data1)
		end,
		?ok
	catch
		X:Y ->
			?MSG_ERROR("send reward err: ~p~n",[{X,Y,erlang:get_stacktrace()}])
    end.
%% 发离线
flush_offline(Player, {UserId,Meritorious,Coin}) ->
    %% 发铜钱
    player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Coin, ?CONST_COST_ARCHERY_MAIL),
    %% 发功勋
    case player_api:plus_meritorious(Player,Meritorious) of 
        {?ok, Player2} ->
            Player2;
        _ ->
            Player
    end.
%% 发在线
flush_offline_2(Player, {UserId,Meritorious,Coin}) ->
%%     ?MSG_DEBUG("flush_offline_2 arg",[{UserId,Meritorious,Coin}]),
    {?ok,flush_offline(Player, {UserId,Meritorious,Coin})}.
%% 离线把ets持久化到db
save_archery(Player)->
	try
		UserId = Player#player.user_id,
		Arch = archery_mod:get_archery_ets(Player),
		Sql1 = "INSERT INTO `game_archery_info` (`user_id`,`power`,`angle`,`arrow`,`accGet`,`done`,`courtInfo`,`point`,`time`,`instruction`,`limit_buy`)"++
				   " VALUES('"++misc:to_list(Arch#ets_archery_info.user_id)++"','"
				   ++misc:to_list(Arch#ets_archery_info.power)++"','"
				   ++misc:to_list(Arch#ets_archery_info.angle)++"','"
				   ++misc:to_list(Arch#ets_archery_info.arrow)++"','"
				   ++misc:to_list(Arch#ets_archery_info.accGet)++"','"
				   ++misc:to_list(Arch#ets_archery_info.done)++"', ",
		Sql2 = " ,'"
				   ++misc:to_list(Arch#ets_archery_info.point)++"','"
				   ++misc:to_list(Arch#ets_archery_info.time)++"','"
				   ++misc:to_list(Arch#ets_archery_info.instrution)++"','"
				   ++misc:to_list(Arch#ets_archery_info.limit_buy)++"')"
				   ++" ON DUPLICATE KEY UPDATE `power` ='"++misc:to_list(Arch#ets_archery_info.power)++"',"
				   ++"`angle`='"++misc:to_list(Arch#ets_archery_info.angle)++"',"
				   ++"`arrow`='"++misc:to_list(Arch#ets_archery_info.arrow)++"',"
				   ++"`accGet`='"++misc:to_list(Arch#ets_archery_info.accGet)++"',"
				   ++"`time`='"++misc:to_list(Arch#ets_archery_info.time)++"',"
				   ++"`done`='"++misc:to_list(Arch#ets_archery_info.done)++"',"
				   ++"`courtInfo`= ",
		Sql3 = " ,"
				   ++"`point`='"++misc:to_list(Arch#ets_archery_info.point)++"',"
				   ++"`limit_buy`='"++misc:to_list(Arch#ets_archery_info.limit_buy)++"',"
				   ++"`instruction`='"++misc:to_list(Arch#ets_archery_info.instrution)++"';",
		Sql =  <<  (misc:to_binary(Sql1))/binary
				   ,(mysql_api:encode(Arch#ets_archery_info.courtInfo))/binary
				   ,(misc:to_binary(Sql2))/binary
				   ,(mysql_api:encode(Arch#ets_archery_info.courtInfo))/binary
				   ,(misc:to_binary(Sql3))/binary>>,
		case  mysql_api:execute(Sql) of
			{?error,Wrong} when Wrong =/= []->
				?MSG_ERROR("save player archery wrong: ~p~n---------------------------~nusername:~p~n,time:~p~nstack~p~nArch:~p~n",[Wrong,player_api:get_name(Player#player.user_id),misc:seconds(), erlang:get_stacktrace(),Arch]),
				?error;
			_V ->
				ets:delete(?CONST_ETS_ARCHERY_INFO, UserId)
		end
	catch 
		E:W ->
			?MSG_ERROR("save player archery ,error:~p,Why:~p~n---------------------------~nusername:~p~n,time:~p~nstack~p~n",[E,W,player_api:get_name(Player#player.user_id),misc:seconds(), erlang:get_stacktrace()])
	end,
	ok.
%% ====================================================================
%% Internal functions
%% ====================================================================

    

