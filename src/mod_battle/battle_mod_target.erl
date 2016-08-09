%% Author: cobain
%% Created: 2012-9-18
%% Description: TODO: Add description to battle_mod_target
-module(battle_mod_target).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.battle.hrl").
%%
%% Exported Functions
%%
-export([target/5, revise_select/4]).
-export([select_seq_default/1, select_seq_neighbour/1, select_seq_row/1, select_seq_column/1]).
-export([get_row/1, get_column/1]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_BATTLE_TARGET_TYPE_DEFAULT             % 目标类型--默认已有目标 
%% CONST_BATTLE_TARGET_TYPE_SELF                % 目标类型--自己 
%% CONST_BATTLE_TARGET_TYPE_SINGLE              % 目标类型--单体 
%% CONST_BATTLE_TARGET_TYPE_NEIGHBOUR           % 目标类型--攻击目标相邻目标 
%% CONST_BATTLE_TARGET_TYPE_MIN_HP              % 目标类型--血量最少 
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_2            % 目标类型--血量最少2个
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_3            % 目标类型--血量最少3个
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_4            % 目标类型--血量最少4个
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_5            % 目标类型--血量最少5个
%% CONST_BATTLE_TARGET_TYPE_MAX_MAGIC_ATTACK	% 目标类型--法术攻击力最大
%% CONST_BATTLE_TARGET_TYPE_ALL                 % 目标类型--全体 
%% CONST_BATTLE_TARGET_TYPE_ALL_MAGIC           % 目标类型--全体法系职业 
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_1        % 目标类型--敌方随机1人 
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_2        % 目标类型--敌方随机2人 
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_3        % 目标类型--敌方随机3人 
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_4        % 目标类型--敌方随机4人 
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_5        % 目标类型--敌方随机5人 
%% CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_1			% 目标类型--攻击目标相邻目标1人 
%% CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_2			% 目标类型--攻击目标相邻目标2人 
%% CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_3			% 目标类型--攻击目标相邻目标3人 
%% CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_4			% 目标类型--攻击目标相邻目标4人 
%% CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_5			% 目标类型--攻击目标相邻目标5人 
%% CONST_BATTLE_TARGET_TYPE_ROW                 % 目标类型--攻击目标所在列 
%% CONST_BATTLE_TARGET_TYPE_COLUMN              % 目标类型--攻击目标所在行（最前排） 
%% CONST_BATTLE_TARGET_TYPE_COLUMN_LAST         % 目标类型--最后一行 
%% CONST_BATTLE_TARGET_TYPE_COLUMN_MAGIC        % 目标类型--最后一行的所有法系职业 
%% CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_1     % 目标类型--最后一行的随机1人 
%% CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_3     % 目标类型--最后两行的随机3人
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 选择战斗目标
target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) ->
	TargetSide2	= battle_mod_misc:convert_target_side(TargetSide, AtkSide),
	case battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx) of
		#unit{target = TargetList} when TargetList =/= [] ->
			{TargetSide2, TargetList};
		AtkUnit when is_record(AtkUnit, unit) ->
			case select(Battle, AtkSide, AtkIdx, TargetSide2, TargetType) of
				{TargetSide2, TargetList} ->
					battle_genius_skill:genius_skill_revise_target(Battle, {AtkSide, AtkIdx}, {TargetSide2, TargetList});
				?null -> ?null
			end;
		_ -> ?null
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 选择目标
%% CONST_BATTLE_TARGET_TYPE_SELF               % 目标类型--自己 
select(Battle, AtkSide, AtkIdx, _TargetSide, ?CONST_BATTLE_TARGET_TYPE_SELF) ->
	case battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx) of
		?null -> ?null;
		TargetUnit -> {AtkSide, [TargetUnit]}
	end;
%% CONST_BATTLE_TARGET_TYPE_SINGLE             % 目标类型--单体 
select(Battle, _AtkSide, AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_SINGLE) ->
	IdxList		= select_seq_default(AtkIdx),
	Count		= 1,
	case select_target(Battle, TargetSide, IdxList, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_NEIGHBOUR          % 目标类型--攻击目标相邻目标 
select(Battle, _AtkSide, AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_NEIGHBOUR) ->
	case default_target_idx(Battle, TargetSide, AtkIdx) of
		?null -> ?null;
		TargetIdx ->
			IdxList		= select_seq_neighbour(TargetIdx),
			Count		= 5,
			case select_target(Battle, TargetSide, [TargetIdx|IdxList], Count) of
				[] -> ?null;
				TargetList -> {TargetSide, TargetList}
			end
	end;
%% CONST_BATTLE_TARGET_TYPE_MIN_HP             % 目标类型--血量最少 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_MIN_HP) ->
	case battle_mod_misc:get_unit_min_hp(Battle, TargetSide) of
		?null -> ?null;
		TargetUnit -> {TargetSide, [TargetUnit]}
	end;
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_2             % 目标类型--血量最少2人
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_MIN_HP_2) ->
    Count = 2,
	case battle_mod_misc:get_unit_min_hp(Battle, TargetSide, Count) of
		[] -> 
            ?MSG_ERROR("1", []),
            ?null;
		TargetList -> 
            X2 = [X#unit.idx||X<-TargetList],
            ?MSG_ERROR("2[~p]", [X2]),
            {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_3             % 目标类型--血量最少3人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_MIN_HP_3) ->
    Count = 3,
	case battle_mod_misc:get_unit_min_hp(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_4             % 目标类型--血量最少4人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_MIN_HP_4) ->
    Count = 4,
	case battle_mod_misc:get_unit_min_hp(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_MIN_HP_5             % 目标类型--血量最少5人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_MIN_HP_5) ->
    Count = 5,
	case battle_mod_misc:get_unit_min_hp(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_MAX_MAGIC_ATTACK	% 目标类型--法术攻击力最大
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_MAX_MAGIC_ATTACK) ->
	case battle_mod_misc:get_unit_max_magic_attack(Battle, TargetSide) of
		?null -> ?null;
		TargetUnit -> {TargetSide, [TargetUnit]}
	end;
%% CONST_BATTLE_TARGET_TYPE_ALL                % 目标类型--全体 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ALL) ->
	case battle_mod_misc:get_unit_all(Battle, TargetSide) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_ALL_MAGIC          % 目标类型--全体法系职业 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ALL_MAGIC) -> 
	case battle_mod_misc:get_unit_all_magic(Battle, TargetSide) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_1       % 目标类型--敌方随机1人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_1) ->
	Count		= 1,
	case battle_mod_misc:get_unit_random(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_2       % 目标类型--敌方随机2人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_2) -> 
	Count		= 2,
	case battle_mod_misc:get_unit_random(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_3       % 目标类型--敌方随机3人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_3) -> 
	Count		= 3,
	case battle_mod_misc:get_unit_random(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_4       % 目标类型--敌方随机4人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_4) ->
	Count		= 4,
	case battle_mod_misc:get_unit_random(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_5       % 目标类型--敌方随机5人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_5) -> 
	Count		= 5,
	case battle_mod_misc:get_unit_random(Battle, TargetSide, Count) of
		[] -> ?null;
		TargetList -> {TargetSide, TargetList}
	end;
%% CONST_BATTLE_TARGET_TYPE_ROW                % 目标类型--攻击目标所在列 
select(Battle, _AtkSide, AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_ROW) -> 
	case default_target_idx(Battle, TargetSide, AtkIdx) of
		?null -> ?null;
		TargetIdx ->
			IdxList		= select_seq_column(TargetIdx),
			Count		= 3,
			case select_target(Battle, TargetSide, IdxList, Count) of
				[] -> ?null;
				TargetList ->
					{TargetSide, TargetList}
			end
	end;
%% CONST_BATTLE_TARGET_TYPE_COLUMN             % 目标类型--攻击目标所在行（最前排） 
select(Battle, _AtkSide, AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_COLUMN) ->
	case default_target_idx(Battle, TargetSide, AtkIdx) of
		?null -> ?null;
		TargetIdx ->
			IdxList		= select_seq_row(TargetIdx),
			Count		= 3,
			case select_target(Battle, TargetSide, IdxList, Count) of
				[] -> ?null;
				TargetList -> {TargetSide, TargetList}
			end
	end;
%% CONST_BATTLE_TARGET_TYPE_COLUMN_LAST        % 目标类型--最后一行 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_COLUMN_LAST) -> 
	case default_target_idx(Battle, TargetSide, 10) of
		?null -> ?null;
		TargetIdx ->
			IdxList		= select_seq_row(TargetIdx),
			Count		= 3,
			case select_target(Battle, TargetSide, IdxList, Count) of
				[] -> ?null;
				TargetList -> {TargetSide, TargetList}
			end
	end;
%% CONST_BATTLE_TARGET_TYPE_COLUMN_MAGIC       % 目标类型--最后一行的所有法系职业 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_COLUMN_MAGIC) ->
	case default_target_idx(Battle, TargetSide, 10) of
		?null -> ?null;
		TargetIdx ->
			IdxList		= select_seq_row(TargetIdx),
			Fun			= fun(Idx, AccUnit) ->
								  case battle_mod_misc:get_unit(Battle, TargetSide, Idx) of
									  Unit when is_record(Unit, unit) andalso
													Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
										  case battle_mod_misc:magic_pro(Unit#unit.pro) of
											  ?true -> [Unit|AccUnit];
											  ?false -> AccUnit
										  end;
									  _ -> AccUnit
								  end
						  end,
			case lists:foldl(Fun, [], IdxList) of
				[] -> ?null;
				TargetList -> {TargetSide, TargetList}
			end
	end;
%% CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_1    % 目标类型--最后一行的随机1人 
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_1) ->
    IdxList 	= select_seq_default(10),
	CountTemp	= 3,
	case select_target(Battle, TargetSide, IdxList, CountTemp) of
		[] -> ?null;
		TargetList ->
			ColumnLast	= get_last_column(TargetList),
			Fun			= fun(T, AccT) ->
								  Column	= (T#unit.idx - 1) div 3 + 1,
								  if Column =:= ColumnLast -> [T|AccT]; ?true -> AccT end
						  end,
			TargetList2	= lists:foldl(Fun, [], TargetList),
			Count		= 1,
			Len 		= length(TargetList2),
			TargetList3	= if Len > Count -> misc_random:random_list_norepeat(TargetList2, Count); ?true -> TargetList2 end,
			{TargetSide, TargetList3}
	end;
%% CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_3    % 目标类型--最后两行的随机3人
select(Battle, _AtkSide, _AtkIdx, TargetSide, ?CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_3) ->
    IdxList 	= select_seq_default(10),
	CountTemp	= 6,
	case select_target(Battle, TargetSide, IdxList, CountTemp) of
		[] -> ?null;
		TargetList ->
			ColumnLast	= get_last_column(TargetList),
			Fun			= fun(T, AccT) ->
								  Column	= (T#unit.idx - 1) div 3 + 1,
								  Diff		= abs(ColumnLast - Column),
								  if Diff =< 1 -> [T|AccT]; ?true -> AccT end
						  end,
			TargetList2	= lists:foldl(Fun, [], TargetList),
			Count		= 3,
			Len 		= length(TargetList2),
			TargetList3	= if Len > Count -> misc_random:random_list_norepeat(TargetList2, Count); ?true -> TargetList2 end,
			{TargetSide, TargetList3}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
select_target(Battle, Side, IdxList, Count) ->
	select_target(Battle, Side, IdxList, Count, 0, []).
select_target(Battle, Side, [Idx|IdxList], Count, AccCount, Acc) 
  when AccCount < Count ->
	case battle_mod_misc:get_unit(Battle, Side, Idx) of
		Unit when is_record(Unit, unit) andalso Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
			select_target(Battle, Side, IdxList, Count, AccCount + 1, [Unit|Acc]);
		_ -> select_target(Battle, Side, IdxList, Count, AccCount, Acc)
	end;
select_target(_Battle, _Side, [], _Count, _AccCount, Acc) -> lists:reverse(Acc);
select_target(_Battle, _Side, _IdxList, Count, AccCount, Acc)
  when AccCount >= Count -> lists:reverse(Acc).







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 校正目标
%% CONST_BATTLE_TARGET_TYPE_EXT_NEIGHBOUR	目标类型扩展--攻击目标相邻目标 -- 随机n个目标
revise_select(Battle, ?CONST_BATTLE_TARGET_TYPE_EXT_NEIGHBOUR, Count, {TargetSide, TargetList}) ->
	[TargetUnit|TargetListTemp]	= TargetList,
    IdxList     = misc_random:random_list_norepeat([1,2,3,4,5,6,7,8,9], 9),
    IdxList2    = lists:delete(TargetUnit#unit.idx, IdxList),     % 去掉已被选中的目标
	case select_target(Battle, TargetSide, IdxList2, Count) of
		[] -> {TargetSide, TargetList};
		TargetList2 ->
			Fun			= fun(TargetTemp, AccTargetList) ->
								  case lists:keymember(TargetTemp#unit.idx, #unit.idx, AccTargetList) of
									  ?true -> AccTargetList;
									  ?false -> [TargetTemp|AccTargetList]
								  end
						  end,
			TargetList3	= lists:foldl(Fun, TargetListTemp, TargetList2),
			{TargetSide, [TargetUnit|TargetList3]}
	end;
revise_select(_Battle, TargetType, Count, Target) ->
	?MSG_ERROR("ERROR TargetType:~p Count:~p", [TargetType, Count]),
	Target.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
default_target_idx(Battle, Side, Idx) ->
	IdxList	= select_seq_default(Idx),
	default_target_idx2(Battle, Side, IdxList).
default_target_idx2(Battle, Side, [Idx|IdxList]) ->
	case battle_mod_misc:get_unit(Battle, Side, Idx) of
		Unit when is_record(Unit, unit) andalso
				  Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
			Unit#unit.idx;
		_ -> default_target_idx2(Battle, Side, IdxList)
	end;
default_target_idx2(_Battle, _Side, []) -> ?null.

get_last_column(TargetList) ->
	lists:foldl(fun(X, AccColumnLast) ->
						ColumnT	= (X#unit.idx - 1) div 3 + 1,
						if ColumnT >= AccColumnLast -> ColumnT;
						   ?true -> AccColumnLast end
				end, 0, TargetList).
%%
%% Local Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 默认选取敌人序列
select_seq_default(0) -> [1, 2, 3, 4, 5, 6, 7, 8, 9];
select_seq_default(1) -> [1, 2, 3, 4, 5, 6, 7, 8, 9];
select_seq_default(2) -> [2, 1, 3, 5, 4, 6, 8, 7, 9];
select_seq_default(3) -> [3, 1, 2, 6, 4, 5, 9, 7, 8];
select_seq_default(4) -> [1, 2, 3, 4, 5, 6, 7, 8, 9];
select_seq_default(5) -> [2, 1, 3, 5, 4, 6, 8, 7, 9];
select_seq_default(6) -> [3, 1, 2, 6, 4, 5, 9, 7, 8];
select_seq_default(7) -> [1, 2, 3, 4, 5, 6, 7, 8, 9];
select_seq_default(8) -> [2, 1, 3, 5, 4, 6, 8, 7, 9];
select_seq_default(9) -> [3, 1, 2, 6, 4, 5, 9, 7, 8];
select_seq_default(?null) -> [];
select_seq_default(_) -> [9, 8, 7, 6, 5, 4, 3, 2, 1].

select_seq_neighbour(1) -> [2, 4];
select_seq_neighbour(2) -> [1, 3, 5];
select_seq_neighbour(3) -> [2, 6];
select_seq_neighbour(4) -> [1, 5, 7];
select_seq_neighbour(5) -> [2, 4, 6, 8];
select_seq_neighbour(6) -> [3, 5, 9];
select_seq_neighbour(7) -> [4, 8];
select_seq_neighbour(8) -> [5, 7, 9];
select_seq_neighbour(9) -> [6, 8];
select_seq_neighbour(?null) -> [].

select_seq_row(1) -> [1, 2, 3];
select_seq_row(2) -> [2, 1, 3];
select_seq_row(3) -> [3, 1, 2];
select_seq_row(4) -> [4, 5, 6];
select_seq_row(5) -> [5, 4, 6];
select_seq_row(6) -> [6, 4, 5];
select_seq_row(7) -> [7, 8, 9];
select_seq_row(8) -> [8, 7, 9];
select_seq_row(9) -> [9, 7, 8];
select_seq_row(?null) -> [].

select_seq_column(1) -> [1, 4, 7];
select_seq_column(2) -> [2, 5, 8];
select_seq_column(3) -> [3, 6, 9];
select_seq_column(4) -> [1, 4, 7];
select_seq_column(5) -> [2, 5, 8];
select_seq_column(6) -> [3, 6, 9];
select_seq_column(7) -> [1, 4, 7];
select_seq_column(8) -> [2, 5, 8];
select_seq_column(9) -> [3, 6, 9];
select_seq_column(?null) -> [].

get_row(1) -> 1;
get_row(2) -> 1;
get_row(3) -> 1;
get_row(4) -> 2;
get_row(5) -> 2;
get_row(6) -> 2;
get_row(7) -> 3;
get_row(8) -> 3;
get_row(9) -> 3.

get_column(1) -> 1;
get_column(2) -> 2;
get_column(3) -> 3;
get_column(4) -> 1;
get_column(5) -> 2;
get_column(6) -> 3;
get_column(7) -> 1;
get_column(8) -> 2;
get_column(9) -> 3.
