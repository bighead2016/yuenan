%% Author: Administrator
%% Created: 2012-9-13
%% Description: 个人竞技场API
%% Remark:	竞技场奖励实时对数据库操作，对应的ETS暂时弃用
-module(single_arena_api).
%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").
-include("record.goods.data.hrl").
-include("record.player.hrl").
-include("record.battle.hrl").
-include("record.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([login/1, initial_ets/0, refresh_oclock/0, refresh_power/2, refresh_daily_db/1, get_player_attack_report/1,
		 get_player_def_report/1, get_single_arena_top_rank_ets/1, insert_report/1, battle_over/4, pack_rank_list/1, 
		 level_up/1, arena_achievement/1, times_cd_to_front/1, get_user_arena_rank/1, refresh_daily_award/0,
		 get_challenge_reward/2, refresh_daily_report/1, refresh_daily_member/1, champion_report_to_front/1,
		 get_single_arena_times/1, refresh_arena_member_db/4, get_single_arena_rank/1, refresh_daily_db/0,
         get_myself_info/1, get_arena_report/1, get_deffender_list/1, get_streak_win_reward_info/1, 
		 get_area_win_top/1, get_target/1, get_daily_award/1, calc_target/1, lookup_campion_report/1,
         update_pro/2, vip/1]).

-export([testit/0,
		 msg_sc_clear_cd/1, 
		 msg_sc_win_streak_award/2, 
		 msg_sc_buy_challenge_time/2,
		 msg_sc_enter_arena/6, 
		 msg_sc_rank/7, 
		 msg_sc_refresh_report/14, 
%% 		 msg_sc_enter/13, 
		 msg_sc_rank_award/1, 
		 msg_sc_champion_report/6,
		 msg_sc_top_rank/1,
         msg_sc_refresh_challenge_list/1,
		 msg_sc_top_streak/1,
         msg_sc_score_update/1,
         msg_sc_target/2]).
%%
%% API Functions
%% 登陆时发送上次一骑讨奖励(功勋)
login(Player) ->
	case ets_api:lookup(?CONST_ETS_ARENA_MEMBER, Player#player.user_id) of
		Member when is_record(Member, ets_arena_member) ->
			Meritorious = Member#ets_arena_member.meritorious,
			{?ok, Player2} = player_api:plus_meritorious(Player, Meritorious),
			ets:update_element(?CONST_ETS_ARENA_MEMBER, Player#player.user_id, [{#ets_arena_member.meritorious, 0}]),
			Player2;
		?null ->
			Player
	end.

%%%%%%%%%%%%%%%%%%%%%%
get_myself_info(UserId) ->
    [_, Member] = single_arena_mod:get_myself_info(UserId),
    Member.

get_streak_win_reward_info(UserId) ->
    single_arena_mod:get_streak_win_reward_info(UserId).

get_deffender_list(UserId) ->
    [_, DefList] = single_arena_mod:get_deffender_list(UserId),
    DefList.

get_arena_report(UserId) ->
    [_, ReportList] = single_arena_mod:get_arena_report(UserId),
    ReportList.
%%%%%%%%%%%%%%%%%%%%%%

%%
%%竞技场每日00:01刷新挑战次数 发放排行奖励(game_arena_member记录了所有竞技场玩家信息,包括在线/离线)
refresh_oclock() ->
	try
		refresh_daily_arena()
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.

refresh_daily_arena() ->
	case ets:first(?CONST_ETS_ARENA_MEMBER) of
		'$end_of_table' ->
			?ok;
		Key ->
			refresh_daily_arena(Key)
	end.

refresh_daily_arena(Key) ->
	refresh_arena_member_ets(Key),
	case ets:next(?CONST_ETS_ARENA_MEMBER, Key) of
		'$end_of_table' ->
			?ok;
		Key2 ->
			refresh_arena_member_ets(Key2),
			refresh_daily_arena(Key2)
	end.
			
refresh_arena_member_ets(Key) ->
    case ets_api:lookup(?CONST_ETS_ARENA_MEMBER, Key) of
        #ets_arena_member{} = Member ->
            % 每日目标
            Rank = Member#ets_arena_member.rank,
            NextRank = calc_target(Rank),
            if
                Member#ets_arena_member.target_state =:= ?CONST_SINGLE_ARENA_STATE_CAN_GET ->
                    mail_api:send_system_mail_to_one(Member#ets_arena_member.player_name, <<>>, <<>>, 1650, [], [], 
                                                     ?CONST_SINGLE_ARENA_REWARD_BGOLD, 0, ?CONST_SINGLE_ARENA_REWARD_BCASH, ?CONST_COST_SINGLE_ARENA_DAILY_TARGET);
                ?true ->
                    ?ok
            end,
            ets_api:update_element(?CONST_ETS_ARENA_MEMBER, Key, [
                                                       {#ets_arena_member.times, 0},
                                                       {#ets_arena_member.winning_streak, 0},
                                                       {#ets_arena_member.cd, 0},
                                                       {#ets_arena_member.daily_buy_time, 0},
                                                       {#ets_arena_member.daily_max_win, 0},
                                                       {#ets_arena_member.clean_times_time, misc:date_num()},
                                                       {#ets_arena_member.streak_wining_reward, []},
                                                       {#ets_arena_member.daily_target, NextRank},
                                                       {#ets_arena_member.target_state, ?CONST_SINGLE_ARENA_STATE_NOT_ARRIVE}
                                                      ]),
            ?ok;
        ?null ->
            ?ok
    end.
%% XXX
calc_target(Rank) ->
    if
        Rank > 1000 ->
            1000;
        Rank =< 1000 andalso 100 < Rank ->
            max(Rank - 100, 100);
        ?true ->
            0
    end.

%% 刷ets_arena_award 发放新的排行奖励
refresh_daily_award() ->
	try
		Now 	= misc:seconds(),
		Elapse 	= calendar:time_to_seconds(misc:time()),
		From 	= (Now - Elapse),
		%% 还有未过期的礼包发送邮件
		case mysql_api:select_execute(<<"SELECT a.`player_id`, a.`rank`, a.`meritorious`, a.`goods`, a.`score` ",
                                        "FROM `game_arena_reward` as a, `game_arena_member` as b ",
                                        "where `get_date`<= `settlement_date` and a.`player_id` = b.`player_id`;">>) of
			{?ok, Data} ->
				mail_over_date_award(Data);
			_Other ->
				?ok
		end, 
		mysql_api:execute(<<"TRUNCATE TABLE `game_arena_reward`;">>),	%清理过期的礼包奖励
		case ets:first(?CONST_ETS_ARENA_MEMBER) of
			'$end_of_table' ->
				?ok;
			Key ->
				refresh_daily_award(Key, From)
		end
	catch
		Error:Reason ->
			?MSG_ERROR("Error ~p, Reason ~p, Strace ~p", [Error, Reason, erlang:get_stacktrace()])
	end.

mail_over_date_award([[UserId, Rank, Meritorious, _Goods, Score]| DataList]) ->
%% 	[GoodsNum, Bind, GoodsId] = single_arena_mod:get_reward_goods(Goods),
	case player_api:check_online(UserId) of
		?true -> %% 在线则主动发送上一天的功勋
			player_api:process_send(UserId, player_api, plus_meritorious, Meritorious),
            case ets_api:lookup(?CONST_ETS_ARENA_MEMBER, UserId) of
                Member when is_record(Member, ets_arena_member) ->
                    NewScore       = Score + Member#ets_arena_member.score,
                    ScorePacket    = msg_sc_score_update(NewScore),
                    misc_packet:send(UserId, ScorePacket),
                    ets:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.score,       NewScore}]);
                ?null ->
                    ?ok
            end;
		?false -> %% 不在线把功勋存起来 等玩家登陆时发
			case ets_api:lookup(?CONST_ETS_ARENA_MEMBER, UserId) of
				Member when is_record(Member, ets_arena_member) ->
					NewMeritorious = Meritorious + Member#ets_arena_member.meritorious,
					NewScore       = Score + Member#ets_arena_member.score,
					ets:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.meritorious, NewMeritorious},
                                                                         {#ets_arena_member.score,       NewScore}]);
				?null ->
					?ok
			end
	end,
	ReceiveName	= player_api:get_name(UserId),
	ScoreList	= [{misc:to_list(Score)}],
	RankList	= [{misc:to_list(Rank)}],
	MerList		= [{misc:to_list(Meritorious)}],
	Content		= [{RankList}] ++ [{MerList}] ++ [{ScoreList}],
	{BGold, BCash} = {0, 0},
	mail_api:send_system_mail_to_one3(ReceiveName, <<>>, <<>>, ?CONST_MAIL_SINGLE_AREA, Content, 
									  [], BGold, 0, BCash, ?CONST_COST_SINGLE_ARENA_RANK,0),
	mail_over_date_award(DataList);
mail_over_date_award([_Other|DataList]) -> mail_over_date_award(DataList);
mail_over_date_award([]) -> ?ok.

refresh_daily_award(Key, From) ->
	refresh_daily_award_db(Key, From),
	case ets:next(?CONST_ETS_ARENA_MEMBER, Key) of
		'$end_of_table' ->
			?ok;
		Key2 ->
			refresh_daily_award_db(Key2, From),
			refresh_daily_award(Key2, From)
	end.
			
refresh_daily_award_db(Key, From) ->
	case ets_api:lookup(?CONST_ETS_ARENA_MEMBER, Key) of
		Member when is_record(Member, ets_arena_member) ->
			#ets_arena_member{rank = Rank, player_lv = Lv} = Member,
			[Meritorious, GoodsNum, Bind, GoodsId, Score] = single_arena_mod:get_rank_reward_data(Rank, Lv),
%% 			?MSG_DEBUG("@@@@@@@@    ~p", [term_to_binary([GoodsNum, Bind, GoodsId])]),
			mysql_api:insert_execute(<<"REPLACE INTO `game_arena_reward` ",
									   "(`player_id`, `get_date`, `meritorious`, `experience`,",
									   " `rank`, `goods`, `on_line_flag`, `sn`, `settlement_date`, `score`)",
									   " VALUES (",
									   " '", (misc:to_binary(Member#ets_arena_member.player_id))/binary, "',",
									   " '", (misc:to_binary(From))/binary, "',",
									   " '", (misc:to_binary(Meritorious))/binary, "',",
									   " '", (misc:to_binary(0))/binary, "',",
									   " '", (misc:to_binary(Rank))/binary, "',",
									   " '", (term_to_binary([GoodsNum, Bind, GoodsId]))/binary, "',",
									   " '", (misc:to_binary(Member#ets_arena_member.on_line_flag))/binary, "',",
									   " '", (misc:to_binary(Member#ets_arena_member.sn))/binary, "',",
									   " '", (misc:to_binary(From))/binary, "',",
                                       " '", (misc:to_binary(Score))/binary, "');">>);
		?null ->
			?ok
	end.

%% 回写ETS数据到数据库 TODO(取ETS数据前加锁)
refresh_daily_db() ->
    Self = erlang:node(),
    refresh_daily_db(Self).
    
refresh_daily_db(Self) ->
    try
    	refresh_daily_member(Self),
    	refresh_daily_report(Self)
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end.

%% 刷ets_arena_member
refresh_daily_member(Self) ->
	case ets:first(?CONST_ETS_ARENA_MEMBER) of
		'$end_of_table' ->
%%             ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:ets_arena_member empty.............3.2/10~n", [Self, ?LINE]),
			?ok;
		Key ->
%%             ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:write ets_arena_member begin.............3.1/10~n", [Self, ?LINE]),
            TotalSize = ets:info(?CONST_ETS_ARENA_MEMBER, size),
			refresh_daily_member(Self, Key, 1, TotalSize),
%%             ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:write ets_arena_member end.............3.2/10~n", [Self, ?LINE]),
            ?ok
	end.

refresh_daily_member(Self, Key, NowCount, TotalSize) ->
%%     ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:write ets_arena_member ing[~p/~p].............3.1.1/10~n", [Self, ?LINE, NowCount, TotalSize]),
%%     ?MSG_ERROR("1[~p]", [Key]),
	refresh_arena_member_db(Self, Key, NowCount, TotalSize),
	case ets:next(?CONST_ETS_ARENA_MEMBER, Key) of
		'$end_of_table' ->
			?ok;
		Key2 ->
            NewNowCount = NowCount + 1,
%% 			refresh_arena_member_db(Self, Key2, NewNowCount, TotalSize),
			refresh_daily_member(Self, Key2, NewNowCount, TotalSize)
	end.

refresh_arena_member_db(_Self, Key, _NowCount, _TotalSize) ->
	case ets_api:lookup(?CONST_ETS_ARENA_MEMBER, Key) of
		Member when is_record(Member, ets_arena_member) ->
            try
    			Result = mysql_api:insert_execute(<<"INSERT INTO `game_arena_member` ",
    									   "(`cd`, `clean_times_time`, `daily_buy_time`, `daily_max_win`,",
    									   " `fight_force`, `on_line_flag`, `open_flag`, `player_career`,",
    									   " `player_id`, `player_lv`, `player_name`, `player_sex`, `rank`,",
    									   " `sn`, `streak_wining_reward`, `times`, `max_win`, `winning_streak`,",
    									   " `meritorious`, `score`, `daily_target`, `target_state`)",
    									   " VALUES (",
    									   " '", (misc:to_binary(Member#ets_arena_member.cd))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.clean_times_time))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.daily_buy_time))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.daily_max_win))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.fight_force))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.on_line_flag))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.open_flag))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.player_career))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.player_id))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.player_lv))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.player_name))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.player_sex))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.rank))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.sn))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.streak_wining_reward))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.times))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.max_win))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.winning_streak))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.meritorious))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.score))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.daily_target))/binary, "',",
    									   " '", (misc:to_binary(Member#ets_arena_member.target_state))/binary, "') ",
    									   " ON DUPLICATE KEY UPDATE `cd` = '", (misc:to_binary(Member#ets_arena_member.cd))/binary, "',",
    									   " `clean_times_time` = '", (misc:to_binary(Member#ets_arena_member.clean_times_time))/binary, "',",
    									   " `daily_buy_time` = '", (misc:to_binary(Member#ets_arena_member.daily_buy_time))/binary, "',",
    									   " `daily_max_win` = '", (misc:to_binary(Member#ets_arena_member.daily_max_win))/binary, "',",
    									   " `fight_force` = '", (misc:to_binary(Member#ets_arena_member.fight_force))/binary, "',",
    									   " `on_line_flag` = '", (misc:to_binary(Member#ets_arena_member.on_line_flag))/binary, "',",
    									   " `open_flag` = '", (misc:to_binary(Member#ets_arena_member.open_flag))/binary, "',",
    									   " `player_career` = '", (misc:to_binary(Member#ets_arena_member.player_career))/binary, "',",
    									   " `player_id` = '", (misc:to_binary(Member#ets_arena_member.player_id))/binary, "',",
    									   " `player_lv` = '", (misc:to_binary(Member#ets_arena_member.player_lv))/binary, "',",
    									   " `player_name` = '", (misc:to_binary(Member#ets_arena_member.player_name))/binary, "',",
    									   " `player_sex` = '", (misc:to_binary(Member#ets_arena_member.player_sex))/binary, "',",
    									   " `rank` = '", (misc:to_binary(Member#ets_arena_member.rank))/binary, "',",
    									   " `sn` = '", (misc:to_binary(Member#ets_arena_member.sn))/binary, "',",
    									   " `streak_wining_reward` = '", (misc:to_binary(Member#ets_arena_member.streak_wining_reward))/binary, "',",
    									   " `times` = '", (misc:to_binary(Member#ets_arena_member.times))/binary, "',",
    									   " `max_win` = '", (misc:to_binary(Member#ets_arena_member.max_win))/binary, "',",
    									   " `winning_streak` = '", (misc:to_binary(Member#ets_arena_member.winning_streak))/binary, "',",
    									   " `meritorious` = '", (misc:to_binary(Member#ets_arena_member.meritorious))/binary, "',",
    									   " `score` = '", (misc:to_binary(Member#ets_arena_member.score))/binary, "',",
    									   " `daily_target` = '", (misc:to_binary(Member#ets_arena_member.daily_target))/binary, "',",
    									   " `target_state` = '", (misc:to_binary(Member#ets_arena_member.target_state))/binary, "';">>),
    			if
                    {?error, []} =/= Result ->
    %%                     ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:write ets_arena_member:~p,~w[~p/~p].............3.1.2/10~n", 
    %%                                [Self, ?LINE, Key, Result, NowCount, TotalSize]),
%%                         ?MSG_ERROR("1[~p]", [Result]),
                        ?ok;
                    ?true ->
                        ?ok
                end
            catch
                X:Y ->
                    ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
                    ?ok
            end;
		X ->
            ?MSG_ERROR("1[~p]", [X]),
%%             ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:write ets_arena_member:~p,~p[~p/~p].............3.1.2/10~n", 
%%                        [Self, ?LINE, Key, X, NowCount, TotalSize]),
			?ok
	end.

%% 刷战报(同时清理旧战报)
refresh_daily_report(Self) ->
	case ets:first(?CONST_ETS_ARENA_REPORT) of
		'$end_of_table' ->
%%             ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:delete all old report end.............3.7/10~n", [Self, ?LINE]),
			?ok;
		Key ->
%%             ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:delete old report:~p .............3.6/10~n", [Self, ?LINE, Key]),
            TotalSize = ets:info(?CONST_ETS_ARENA_REPORT, size),
			catch refresh_daily_report(Self, Key, [], 1, TotalSize),
            ?ok
%%             ?MSG_ERROR("ok[~p|~p]-refresh_daily_db:delete old report:~p end .............3.6/10~n", [Self, ?LINE, Key])
	end.

refresh_daily_report(Self, Key, DelList, NowCount, TotalSize) ->
	refresh_arena_report_db(Self, Key),
	case ets:next(?CONST_ETS_ARENA_REPORT, Key) of
		'$end_of_table' ->
			lists:foreach(fun(TmpKey) -> ets_api:delete(?CONST_ETS_ARENA_REPORT, TmpKey) end, DelList),
			?ok;
		Key2 ->
            try
                NewNowCount = NowCount + 1,
    			case refresh_arena_report_db(Self, Key2) of
    				?null ->
    					refresh_daily_report(Self, Key2, DelList, NewNowCount, TotalSize);
    				DelKey ->
    					refresh_daily_report(Self, Key2, [DelKey|DelList], NewNowCount, TotalSize)
    			end
            catch
                Error:Reason ->
                    ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
                    ?ok
            end
	end.
			
refresh_arena_report_db(_Self, Key) ->
%%     io:format("ok[~p|~p]-refresh_daily_db:delete old report:~p .............3.6/10~n", [Self, ?LINE, Key]),
	case ets_api:lookup(?CONST_ETS_ARENA_REPORT, Key) of
		Report when is_record(Report, ets_arena_report) ->
			case check_drop_old_report(Report) of
				?true ->
%% 					ets_api:delete(?CONST_ETS_ARENA_REPORT, Key),
					mysql_api:delete(game_arena_report, "`id` = \"" ++ Key ++ "\""),
%%                     io:format("ok[~p|~p]-refresh_daily_db:delete old report:~p .............3.6/10~n", [Self, ?LINE, Key]),
					Key;
				?false ->
%% 					io:format("ok[~p|~p]-refresh_daily_db:insert new report:~p .............3.6/10~n", [Self, ?LINE, Key]),
					BinReport	= mysql_api:encode(Report#ets_arena_report.bin_report),
%% 					BinReport0	= (Report#ets_arena_report.bin_report),
					BinReport	= re:replace(BinReport,"'","''",[global,{return,binary}]),
					try
						mysql_api:insert_execute(<<"INSERT INTO `game_arena_report` ",
											   "(`id`, `type`, `result`, `time`, `player_id`, `deffender_id`,",
											   " `deffender_name`, `rank_change_type`, `rank`, `bin_report`)",
											   " VALUES (",
											   " '", (misc:to_binary(Report#ets_arena_report.id))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.type))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.result))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.time))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.player_id))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.deffender_id))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.deffender_name))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.rank_change_type))/binary, "',",
											   " '", (misc:to_binary(Report#ets_arena_report.rank))/binary, "',",
											   " ", BinReport/binary, ")",
											   " ON DUPLICATE KEY UPDATE", 
											   " `id` = '", (misc:to_binary(Report#ets_arena_report.id))/binary, "',",
											   " `type` = '", (misc:to_binary(Report#ets_arena_report.type))/binary, "',",
											   " `result` = '", (misc:to_binary(Report#ets_arena_report.result))/binary, "',",
											   " `time` = '", (misc:to_binary(Report#ets_arena_report.time))/binary, "',",
											   " `player_id` = '", (misc:to_binary(Report#ets_arena_report.player_id))/binary, "',",
											   " `deffender_id` = '", (misc:to_binary(Report#ets_arena_report.deffender_id))/binary, "',",
											   " `deffender_name` = '", (misc:to_binary(Report#ets_arena_report.deffender_name))/binary, "',",
											   " `rank_change_type` = '", (misc:to_binary(Report#ets_arena_report.rank_change_type))/binary, "',",
											   " `rank` = '", (misc:to_binary(Report#ets_arena_report.rank))/binary, "',",
											   " `bin_report` = ", BinReport/binary, ";">>)
					catch
						A:B ->
%% 							io:format("refresh_arena_report_db    A ~p, B ~p, C ~p  ~n", [A, 0, erlang:bit_size(BinReport) rem 8])
							io:format("refresh_arena_report_db    A ~p, B ~p, C ~p  ~n", [A, B, 0])
					end,
					?null
            end;
		?null ->
%%             io:format("ok[~p|~p]-refresh_daily_db:delete old report:~p:~p .............3.6/10~n", [Self, ?LINE, Key, null]),
			?ok,
			?null
	end.

%% 检查战报是否需要丢弃（过期）
check_drop_old_report(Report) ->
	Now = misc:seconds(),
	Old = Report#ets_arena_report.time,
	(Now - Old) > ?CONST_SINGLE_ARENA_REPORT_DEADLINE.
	

testit() ->
	{?ok, List} = mysql_api:select("select * from game_arena_member where player_id = 1571"),
	F = fun(Member)->
				MemberInfo 	= list_to_tuple([ets_arena_member | Member]),
				StreakRaw 	= misc:to_list(MemberInfo#ets_arena_member.streak_wining_reward),
				?MSG_DEBUG("StreakRaw ~p", [StreakRaw])
		end,
	lists:foreach(F, List).

%% application start --> Load硬盘数据到内存
initial_ets() ->
	?ok = init_arena_member(),
	?ok = init_arena_report(),
	?ok.

init_arena_member()->
	ets:delete_all_objects(?CONST_ETS_ARENA_MEMBER),
	F = fun(Member)->
				MemberInfo 	= list_to_tuple([ets_arena_member | Member]),
				StreakRaw 	= misc:to_list(MemberInfo#ets_arena_member.streak_wining_reward),
				StreakRaw2 	= StreakRaw, %misc:string_to_term(StreakRaw),
				Streak = 
					case is_list(StreakRaw2) of
						?true->
							StreakRaw2;
						?false->
							[]
					end,
				NewMemberInfo = MemberInfo#ets_arena_member{streak_wining_reward = Streak},
				ets:insert(?CONST_ETS_ARENA_MEMBER, NewMemberInfo)
		end,
	{?ok, MemberList} = mysql_api:select("select * from game_arena_member"),
	lists:foreach(F, MemberList),
	?ok.

init_arena_report()->
	ets:delete_all_objects(?CONST_ETS_ARENA_REPORT),
	F = fun(Report)->
				RecReport 	= list_to_tuple([ets_arena_report | Report]),
				Id		= misc:to_list(RecReport#ets_arena_report.id),
				DefName  	= misc:to_list(RecReport#ets_arena_report.deffender_name),
				BinReport	= RecReport#ets_arena_report.bin_report,
				ets:insert(?CONST_ETS_ARENA_REPORT, RecReport#ets_arena_report{id = Id,  
																			   deffender_name = DefName,
																			   bin_report = mysql_api:decode(BinReport)})
		end,
	{?ok, ReportList} = mysql_api:select("select * from game_arena_report"),
	lists:foreach(F, ReportList),
    
	F2 = fun([Id2, BinReport2])->
				Id3		= misc:to_list(Id2),
				ets:insert(?CONST_ETS_ARENA_REPORT_CAMPION, {Id3, mysql_api:decode(BinReport2)})
		end,
	{?ok, ReportList2} = mysql_api:select("select `report_id`,`bin_report` from game_arena_champion_report"),
	lists:foreach(F2, ReportList2),
	?ok.

%% init_arena_reward()->
%% 	ets:delete_all_objects(?CONST_ETS_ARENA_REWARD),
%% 	F = fun(Reward)->
%% 				RewardInfo 	= list_to_tuple([ets_arena_reward | Reward]),
%% 				RewardInfo2 = RewardInfo#ets_arena_reward{goods = misc:to_list(RewardInfo#ets_arena_reward.goods)},
%% 				ets:insert(?CONST_ETS_ARENA_REWARD, RewardInfo2)
%% 		end,
%% 	{?ok, RewardList} = mysql_api:select("select * from game_arena_reward"),
%% 	lists:foreach(F, RewardList),
%% 	?ok.

%%玩家升级接口      同步到竞技场表的玩家等级
level_up(Player = #player{user_id = UserId, info = Info}) ->
	Lv		= Info#info.lv,
	ets:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.player_lv, Lv}]),
	case Lv of
		?CONST_SINGLE_ARENA_AUTO_RANK_LV ->
			single_arena_mod:send_auto_rank(Player);
		_Other ->
			?ok
	end.

%%插入一个玩家的战报信息
insert_report(Report)->
	Now = misc:seconds(),
	UserId = Report#ets_arena_report.player_id,
%% 	Type = Report#ets_arena_report.type,
	UniqueId = lists:concat([misc:to_list(UserId), "_", misc:to_list(Now)]),
	
	List = ets:match_object(?CONST_ETS_ARENA_REPORT, #ets_arena_report{player_id = UserId, _ = '_'}),
	case length(List) >= ?CONST_SINGLE_ARENA_REPORT_MAX of
		?true->														%%玩家战报超过缓存限制
			OldReport = get_min(List, #ets_arena_report.time),
			ets:match_delete(?CONST_ETS_ARENA_REPORT, OldReport);
		?false->
			?ok			
	end,
    ets:insert_new(?CONST_ETS_ARENA_REPORT, Report#ets_arena_report{id = UniqueId}),
	UniqueId.

%%获取玩家挑战战报
get_player_attack_report(UserId) ->
	ets:match_object(?CONST_ETS_ARENA_REPORT, #ets_arena_report{player_id = UserId, type = ?CONST_SINGLE_ARENA_ATTACK, _ ='_'}).

%%获取玩家被挑战战报
get_player_def_report(UserId) ->
	ets:match_object(?CONST_ETS_ARENA_REPORT, #ets_arena_report{player_id = UserId, type = ?CONST_SINGLE_ARENA_DEF, _ ='_'}).

%%获取竞技场排名前XX(ets)
get_single_arena_top_rank_ets(Num) ->
	get_single_arena_top_rank_ets(1, Num, []).

get_single_arena_top_rank_ets(From, To, Acc) when From > To ->
	Acc;
get_single_arena_top_rank_ets(From, To, Acc) ->
	Fun = ets:fun2ms(fun(X) when X#ets_arena_member.rank =:= From -> {X#ets_arena_member.rank, X#ets_arena_member.player_id} end),
	case ets:select(?CONST_ETS_ARENA_MEMBER, Fun) of
		'$end_of_table' ->
			get_single_arena_top_rank_ets(From+1, To, Acc);
		[] ->
			get_single_arena_top_rank_ets(From+1, To, Acc);
		[Result|_] ->
			get_single_arena_top_rank_ets(From+1, To, [Result|Acc])
	end.

%%打包竞技场排行榜信息给前端
pack_rank_list(RankList) ->
	pack_rank_list(RankList, []).

pack_rank_list([{Rank, UserId}|Tail], Acc) ->
	Member = single_arena_mod:get_arena_info_by_id(UserId),
	
	#ets_arena_member{player_lv = Lv, player_sex = Sex, player_name = Name, 
					  fight_force = FightForce, player_career = Pro} = Member,
	Trend = single_arena_mod:get_player_trend(UserId),
	[_Meritorious, GoodsNum, _Bind, GoodsId, _Score] = single_arena_mod:get_rank_reward_data(Rank, Lv),
	Data = {Rank, Sex, Lv, FightForce, misc:to_list(Name), Trend, UserId, Pro, GoodsNum, GoodsId},
	pack_rank_list(Tail, [Data|Acc]);
pack_rank_list([], Acc) ->
	Acc.

%% 竞技场表人物战力刷新
refresh_power(UserId, Power) ->
	ets:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.fight_force, Power}]).

%% 成就系统接口
arena_achievement(UserId) ->
	Member = single_arena_mod:get_arena_info_by_id(UserId),
	if
		is_record(Member, ets_arena_member) ->
			streak_win_achievement(UserId, Member),
			rank_top_achievement(UserId, Member),
			?ok;
		?true ->
			?ok
	end.

streak_win_achievement(UserId, #ets_arena_member{winning_streak = StreakWin}) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_ARENA_STREAKWIN, StreakWin, 1).

rank_top_achievement(UserId, #ets_arena_member{rank = Rank}) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_ARENA_ARRAY, Rank, 1).

%% 通知竞技场进程更新相关数据
battle_over(UserId, Result, EnemyId, BinReport) ->
	single_arena_mod:battle_over(UserId, Result, EnemyId, BinReport).

%% 登录推送玩家当日剩余挑战次数/CD时间给前端
times_cd_to_front(UserId) ->
	case single_arena_mod:get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_arena_member) ->
			#ets_arena_member{times = Times, daily_buy_time = BuyTimes} = Member,
			TodayTimes	= single_arena_mod:remain_times(BuyTimes, Times),
			TempTime	= Member#ets_arena_member.cd - misc:seconds(),
			Cd 			= misc:max(TempTime, 0),
			MaxTimes	= ?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES + BuyTimes,
			msg_login_data(TodayTimes, Cd, MaxTimes);
		_ ->
			msg_login_data(?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES, 0, ?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES)
	end.

%% 获取玩家竞技场排名
get_user_arena_rank(UserId) ->
	single_arena_mod:get_user_arena_rank(UserId).

%% 获取单场挑战奖励
get_challenge_reward(Lv, Result) ->
	single_arena_mod:get_challenge_reward(Lv, Result).
%% 登录发送榜首战报
champion_report_to_front(UserId) ->
	single_arena_mod:champion_report_to_front(UserId).


%% 获取一骑讨剩余次数
get_single_arena_times(Player) ->
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_SINGLEARENA) of
		?true	->
			case single_arena_mod:get_arena_info_by_id(Player#player.user_id) of
				Member when is_record(Member, ets_arena_member) ->
					single_arena_mod:remain_times(Member#ets_arena_member.daily_buy_time, Member#ets_arena_member.times);
				_Other ->
					?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES
			end;
		?false ->
			0
	end.

%% 获取一骑讨排名
get_single_arena_rank(UserId) ->
	case ets_api:lookup(?CONST_ETS_ARENA_MEMBER, UserId) of
		Member when is_record(Member, ets_arena_member) ->
			Member#ets_arena_member.rank;
		_ ->
			0
	end.

get_target(Member) ->
    Target = Member#ets_arena_member.daily_target,
    State = Member#ets_arena_member.target_state,
    msg_sc_target(Target, State).

get_daily_award(Player) ->
    UserId = Player#player.user_id,
    MemberUser = single_arena_mod:get_arena_info_by_id(UserId),
    if
        MemberUser#ets_arena_member.target_state =:= ?CONST_SINGLE_ARENA_STATE_CAN_GET ->
%%             mail_api:send_system_mail_to_one(MemberUser#ets_arena_member.player_name, <<>>, <<>>, 1650, [], [], 
%%                                                      ?CONST_SINGLE_ARENA_REWARD_BGOLD, 0, ?CONST_SINGLE_ARENA_REWARD_BCASH, ?CONST_COST_SINGLE_ARENA_DAILY_TARGET),
            player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, ?CONST_SINGLE_ARENA_REWARD_BGOLD, ?CONST_COST_SINGLE_ARENA_DAILY_TARGET),
            player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, ?CONST_SINGLE_ARENA_REWARD_BCASH, ?CONST_COST_SINGLE_ARENA_DAILY_TARGET),
            P1 = message_api:msg_notice(?TIP_REWARD_ADD_BIND_CASH_2, [{?TIP_SYS_COMM, misc:to_list(?CONST_SINGLE_ARENA_REWARD_BCASH)}]),
            P2 = message_api:msg_notice(?TIP_REWARD_ADD_BIND_GOLD_2, [{?TIP_SYS_COMM, misc:to_list(?CONST_SINGLE_ARENA_REWARD_BGOLD)}]),
            ets_api:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.target_state, ?CONST_SINGLE_ARENA_STATE_GOT}]),
            Packet = single_arena_api:msg_sc_target(MemberUser#ets_arena_member.daily_target, ?CONST_SINGLE_ARENA_STATE_GOT),
            misc_packet:send(UserId, <<Packet/binary, P1/binary, P2/binary>>),
            ?ok;
        ?true ->
            ?ok
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 协议
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 打开/关闭竞技场界面
%%[Res,Rank,Streak,TodayTimes,Cd,Gold,Renown,RewardTime,DailyMaxWin,DailyBuyTimes,{GoodState},{UserId,Lv,UserRank,UserName,Pro,Sex,Gold1,Renown1,Gold2,Renown2},{ReportId,FightType,Time,OppUserId,OppName,RankChange,ReportRank,Result}]
%% msg_sc_enter(Res,Rank,Streak,TodayTimes,Cd,Gold,Renown,RewardTime,DailyMaxWin,DailyBuyTimes,List1,List2,List3) ->
%% 	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_ENTER, ?MSG_FORMAT_SINGLE_ARENA_SC_ENTER, [Res,Rank,Streak,TodayTimes,Cd,Gold,Renown,RewardTime,DailyMaxWin,DailyBuyTimes,List1,List2,List3]).

%% 清除cd
%%[Res]
msg_sc_clear_cd(Res) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_CLEAR_CD, ?MSG_FORMAT_SINGLE_ARENA_SC_CLEAR_CD, [Res]).

%% 领取连胜奖励返回
%%[Result]
msg_sc_win_streak_award(Result,List1) ->
	TupleList = lists:map(fun(X) -> {X} end, List1),
	Datas = {Result, TupleList},
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_WIN_STREAK_AWARD, ?MSG_FORMAT_SINGLE_ARENA_SC_WIN_STREAK_AWARD, Datas).

%% 竞技场排行榜返回   
%%[Num,Rank,Sex,Lv,Battle,Name,Trend]
msg_sc_rank(Num,Rank,Sex,Lv,Battle,Name,Trend) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_RANK, ?MSG_FORMAT_SINGLE_ARENA_SC_RANK, [Num,Rank,Sex,Lv,Battle,Name,Trend]).

%% 购买战斗次数返回
%%[Result,Num]
msg_sc_buy_challenge_time(Result,Num) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_BUY_CHALLENGE_TIME, ?MSG_FORMAT_SINGLE_ARENA_SC_BUY_CHALLENGE_TIME, [Result,Num]).

%% 领取排名奖励返回
%%[Result]
msg_sc_rank_award(Result) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_RANK_AWARD, ?MSG_FORMAT_SINGLE_ARENA_SC_RANK_AWARD, [Result]).

%% 更新挑战列表
%%[{UserId,Lv,Rank,Name,Pro,Sex,BattleMeritorious,RankMeritorious,RankGoodsNum,RankGoodsId,EquipArmor,EquipWeapon,GuildName,Horse,Power,EquipFashion}]
msg_sc_refresh_challenge_list(List1) ->
    misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, ?MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, [List1]).

%% 更新战斗信息
%%[Type,Rank,WinStreak,Time,EnemyId,EnemyName,Trend,Report,RewardGold,RewardPrestige,RewardTime,Result,MaxWinStreak,RemainTimes]
msg_sc_refresh_report(Type,Rank,WinStreak,Time,EnemyId,EnemyName,Trend,Report,RewardGold,RewardPrestige,RewardTime,Result,MaxWinStreak,RemainTimes) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_REFRESH_REPORT, ?MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_REPORT, [Type,Rank,WinStreak,Time,EnemyId,EnemyName,Trend,Report,RewardGold,RewardPrestige,RewardTime,Result,MaxWinStreak,RemainTimes]).

%%进入竞技场的协议
msg_sc_enter_arena(?CONST_SINGLE_ARENA_STATE_ON, Result, Member, StreakAwardList, DefList, ReportList) ->
	Rank 			= Member#ets_arena_member.rank,
	Streak 			= Member#ets_arena_member.winning_streak,
	UserId			= Member#ets_arena_member.player_id,
	TodayTimes		= single_arena_mod:remain_times(Member#ets_arena_member.daily_buy_time, Member#ets_arena_member.times),
	TempTime		= Member#ets_arena_member.cd - misc:seconds(),
	Cd 				= misc:max(TempTime, 0),
    Score           = Member#ets_arena_member.score,
	
	[Meritorious, GoodsNum, _Bind, GoodsId, _] = single_arena_mod:get_rank_reward_data(Rank, Member#ets_arena_member.player_lv),
	{IsReward, RewardTime} 	= single_arena_mod:get_next_reward_time(UserId),	%%排名奖励领取时间  每天08:00pm
	
	DailyMaxWin 	= Member#ets_arena_member.daily_max_win,
	MaxWin 			= Member#ets_arena_member.max_win,
	DailyBuyTime	= Member#ets_arena_member.daily_buy_time,
	
	%% 未领取连胜的物品
	Data1 = non_got_goods_list(StreakAwardList, []),
	%% 可挑战角色列表
	Data2 = lists:map(fun(Element) -> single_arena_mod:get_member_binary(Element) end, DefList),
	%% 个人战报信息
	Data3 = lists:map(fun(Element2) -> single_arena_mod:get_report_binary(Element2) end, ReportList),
	Data = 
		[Result, Rank, Streak, TodayTimes, Cd, IsReward, RewardTime, Meritorious, Score, GoodsNum, GoodsId, MaxWin, DailyMaxWin, DailyBuyTime, Data1, Data2, Data3],
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_ENTER, ?MSG_FORMAT_SINGLE_ARENA_SC_ENTER, Data);

msg_sc_enter_arena(_, _Result, _Member, _List1, _List2, _List3) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_ENTER, ?MSG_FORMAT_SINGLE_ARENA_SC_ENTER, []).

%% 登录推送挑战次数/CD
%%[Times,Cd]
msg_login_data(Times,Cd, MaxTimes) ->
	?MSG_DEBUG("msg_login_data11:~p",[{Times,Cd, MaxTimes}]),
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_LOGIN_DATA, ?MSG_FORMAT_SINGLE_ARENA_SC_LOGIN_DATA, [Times,Cd, MaxTimes]).

%% 冠军战报更新
%%[ReportId,UserId,UserName,OppId,OppName]
msg_sc_champion_report(ReportId,UserId,UserName,OppId,OppName,Time) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_CHAMPION_REPORT, ?MSG_FORMAT_SINGLE_ARENA_SC_CHAMPION_REPORT, [ReportId,UserId,UserName,OppId,OppName,Time]).
%% 竞技场英雄榜返回
%%[{UserId,UserRank,UserName,UserSex,UserLv,UserPower,Trend}]
msg_sc_top_rank(List1) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_TOP_RANK, ?MSG_FORMAT_SINGLE_ARENA_SC_TOP_RANK, [List1]).
%% 竞技场连胜榜返回
%%[{UserId,UserRank,UserName,UserLv,UserPower,Streak}]
msg_sc_top_streak(List1) ->
	misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_TOP_STREAK, ?MSG_FORMAT_SINGLE_ARENA_SC_TOP_STREAK, [List1]).
%% 积分改变
%%[Score]
msg_sc_score_update(Score) ->
    misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_SCORE_UPDATE, ?MSG_FORMAT_SINGLE_ARENA_SC_SCORE_UPDATE, [Score]).
%% 每日目标
%%[Target,State]
msg_sc_target(Target,State) ->
    misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_TARGET, ?MSG_FORMAT_SINGLE_ARENA_SC_TARGET, [Target,State]).

%%
%% Local Functions
%%

%% 未领取奖励的次数
non_got_goods_list([], Acc) ->
	Acc;
non_got_goods_list([State|T], Acc) ->
	if
		State > 0 ->
			non_got_goods_list(T, [{State}|Acc]);
		?true ->
			non_got_goods_list(T, Acc)
	end.


get_min([],_Pos)->
	[];
get_min([Head | Tail],Pos)->
	Fun = fun(Elem,{Max})->
				  case erlang:element(Pos,Elem) =< erlang:element(Pos,Max)  of
					  true->
						  {Elem};
					  false->
						  {Max}
				  end
		  end,
	{Max} = lists:foldl(Fun,{Head},Tail),
	Max.

%% 最近自己打败的玩家列表top4(给家园调用)
get_area_win_top(UserId) ->
	ReportList	= 
		case single_arena_mod:get_arena_info_by_id(UserId) of
			[]->
				[];
			_Member->
				AtkList = single_arena_api:get_player_attack_report(UserId),
				Fun = fun(Elem1,Elem2)->
				  			Elem1#ets_arena_report.time > Elem2#ets_arena_report.time
					  end,
				List1 = lists:sort(Fun, AtkList),
				lists:sublist(List1, 4)
		end,
	[X#ets_arena_report.deffender_id || X <- ReportList, X#ets_arena_report.result =:= 1].
	
lookup_campion_report(Id) ->
    case ets_api:lookup(?CONST_ETS_ARENA_REPORT_CAMPION, Id) of
        ?null ->
            <<>>;
        {_, X} ->
            X
    end.

%% 更新职业信息
update_pro(UserId, Pro) ->
    ets_api:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.player_career, Pro}]).

%% vip改变
vip(Player) ->
	VipLv	= player_api:get_vip_lv(Player),
	IsNoCd	= player_vip_api:is_no_arena_cd(VipLv),
	case IsNoCd of
		?CONST_SYS_TRUE ->
			ets:update_element(?CONST_ETS_ARENA_MEMBER, Player#player.user_id, [{#ets_arena_member.cd, misc:seconds()}]),
			Packet	= times_cd_to_front(Player#player.user_id),
			misc_packet:send(Player#player.user_id, Packet);
		?CONST_SYS_FALSE ->
			?ok
	end.
	