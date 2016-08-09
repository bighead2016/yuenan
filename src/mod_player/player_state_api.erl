%%% 状态处理
%%% 天下3分，
%%%    1.玩家状态:玩家身上的状态，关系到玩家的各种逻辑处理。
%%%    2.玩法状态:在哪种玩法中，各玩法直接互斥，只能通过中立场景转换。
%%%    3.特殊状态:这种状态是完全通用，无任何状态排斥性的状态，所以要特殊处理。
%%% 注意：
%%%    无状态排斥性并不意味着他能无限转，无规则转。相反，这特殊状态的转换处理更加细致，一般与地图、玩法有密切关系。
%%%  由于特殊状态破坏了玩家、玩法状态各自的封装性，所以最好尽量不要定义这种状态。一定要注意!

-module(player_state_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([get_state/1, try_set_state/2, try_set_state_play/2, set_state/3, is_raiding/1,
         read_play_state_tips/1, is_fighting/1, is_doing/2, is_death/1]).

%%
%% API Functions
%%
get_state(Player) ->
    UserState = Player#player.user_state, 
    PracState = Player#player.practice_state, 
    PlayState = Player#player.play_state,
    case {UserState, PlayState} of
        {X, Y} when X =< 0 orelse Y < 0 ->
            {?CONST_PLAYER_STATE_NORMAL, ?CONST_PLAYER_STATE_NORMAL, ?CONST_PLAYER_PLAY_CITY};
        {State, StatePlay} ->
            {State, PracState, StatePlay}
    end.

%% 改变玩家状态
%% 1.修炼状态单独处理
%% 2.玩家状态只作单纯战斗过滤
try_set_state(Player, ?CONST_PLAYER_STATE_SINGLE_PRACTISE = NewState) -> % -> 单修
    {State, PracState, _StatePlay} =  get_state(Player),
    CanChange = 
        if
            ?CONST_PLAYER_STATE_SINGLE_PRACTISE =:= PracState -> % 单修->单修
                ?true;
            ?CONST_PLAYER_STATE_DOUBLE_PRACTISE =:= PracState -> % 双修->单修
                ?true;
            ?CONST_PLAYER_STATE_NORMAL =:= State -> % 正常
                ?true;
            ?true ->
                ?false
        end,
    if
        ?true =:= CanChange ->
            NewPlayer = Player#player{practice_state = NewState},
            map_api:change_user_state(NewPlayer),
            {?true, NewPlayer};
        ?true ->
            {?false, Player}
    end;
try_set_state(Player, ?CONST_PLAYER_STATE_DOUBLE_PRACTISE = NewState) -> % -> 双修
    {State, PracState, _StatePlay} =  get_state(Player),
    CanChange = 
        if
            ?CONST_PLAYER_STATE_SINGLE_PRACTISE =:= PracState -> % 单修->双修
                ?true;
            ?CONST_PLAYER_STATE_DOUBLE_PRACTISE =:= PracState -> % 双修->双修
                ?true;
            ?CONST_PLAYER_STATE_NORMAL =:= State -> % 正常
                ?true;
            ?true ->
                ?false
        end,
    if
        ?true =:= CanChange ->
            NewPlayer = Player#player{practice_state = NewState},
            map_api:change_user_state(NewPlayer),
            {?true, NewPlayer};
        ?true ->
            {?false, Player}
    end;
try_set_state(Player, NewState) -> % -> 其他
    {State, _PracState, StatePlay} =  get_state(Player),
%%     ?MSG_ERROR("xxxxxxxxxxxxxxxxxxxxx[~p]", [{State, PracState, StatePlay, NewState, map_api:get_map_player(Player#player.user_id)}]),
    case can_change(State, NewState) of
        ?CONST_SYS_TRUE ->
            IsPraticing = ets_api:lookup(?CONST_ETS_PRACTICE, Player#player.user_id),
            if
                ?CONST_PLAYER_PLAY_CITY =/= StatePlay -> % 非中立地图
                    if
                        ?null =/= IsPraticing ->
                            practice_api:cancel(Player);
                        ?true ->
                            ?ok
                    end,
                    NewPlayer = Player#player{user_state = NewState, practice_state = ?CONST_PLAYER_STATE_NORMAL},
                    map_api:change_user_state(NewPlayer),
                    {?true, NewPlayer};
                ?null =:= IsPraticing -> % 中立地图，非修炼中
                    NewPlayer = Player#player{user_state = NewState},
                    map_api:change_user_state(NewPlayer),
                    {?true, NewPlayer};
                ?null =/= IsPraticing 
                  andalso ((State =:= ?CONST_PLAYER_STATE_FIGHTING andalso NewState =:= ?CONST_PLAYER_STATE_NORMAL)
                            orelse NewState =:= ?CONST_PLAYER_STATE_FIGHTING
                           ) ->
                    NewPlayer = Player#player{user_state = NewState},
                    {?true, NewPlayer};
                ?null =/= IsPraticing ->
                    practice_api:cancel(Player),
                    NewPlayer = Player#player{user_state = NewState, practice_state = ?CONST_PLAYER_STATE_NORMAL},
                    map_api:change_user_state(NewPlayer),
                    {?true, NewPlayer};
                ?true ->
                    NewPlayer = Player#player{user_state = NewState},
                    {?true, NewPlayer}
            end;
        ?CONST_SYS_FALSE ->
            {?false, Player}
    end.

%% 改变玩家玩法状态
try_set_state_play(Player, NewPlayState) ->
    {_State, _, PlayState} = get_state(Player),
    case NewPlayState of
        ?CONST_PLAYER_PLAY_SINGLE_COPY when ?CONST_PLAYER_PLAY_SINGLE_COPY =:= PlayState ->
            {?false, Player, ?TIP_COPY_SINGLE_ALREADY_IN};
        PlayState ->
            {?true, Player};
        ?CONST_PLAYER_PLAY_CITY ->
            NewPlayer = Player#player{play_state  = NewPlayState},
            {?true, NewPlayer};
        _ ->
            can_change(NewPlayState, PlayState, Player)
    end.    

%% 玩法状态
can_change(NewPlayState, OldPlayState, Player) when is_record(Player, player) ->
    UserId = Player#player.user_id,
    case is_raiding(UserId) of
        ?true ->
            case lists:member(NewPlayState, ?CONST_PLAYER_LIST_RAID_CAN_CHANGE) of
                ?true ->
                    Player2 = Player#player{play_state = NewPlayState},
                    {?true, Player2};
                ?false ->
                    {?false, Player, ?TIP_COMMON_NOT_4_RAIDING}
            end;
        ?false ->
            if
                ?CONST_PLAYER_PLAY_CITY =:= OldPlayState -> % 不在扫荡，同时在中立场景中
                    Player3 = Player#player{play_state  = NewPlayState},
                    {?true, Player3};
                ?true ->
					case data_player:get_player_play_state({NewPlayState, OldPlayState}) of
						?CONST_SYS_TRUE ->
							Player3 = Player#player{play_state  = NewPlayState},
							{?true, Player3};
						?CONST_SYS_FALSE ->
                            Tips = read_play_state_tips(OldPlayState),
							{?false, Player, Tips};
                        _ ->
                            Player3 = Player#player{play_state  = NewPlayState},
                            {?true, Player3}
					end
            end
      end.

%% 角色状态
can_change(State1, State2) ->
    data_player:get_player_state({State1, State2}).


%% 定时改变玩家状态
set_state(Player, NewState, TimeStamp) ->
	Now = misc:seconds(),
	case Now >= TimeStamp of
		?true ->
			case player_state_api:try_set_state(Player, NewState) of
				{?true, NewPlayer} ->
					NewPlayer;
				{?false, Player} ->
					Player
			end;
		?false ->
			erlang:send_after(1000, self(), {set_state, NewState, TimeStamp}),
			Player
    end.

%% 扫荡中?
is_raiding(UserId) ->
    case ets_api:lookup(?CONST_ETS_RAID_PLAYER, UserId) of
        ?null ->
            case ets_api:lookup(?CONST_ETS_RAID_ELITE_PLAYER, UserId) of
                ?null ->
                    ?false;
                _ ->
                    ?true
            end;
        _ ->
            ?true
    end.

%% 战斗中?
is_fighting(#player{user_state = ?CONST_PLAYER_STATE_FIGHTING}) -> ?true;
is_fighting(_)                                                  -> ?false.

%% 挂了?
is_death(#player{user_state = ?CONST_PLAYER_STATE_DEATH}) -> ?true;
is_death(_)                                               -> ?false.

%% 某玩法中?
is_doing(#player{play_state = PlayState}, PlayState) -> ?true;
is_doing(_, _)                                       -> ?false.

%% 读取玩法对应的tips
read_play_state_tips(?CONST_PLAYER_PLAY_BOSS) -> ?TIP_PLAYER_PLAY_STATE_BOSS;
read_play_state_tips(?CONST_PLAYER_PLAY_INVASION) -> ?TIP_PLAYER_PLAY_STATE_INVASION;
read_play_state_tips(?CONST_PLAYER_PLAY_SPRING) -> ?TIP_PLAYER_PLAY_STATE_SPRING;
read_play_state_tips(?CONST_PLAYER_PLAY_MULTI_ARENA) -> ?TIP_PLAYER_PLAY_STATE_ARENA_PVP;
read_play_state_tips(?CONST_PLAYER_PLAY_PARTY) -> ?TIP_PLAYER_PLAY_STATE_GUILD_PARTY;
read_play_state_tips(_) -> ?TIP_PLAYER_PLAY_STATE_CONFLICT.

%%
%% Local Functions
%%
%% 
%% info{
%%     state = 单修   双修  正常  战斗  死亡  惩罚,
%%     state_play = '温泉'...,
%%     ...
%% }
