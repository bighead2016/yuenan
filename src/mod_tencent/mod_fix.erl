-module(mod_fix).

-compile(export_all).

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/record.home.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").


start() ->
	fix_blob(),
	fix_friend(),
	fix_guild().


fix_guild() ->
	Sid    = config:read_deep([server, base, sid]),
	FixValue = (Sid - 1)*100000,
	guild_db_mod:select_data(),
	Guilds = ets:tab2list(?CONST_ETS_GUILD_DATA),
	Fun = fun(Guild) ->
		Fun2 = fun({Pos,IDs}) ->
			Fun3 = fun(ID) ->
				case ID < FixValue of
					true ->
						ID + FixValue;
					false ->
						ID
				end
			end,
			{Pos,lists:map(Fun3,IDs)}
		end,
		NewGuild = Guild#guild_data{pos_list = lists:map(Fun2,Guild#guild_data.pos_list)},
		case NewGuild /= Guild of
			true ->
				guild_db_mod:update_data(NewGuild);
				% io:format("fix guild [~p]~n", [Guild#guild_data.guild_id]);
			false ->
				void
		end
	end,
	lists:map(Fun,Guilds).


fix_friend() ->
	Sid    = config:read_deep([server, base, sid]),
	FixValue = (Sid - 1)*100000,
	relation_db_mod:select_data(),
	Friends = ets:tab2list(?CONST_ETS_RELATION_DATA),
	Fun = fun(Friend) ->
		Fun1 =fun(R) ->
			case R#relation.mem_id < FixValue of
				true ->
					R#relation{mem_id = R#relation.mem_id + FixValue};
				false ->
					R
			end
		end,
		NewFirend = Friend#relation_data{friend_list = lists:map(Fun1,Friend#relation_data.friend_list),
										 best_list = lists:map(Fun1,Friend#relation_data.best_list),
										 black_list = lists:map(Fun1,Friend#relation_data.black_list)

		},
		case NewFirend /= Friend of
			true ->
				relation_db_mod:replace_data(NewFirend);
				% io:format("fix guild [~p]~n", [Friend#relation_data.user_id]);
			false ->
				void
		end
	end,
	lists:map(Fun,Friends).



fix_blob() ->
	Sid    = config:read_deep([server, base, sid]),
	FixValue = (Sid - 1)*100000,
	MinID =
	case mysql_api:select_execute(<<"SELECT min(`user_id`) FROM  `game_user`;">>) of
		{?ok,[[Min]]} -> Min;
		_ ->  1
	end,
	MaxID =
	case mysql_api:select_execute(<<"SELECT max(`user_id`) FROM  `game_user`;">>) of
		{?ok,[[Max]]} -> Max;
		_ ->  1
	end,
	Fun = fun(UserId) ->
		case player_mod:read_player(UserId) of
			{?ok, ?null} -> void;
			{?ok, Player} -> 
				NewPlayer = fix_player(Player,FixValue),
				case NewPlayer /= Player of
					true ->
						player_mod:write_player(NewPlayer,3);
						% io:format("fix blob [~p]~n", [UserId]);
					false ->
						void
				end
		end
	end,
	lists:map(Fun,lists:seq(MinID,MaxID)).


fix_player(Player,FixValue) ->
	Equip = Player#player.equip,
	Fun1 = fun({{UserId, CtnType}, Arg}) ->
		case CtnType  of
			4 ->
				case UserId < FixValue of
					true ->
						{{UserId+FixValue, CtnType}, Arg};
					false ->
						{{UserId, CtnType}, Arg}
				end;
			5 ->
				case UserId > FixValue of
					true ->
						{{UserId-FixValue, CtnType}, Arg};
					false ->
						{{UserId, CtnType}, Arg}
				end;
			_ ->
				io:format("unkown type,[~p]~n",[{{UserId, CtnType}, Arg}]),
				{{UserId, CtnType}, Arg}
		end
	end,
	NewEquip = lists:map(Fun1,Equip),
	Camp = Player#player.camp,
	Camps = Camp#camp_data.camp,
	Fun2 = fun(CampOne) ->
		Fun3 = fun(CampPos) ->
			case is_record(CampPos,camp_pos) of
				true ->
					case CampPos#camp_pos.type == 1 andalso CampPos#camp_pos.id < FixValue of
						true ->
							CampPos#camp_pos{id = CampPos#camp_pos.id + FixValue};
						false ->
							CampPos
					end;
				false ->
					CampPos
			end
		end,
		CampOne#camp{position = list_to_tuple(lists:map(Fun3,tuple_to_list(CampOne#camp.position)))}
	end,
	NewCamp = Camp#camp_data{camp = lists:map(Fun2,Camps)},

	Welfare = Player#player.welfare,

	NewWelfare = 
	case Welfare#welfare.user_id < FixValue of
		true ->
			Welfare#welfare{user_id = Welfare#welfare.user_id + FixValue};
		false ->
			Welfare
	end,

	MindDate = Player#player.mind,

	Fun4 = fun(MindUser) ->
		case MindUser#mind_use.type == 1 andalso MindUser#mind_use.user_id < FixValue of
			true ->
				MindUser#mind_use{user_id = MindUser#mind_use.user_id + FixValue};
			false ->
				MindUser
		end
	end,


	NewMindData = MindDate#mind_data{mind_uses = lists:map(Fun4,MindDate#mind_data.mind_uses)},

	case home_db_mod:read_home_info(Player#player.user_id) of
		{?ok, []} ->        							%% 第一次进入家园，需创建家园
			void;
		{?error, _Error}->
			void;
		Home1 ->              					        %% 从数据库里得到数据，要进行数据格式转换
			Home = home_api:record_home(Home1),

			Fun5 = fun(ID) ->
				case ID < FixValue andalso ID > 0 of
					true ->
						ID+FixValue;
					false ->
						case ID == FixValue of
							true ->
								0;
							false ->
								ID
						end
				end
			end,
			Fun6 = fun(Recomend) ->
				case Recomend#recommend_list.id < FixValue andalso Recomend#recommend_list.id > 0 of
					true ->
						Recomend#recommend_list{id = Recomend#recommend_list.id + FixValue};
					false ->
						case Recomend#recommend_list.id == FixValue of
							true ->
								Recomend#recommend_list{id = 0};
							false ->
								Recomend
						end
				end
			end,
			Fun7 = fun(GrabInfo) ->
				case GrabInfo#grab_girl_info.owner_id < FixValue andalso GrabInfo#grab_girl_info.owner_id > 0 of
					true ->
						GrabInfo#grab_girl_info{owner_id =GrabInfo#grab_girl_info.owner_id + FixValue};
					false ->
						case GrabInfo#grab_girl_info.owner_id == FixValue of
							true ->
								GrabInfo#grab_girl_info{owner_id = 0};
							false ->
								GrabInfo
						end
				end
			end,

			Fun8 = fun(Enemy) ->
				case Enemy#enemy_list.id < FixValue andalso Enemy#enemy_list.id > 0 of
					true ->
						Enemy#enemy_list{id =Enemy#enemy_list.id + FixValue};
					false ->
						case Enemy#enemy_list.id == FixValue of
							true ->
								Enemy#enemy_list{id = 0};
							false ->
								Enemy
						end
				end
			end,

			Girl = Home#ets_home.girl,
			NewBelonger = 
			case Girl#girl.belonger < FixValue andalso Girl#girl.belonger > 0 of
				true ->
					Girl#girl.belonger + FixValue;
				false ->
					case Girl#girl.belonger == FixValue of
						true ->
							0;
						false ->
							Girl#girl.belonger
					end
			end,
			NewGirl = Girl#girl{source_list = lists:map(Fun5,Girl#girl.source_list),
								recommend_list = list_to_tuple(lists:map(Fun6,tuple_to_list(Girl#girl.recommend_list))),
								grab_girl_info = list_to_tuple(lists:map(Fun7,tuple_to_list(Girl#girl.grab_girl_info))),
								enemy_list = list_to_tuple(lists:map(Fun8,tuple_to_list(Girl#girl.enemy_list))),
								battle_list = lists:map(Fun5,Girl#girl.battle_list),
								belonger = NewBelonger

			},

			NewHome = Home#ets_home{girl = NewGirl},
			home_db_mod:update_home_play_girl(NewHome),
			io:format("fix girl [~p]~n",[Player#player.user_id]),
			void
	end,

	Player#player{equip = NewEquip,camp = NewCamp,welfare = NewWelfare,state = 1,mind = NewMindData}.



fix_none_girl(UserId) ->
	Sid    = config:read_deep([server, base, sid]),
	FixValue = (Sid - 1)*100000,
	case home_db_mod:read_home_info(UserId) of
		{?ok, []} ->        							%% 第一次进入家园，需创建家园
			void;
		{?error, _Error}->
			void;
		Home1 ->              					        %% 从数据库里得到数据，要进行数据格式转换
			Home = home_api:record_home(Home1),

			Fun5 = fun(ID) ->
				case ID < FixValue andalso ID > 0 of
					true ->
						ID+FixValue;
					false ->
						case ID == FixValue of
							true ->
								0;
							false ->
								ID
						end
				end
			end,
			Fun6 = fun(Recomend) ->
				case Recomend#recommend_list.id < FixValue andalso Recomend#recommend_list.id > 0 of
					true ->
						Recomend#recommend_list{id = Recomend#recommend_list.id + FixValue};
					false ->
						case Recomend#recommend_list.id == FixValue of
							true ->
								Recomend#recommend_list{id = 0};
							false ->
								Recomend
						end
				end
			end,
			Fun7 = fun(GrabInfo) ->
				case GrabInfo#grab_girl_info.owner_id < FixValue andalso GrabInfo#grab_girl_info.owner_id > 0 of
					true ->
						GrabInfo#grab_girl_info{owner_id =GrabInfo#grab_girl_info.owner_id + FixValue};
					false ->
						case GrabInfo#grab_girl_info.owner_id == FixValue of
							true ->
								GrabInfo#grab_girl_info{owner_id = 0};
							false ->
								GrabInfo
						end
				end
			end,

			Fun8 = fun(Enemy) ->
				case Enemy#enemy_list.id < FixValue andalso Enemy#enemy_list.id > 0 of
					true ->
						Enemy#enemy_list{id =Enemy#enemy_list.id + FixValue};
					false ->
						case Enemy#enemy_list.id == FixValue of
							true ->
								Enemy#enemy_list{id = 0};
							false ->
								Enemy
						end
				end
			end,

			Girl = Home#ets_home.girl,
			NewBelonger = 0,
			NewGirl = Girl#girl{source_list = lists:map(Fun5,Girl#girl.source_list),
								recommend_list = list_to_tuple(lists:map(Fun6,tuple_to_list(Girl#girl.recommend_list))),
								grab_girl_info = list_to_tuple(lists:map(Fun7,tuple_to_list(Girl#girl.grab_girl_info))),
								enemy_list = list_to_tuple(lists:map(Fun8,tuple_to_list(Girl#girl.enemy_list))),
								battle_list = lists:map(Fun5,Girl#girl.battle_list),
								belonger = NewBelonger

			},

			NewHome = Home#ets_home{girl = NewGirl},
			home_db_mod:update_home_play_girl(NewHome),
			io:format("fix none girl [~p]~n",[UserId]),
			void
	end.
