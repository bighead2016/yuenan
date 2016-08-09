%% @author liuyujian
%% 注意：
%%箭矢arrow 低两位表示免费次数，高位表示购买的次数
%%
-module(archery_mod).
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 get_srceen/2,
		 ask_top_list/1,
		 shoot/2,
         config/2,
		 get_reword/2, 
		 add_arrow/1,
         get_top_list_db/0,
		 get_top_list/0,
		 get_reward_rank/1,
         refresh/1,
		 retArrow/3,
		 get_archery_ets/1,
		 get_accGet_and_done/1,
		 get_dict_court/0
		]).
%% Arch#ets_archery_info.courtInfo ->[{Pos,Length,Hight}..]
%% 请求界面信息 是否是新靶场
get_srceen(Player, IsNew) ->
    UserId = Player#player.user_id,
	%%     ?MSG_DEBUG("about to get ets",[]),
	Arch = get_archery_ets(Player),
	Place = [{Length,Hight,Pos}|| {Pos,Length,Hight} <- Arch#ets_archery_info.courtInfo],
	Instruction = if Arch#ets_archery_info.instrution > 0 ->
						 ?true;
					 ?true ->
						 ?false
				  end,
	Data = [
			Arch#ets_archery_info.power,
			Arch#ets_archery_info.angle,
            Place,
			Instruction,
			IsNew
		   ],
%%     ?MSG_DEBUG("srceen data :~p~n",Data),
    Packet = misc_packet:pack(?MSG_ID_ARCHERY_SRCEEN_INFO,?MSG_FORMAT_ARCHERY_SRCEEN_INFO,Data),
    get_accGet_and_done(Player),
    retArrow(UserId, Arch#ets_archery_info.arrow, ?CONST_ARCHERY_LIMIT_BUY - Arch#ets_archery_info.limit_buy),
    misc_packet:send(UserId, Packet),
    {?ok,Player}.

%% 请求排行榜信息
ask_top_list(Player)->
    UserId = Player#player.user_id,
    Arch = get_archery_ets(Player),
    Data = [get_top_list(),misc:to_integer(Arch#ets_archery_info.point)],
%%     ?MSG_DEBUG("ask_top_list :~p~n",[Data]),
    Packet = misc_packet:pack(?MSG_ID_ARCHERY_GET_TOP_LIST,?MSG_FORMAT_ARCHERY_GET_TOP_LIST,Data),
    misc_packet:send(UserId, Packet),
    {?ok,Player}.

%% 射击
shoot(Player,{Angle,Power})->
    UserId = Player#player.user_id,
    Arch = get_archery_ets(Player),
    Angle2 = Angle/180*math:pi(),
    V_h = erlang:abs(Power * math:cos(Angle2)),%水平速度
    V_v = erlang:abs(Power * math:sin(Angle2)),%垂直速度
%%     ?MSG_DEBUG("{Angle,Power}~p~n",[{Angle,Power,math:cos(Angle2),math:sin(Angle2)}]),
    case Arch#ets_archery_info.arrow > 0 of
        ?true ->
            Fshoot = fun(X,Y) ->%X是横轴
                             T = (X - ?CONST_ARCHERY_ARROW_L * math:cos(Angle2) ) / V_h,
                             H2 = ?CONST_ARCHERY_ARROW_L * math:sin(Angle2) + V_v*T - get_gravity() * T * T/2,
%%                              ?MSG_DEBUG("H2 :~p~n",[H2]),
                             if  H2 < Y andalso H2 > Y-?CONST_ARCHERY_RANGE ->
                                     ?true;
                                 ?true ->
                                     ?false
                             end
                     end,
            DataList = [{Pos} || {Pos,Length,Hight} <- Arch#ets_archery_info.courtInfo,% 击倒的靶子号
                                 Fshoot(Length,Hight)],
%%             ?MSG_DEBUG("killed on~p~n",[DataList]),
            Data = [DataList],
            After =[{Pos,Length,Hight}|| {Pos,Length,Hight} <- Arch#ets_archery_info.courtInfo,
                                         (lists:keymember(Pos, 1, [Pos || Pos <- DataList ]) =:= ?false)],
            Kill = length(DataList),
            PointAdd = case Kill of 
                           1 ->
                               ?CONST_ARCHERY_SINGLE_HIT;
                           2 ->
                               ?CONST_ARCHERY_DOUBLE_HIT;
                           3 ->
                               ?CONST_ARCHERY_TRI_HIT;
                           4 ->
                               ?CONST_ARCHERY_FULL_HIT;
                           _ ->
                               0
                       end,
            PointNew = Arch#ets_archery_info.point + PointAdd,
            if PointAdd > 0 -> only_add_point(player_api:get_name(UserId), PointNew);
			   ?true ->?ok end, 
			LastPlace = length(After),
			ExpAdd1 = Kill * round((0.4 + 0.6*(Player#player.info)#info.lv) * 50), % 靶子经验 （0.4+0.6*等级）*50
			ExpAdd2 = %靶场经验（0.4+0.6*等级）*100
				case LastPlace of 
					0 ->
						round((0.4 + 0.6*(Player#player.info)#info.lv) * 100) ;
					_ ->
						0
				end,
			AccGetNew = Arch#ets_archery_info.accGet + ExpAdd1 + ExpAdd2,
			DoneNew = case LastPlace of 
						  0 ->
							  Arch#ets_archery_info.done + 1;
						  _ ->
							  Arch#ets_archery_info.done
					  end,
			CourtInfoNew = case LastPlace of 
							   0 ->
                                   get_new_court();
                               _ ->
                                   After
                           end,
			InstructionNew = 
				if Arch#ets_archery_info.instrution > 0 ->
					   Arch#ets_archery_info.instrution -1;
				   ?true ->
					   0
				end,
            ArchNew = Arch#ets_archery_info{user_id=UserId,
                                        power=Power,
                                        angle=Angle,
                                        arrow=minusArrow(Arch#ets_archery_info.arrow),
                                        accGet=AccGetNew,
										done = DoneNew,
										courtInfo = CourtInfoNew,
										point = PointNew,
										time = misc:seconds(),
										instrution = InstructionNew},
			ets:insert(?CONST_ETS_ARCHERY_INFO, ArchNew),
			%%返回射击结果
			%%             ?MSG_DEBUG("返回射击结果~p~n",Data),
            Packet = misc_packet:pack(?MSG_ID_ARCHERY_RESULT_SHOOT,?MSG_FORMAT_ARCHERY_RESULT_SHOOT,Data),
			misc_packet:send(UserId, <<Packet/binary>>),
			get_accGet_and_done(Player),
			retArrow(UserId, minusArrow(Arch#ets_archery_info.arrow), Arch#ets_archery_info.limit_buy),
			if Kill > 0 ->
				   PacketExp = misc_packet:pack(?MSG_ID_ARCHERY_ADD_REWARD,?MSG_FORMAT_ARCHERY_ADD_REWARD,[Kill, ExpAdd1, ExpAdd2]),
				   misc_packet:send(UserId, PacketExp);
			   ?true ->
				   ?ok
			end,
			if DoneNew =/= Arch#ets_archery_info.done ->
				   %% 下次为新靶场
				   erlang:put("archery_is_first_court", ?true);
			   ?true ->
				   ?ok
			end,
			{?ok,Player};
		_ -> %% 箭矢不能没有
			if Arch#ets_archery_info.limit_buy =:= 0 ->
				   PacketNShoot = message_api:notice(?TIP_ARCHERY_NO_SHOOTTING),
				   misc_packet:send(PacketNShoot);
			   ?true ->
				   ?ok
			end,
			{?ok,Player}
	end.

%% 配置游戏参数
config(Player, {Gravity})->
    ets:insert(ets_archery_gravity_t, {gravity_t,Gravity/100}),
    ?MSG_DEBUG("GRAVIRY Changed to ~p~n",[Gravity/100]),
	{?ok,Player}.

%% 累积奖励和通关靶场
get_accGet_and_done(Player)->
    UserId = Player#player.user_id,
    Arch = get_archery_ets(Player),
    Data = [misc:to_integer(Arch#ets_archery_info.accGet), misc:to_integer(Arch#ets_archery_info.done)],
    Packet = misc_packet:pack(?MSG_ID_ARCHERY_SC_REWORD,?MSG_FORMAT_ARCHERY_SC_REWORD,Data),
    misc_packet:send(UserId, Packet),
    {?ok,Player}.

%% 领取奖励
get_reword(Player, HaveMsg) when is_boolean(HaveMsg)->
	UserId = Player#player.user_id,
	Arch = get_archery_ets(Player),
	case Arch#ets_archery_info.accGet >0 of
		?true -> % 可以领取
			%%             ?MSG_DEBUG("plus_money~p~n:::",[{UserId, ?CONST_SYS_GOLD_BIND, Arch#ets_archery_info.accGet,
			%%                                              ?CONST_COST_ARCHERY_REWORD_GOLD}]),
			case player_api:exp(Player, Arch#ets_archery_info.accGet) of
				{?ok, PlayerNew} ->
					if HaveMsg ->
						   Packet = message_api:msg_notice(?TIP_ARCHERY_ACCGET),
						   misc_packet:send(UserId, Packet);
					   ?true ->?ok
					end,
					ets:update_element(?CONST_ETS_ARCHERY_INFO, UserId, [{#ets_archery_info.accGet,0},{#ets_archery_info.done,0},{#ets_archery_info.time,misc:seconds()}]),
					get_accGet_and_done(Player),
					{?ok, PlayerNew};
				{?error, _ErrorCode} ->
					{?ok, Player}
			end;
		_ ->
			if HaveMsg ->
				   Packet2 = message_api:msg_notice(?TIP_ARCHERY_NO_ACCGET),
				   misc_packet:send(UserId, Packet2);
			   ?true ->?ok
			end,
			{?ok, Player}
	end.

%% 增加箭矢
add_arrow(Player)->
	UserId = Player#player.user_id,
	Arch = get_archery_ets(Player),
	if Arch#ets_archery_info.limit_buy > 0 ->
		   case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_ARCHERY_ARROW_PRICE, ?CONST_COST_ARCHERY_ARROW) of
			   ?ok ->
				   ets:update_element(?CONST_ETS_ARCHERY_INFO, UserId, [{#ets_archery_info.arrow,Arch#ets_archery_info.arrow+100},{#ets_archery_info.time,misc:seconds()},{#ets_archery_info.limit_buy,Arch#ets_archery_info.limit_buy - 1}]),
				   %%                            ?MSG_DEBUG("ets_api update:~p~n",[{?CONST_ETS_ARCHERY_INFO, UserId, [{#ets_archery_info.arrow,Arch#ets_archery_info.arrow+1},{#ets_archery_info.arrow,misc:seconds()}]}]),
				   Packet = message_api:msg_notice(?TIP_MALL_SUCCESS),
				   misc_packet:send(UserId, Packet),
				   %%返回界面信息
				   retArrow(UserId, Arch#ets_archery_info.arrow+100, ?CONST_ARCHERY_LIMIT_BUY - Arch#ets_archery_info.limit_buy + 1);
			   _ ->
				   ?false
		   end;
	   ?true ->
		   Packet2 = message_api:msg_notice(?TIP_ARCHERY_LIMIT_BUY),
		   misc_packet:send(UserId, Packet2)
	end,
	{?ok,Player}.

%% 获取archery_reward_server维护的排行榜 ;;->[]|[{排名，玩家名，积分}..]
get_top_list() ->
    List = archery_reward_server:archery_top_list(),%List->[[userid,point]..]
    {Out, _} = lists:foldl(fun({X1,X2},{Y,Z}) ->{[{Z,X1,X2}|Y],Z-1} end, {[],10}, List),
%%      ?MSG_ERROR("out :~p~n",[Out]),
    lists:filter(fun({_X,_Y,Z}) ->  if Z > 0 -> ?true; ?true -> ?false end end, Out). %[{X,Y,Z}||{X,Y,Z}<-Out,Z>0],

%% 获取数据库排行榜 ->[]|[{排名，玩家名，积分}..]
get_top_list_db()->
    Sql = "select `user_id`,`point` from `game_archery_info` order by `point` desc limit 0,10;",
    case mysql_api:select(<<Sql>>) of
        {?ok, [?undefined]} -> {};
        {?ok, DB} -> %DB->[[userid,point]..]
            lists:foldl(fun([X1,X2],{Y,Z}) ->{[{Z,X1,X2}|Y],Z+1} end, {[],1}, DB);
        _ ->
            ?MSG_ERROR("Err Msg at archery_mod : get_top_list_db..",[]),
            {}
    end.

%% 刷新靶场
refresh(Player) ->
	UserId = Player#player.user_id,
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_ARCHERY_NEWCOURT_PRICE , ?CONST_COST_ARCHERY_ARROW) of
		?ok ->
			ets:update_element(?CONST_ETS_ARCHERY_INFO, UserId, [{#ets_archery_info.courtInfo,get_new_court()},{#ets_archery_info.time,misc:seconds()}]),
			Packet = message_api:msg_notice(?TIP_ARCHERY_NEWCOURT),
			misc_packet:send(UserId, Packet),
			get_srceen(Player, ?true);
		_ ->
			?false
	end,
	{?ok,Player}.

%% 剩余箭矢返回
%% 真实箭矢数量是 round(Arrow/100)+Arrow rem 100
retArrow(UserId,Arrow,Bought)->
    Packet = misc_packet:pack(?MSG_ID_ARCHERY_GET_ADD_ARROW, ?MSG_FORMAT_ARCHERY_GET_ADD_ARROW, [(round(Arrow/100)+Arrow rem 100), misc:to_integer(Bought)]),
    misc_packet:send(UserId, Packet).
%% ====================================================================
%% Internal functions
%% ====================================================================

%% 获取ets表信息 ->#ets_archery_info,当天数据有效
get_archery_ets(Player) ->
    Now = misc:seconds(),
    UserId = Player#player.user_id,
	deal_dict_acc(UserId),
	Arch = #ets_archery_info{user_id=UserId,
							 power=0,
                             angle=45,
                             arrow=?CONST_ARCHERY_ARROW_COMMON,
                             accGet=0,
                             done =0,
                             courtInfo=get_new_court(),
                             point=0,
                             time=Now,
							 instrution = ?CONST_ARCHERY_INSTRUCTION,
							 limit_buy = ?CONST_ARCHERY_LIMIT_BUY},
    case ets:lookup(?CONST_ETS_ARCHERY_INFO, UserId) of
        [] ->
            case get_archery_db(Player) of
                [] ->
                    ets:insert(?CONST_ETS_ARCHERY_INFO, Arch),
                    Arch;
                DBdata ->
                    ets:insert(?CONST_ETS_ARCHERY_INFO, DBdata),
                    DBdata
            end;
        [ArcheryInfo] ->
            case misc:is_same_date(Now, ArcheryInfo#ets_archery_info.time) of
                ?true ->
					ArcheryInfo;
				_ ->
					%% player进程未启动时候，process_send失败，因此记到标识位里
					case player_api:check_online(UserId) of 
						?true->
							player_api:process_send(UserId, player_api, exp, ArcheryInfo#ets_archery_info.accGet);
						?false ->
							if ArcheryInfo#ets_archery_info.accGet >0 ->
								   elang:put(?CONST_ARCHERY_DICT_ACC, ArcheryInfo#ets_archery_info.accGet);
							   ?true ->
								   ?ok
							end
					end,
					erlang:put(?CONST_ARCHERY_DICT_NEW_COURT, ?true),
					Arch2 = #ets_archery_info{
											  user_id=UserId,
											  power=0,
											  angle=45,
											  arrow=round(ArcheryInfo#ets_archery_info.arrow/100)*100 + ?CONST_ARCHERY_ARROW_COMMON,
											  accGet=0,
											  done =0,
											  courtInfo=get_new_court(),
											  point=0,
											  time=Now,
											  instrution = ArcheryInfo#ets_archery_info.instrution,
											  limit_buy = ?CONST_ARCHERY_LIMIT_BUY
											 },
					ets:insert(?CONST_ETS_ARCHERY_INFO, Arch2),
					Arch2
			end
    end.

%% 获取数据库game_archery_info表的【有效】信息
get_archery_db(Player) ->
    UserId = Player#player.user_id,
    Sql = "select `user_id`,`power`,`angle`,`arrow`,`accGet`,`done`,`courtInfo`,`point`,`time`,`instruction`,`limit_buy`  from `game_archery_info` where `user_id` ="++misc:to_list(UserId),
    case mysql_api:select(Sql) of
        {?ok, [?undefined]} -> [];
		{?ok, []} -> [];
        {?ok, [[UserId,Power,Angle,Arrow,AccGet,Done,CourtInfo,Point,Time,Instrution,Limit_buy]]} ->
            case misc:is_same_date(misc:seconds(), Time) of
                ?true ->
                    #ets_archery_info{
									  user_id=UserId,
                                      power=Power,
                                      angle=Angle,
                                      arrow=Arrow,
                                      accGet=AccGet,
                                      done = Done,
									  courtInfo = mysql_api:decode(CourtInfo),
									  point = Point,
									  time = Time,
									  instrution = Instrution,
									  limit_buy = Limit_buy};
				_ ->
					case player_api:check_online(UserId) of 
						?true->
							player_api:process_send(UserId, player_api, exp, AccGet);
						?false ->
							set_dict_acc(AccGet)
					end,
					set_dict_new_court(),
					#ets_archery_info{
									  user_id=UserId,
									  power=0,
									  angle=45,
									  arrow=round(Arrow/100)*100 + ?CONST_ARCHERY_ARROW_COMMON,
									  accGet=0,
									  done =0,
									  courtInfo=get_new_court(),
									  point=0,
									  time=misc:seconds(),
									  instrution = Instrution,
									  limit_buy = ?CONST_ARCHERY_LIMIT_BUY}
			end;
		V ->
			?MSG_ERROR("**************~n_V:~p~n,stack:~p~n", [V, erlang:get_stacktrace()]),
			[]
	end.

%% 获取新的靶场
get_new_court()->
    data_archery:get_court_info(random:uniform(20)).
%% 获取奖励信息No排名->{GoodList, coin, meritorious}
get_reward_rank(No)->
    data_archery:get_archery_bonus(No).

%% 更新user积分
only_add_point(UserName,Point)->
    archery_reward_server:archery_point_change(UserName, Point).

%% 获取重力系数
get_gravity()->
	?CONST_ARCHERY_G;
%% (调试用)获取重力系数
get_gravity()->
    try
        [{_,G}] = ets:lookup(ets_archery_gravity_t, gravity_t),
        ?MSG_DEBUG("GRAVIRY Now ~p~n",[G]),
        G
    catch
        X:Y ->
            ?MSG_DEBUG("GRAVIRY ::ERR ~p~n",[{X,Y,erlang:get_stacktrace()}]),
            ?CONST_ARCHERY_G
    end.

minusArrow(Arrow)->
	Free = Arrow rem 100,
	if Free > 0 ->
		   Arrow - 1;
	   Arrow >= 100 ->
		   Arrow - 100;
	   ?true ->
		   ?MSG_ERROR("Arrow must above 0,now is ~p.~n",[Arrow]),
		   0
	end.

%% 是否是新靶场，如果是，返回true并设置为false
get_dict_court()->
	case erlang:get(?CONST_ARCHERY_DICT_NEW_COURT) of 
		?undefined ->
			?false;
		?true ->
			erlang:put(?CONST_ARCHERY_DICT_NEW_COURT, ?false),
			?true;
		?false ->
			?false
	end.

%% 设置下次获取界面时，为新靶场
set_dict_new_court()->
	erlang:put(?CONST_ARCHERY_DICT_NEW_COURT, ?true).

%% 因为player没有完成init时，process_send失败,又要刷新acc的值，所以存在这里
set_dict_acc(Acc)->
	erlang:put(?CONST_ARCHERY_DICT_ACC, Acc).
%% 处理保留的acc经验,清除dict
deal_dict_acc(UserId)->
	%% 检查有没有acc存在进程中
	case erlang:get(?CONST_ARCHERY_DICT_ACC) of
		?undefined ->
			?ok;
		Acc ->
			case player_api:check_online(UserId) of 
				?true->
					player_api:process_send(UserId, player_api, exp,Acc),
					erlang:erase(?CONST_ARCHERY_DICT_ACC);
				?false ->
					?ok
			end
	end.