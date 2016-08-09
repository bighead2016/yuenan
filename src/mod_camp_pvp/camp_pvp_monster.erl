%%% -------------------------------------------------------------------
%%% Author  : PXR
%%% Description :
%%%
%%% Created : 2013-7-8
%%% -------------------------------------------------------------------
-module(camp_pvp_monster).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/3, check_and_set_state/1, monster_killed/1, battle_over/3, 
         get_attack_target/1, get_walk_point/2, camp_pvp_end/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(CONST_CAMP_PVP_MONSTER_WALK_INTERVAL, 3).
%% ====================================================================
%% External functions
%% ====================================================================

start_link(ServerName, _, Monster) ->
    gen_server:start_link({local, ServerName}, ?MODULE, [Monster], []).

camp_pvp_end() ->
    MonsterList = ets:tab2list(?CONST_ETS_CAMP_PVP_MONSTER),
    Fun =
        fun(Monster) ->
            case Monster#camp_pvp_monster.monster_pid of
                undefined ->
                    ok;
                PidName -> 
                    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, Monster#camp_pvp_monster.monster_id,
                                       {#camp_pvp_monster.state, ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}),
                    gen_server:cast(PidName, camp_pvp_end)
            end
        end,
    lists:foreach(Fun, MonsterList).

% 玩家v怪的战斗胜利的回调
battle_over(MonsterId, Hp2, NewHp) ->
    gen_server:cast(get_monster_pid(MonsterId), {battle_over, MonsterId, Hp2, NewHp}).
% 玩家v怪的战斗失败的回调
monster_killed(MonsterId) ->
    gen_server:cast(get_monster_pid(MonsterId), {monster_killed, MonsterId}).
% 玩家v怪的战斗开始检查、同步状态
check_and_set_state(MonsterId) ->
    Pid = get_monster_pid(MonsterId),
    ?MSG_DEBUG("MonsterId is ~w, Pid is ~w", [MonsterId, Pid]),
    case erlang:is_pid(Pid) andalso erlang:is_process_alive(Pid) of
        true ->
            gen_server:call(get_monster_pid(MonsterId), check_and_set_state);
        false ->
            {false, ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}
    end.
%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([Monster]) ->
    ?MSG_DEBUG("name ~w init ,feel good, pid is ~w,hoho~~", [Monster#camp_pvp_monster.monster_id, self()]),
    erlang:send_after(1000 * ?CONST_CAMP_PVP_MONSTER_WALK_INTERVAL, self(), check_target),
    {ok, Monster#camp_pvp_monster.monster_id}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_call(check_and_set_state, _From, MonsterId) ->
    MonsterRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId),
    case MonsterRec#camp_pvp_monster.state of
        ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
            Reply = {false, ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}; 
        ?CONST_CAMP_PVP_MONSTER_STATE_BATTLE ->
            Reply = {false, ?CONST_CAMP_PVP_MONSTER_STATE_BATTLE};
        ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL ->
            ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId,
                                {#camp_pvp_monster.state,?CONST_CAMP_PVP_MONSTER_STATE_BATTLE}),
            Reply = {ok, [], MonsterRec#camp_pvp_monster.hp_tuple}
    end,
    ?MSG_DEBUG("Reply is ~w", [Reply]),
    {reply, Reply, MonsterId};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast(camp_pvp_end, State) ->
    {stop, normal, State};

handle_cast({battle_over, MonsterId, Hp2, NewHp}, State) ->
    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, 
                       [{#camp_pvp_monster.state, ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL},
                        {#camp_pvp_monster.hp, NewHp},
                        {#camp_pvp_monster.hp_tuple, Hp2}]),
    camp_pvp_mod:broad_monster_hp(MonsterId),
    {noreply, State};

handle_cast({monster_killed, MonsterId}, State) ->
    ?MSG_DEBUG("Monster ~w killed", [MonsterId]),
    Packet = camp_pvp_msg:msg_monster_killed(MonsterId),
    camp_pvp_mod:broad_map(Packet, MonsterId div ?CONST_SYS_NUM_MILLION),
    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.state,
                                                                 ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}),
    {stop, normal, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(check_target, MonsterId) ->
    ?MSG_ERROR("MonsterId is ~w", [MonsterId]),
     Monster = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId),
    ?MSG_ERROR("Monster is ~w", [Monster]),
     RoomId = MonsterId div ?CONST_SYS_NUM_MILLION,
     MonsterId1 = MonsterId rem ?CONST_SYS_NUM_MILLION,
     ?MSG_DEBUG("MonsterId is ~w, Monster is ~w", [MonsterId, Monster#camp_pvp_monster.walkPoint]),
     case Monster#camp_pvp_monster.walkPoint of
         [Point] ->
             case check_boss_alive(MonsterId) of
                 false ->
                      MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterId1),
                      {BornX,_BornY} =  MonsterConfig#rec_camp_pvp_monster.born_point,
                      {TargetX,_} =  MonsterConfig#rec_camp_pvp_monster.target_point,
                      [EndX] = [TargetX, BornX] -- [Point],
                      WalkPoint = camp_pvp_monster:get_walk_point(Point, EndX),
                      ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.walkPoint, WalkPoint}),
                      erlang:send_after(1000 * ?CONST_CAMP_PVP_MONSTER_WALK_INTERVAL, self(), check_target),
                      {noreply, MonsterId};
                 true ->
                     ?MSG_DEBUG("{~w}for the new china ,!!!!!", [MonsterId]),
                     Packet = camp_pvp_msg:msg_monster_killed(MonsterId1),
                     camp_pvp_mod:broad_map(Packet, RoomId),
                     ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.state,
                                                                         ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}),
                     attack_boss(Monster),
                     {stop, normal, MonsterId}
             end;
         _ ->
             case Monster#camp_pvp_monster.state of
                 ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL ->
                     Y = Monster#camp_pvp_monster.born_point_y,
                    {WalkPoint1, Packet} = camp_pvp_mod:monster_package(MonsterId, Monster#camp_pvp_monster.walkPoint, Y),
                    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.walkPoint, WalkPoint1}),
                    camp_pvp_mod:broad_map(Packet, RoomId);
                 _ ->
                    ok
             end,
             erlang:send_after(1000 * ?CONST_CAMP_PVP_MONSTER_WALK_INTERVAL, self(), check_target),
             {noreply, MonsterId}
     end;
     

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, #camp_pvp_monster{monster_id = Id, state = State}) ->
    ?MSG_DEBUG("monster ~w process terminate for Reason: ~w,its state is ~w", [Id, Reason , State]),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
    

attack_boss(Monster) ->
    BossId = get_attack_target(Monster#camp_pvp_monster.monster_id),
    camp_pvp_serv:attack_boss(Monster, BossId).


get_monster_pid(MonsterId) ->
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
        ?null ->
            undefined;
        Record ->
            erlang:whereis(Record#camp_pvp_monster.monster_pid)
    end.
    
% 找自爆攻击的大将军目标：y 坐标相同
get_attack_target(MonsterId) -> 
    MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterId rem ?CONST_SYS_NUM_MILLION),
    CampId = MonsterConfig#rec_camp_pvp_monster.camp,
    {_X, Y} = MonsterConfig#rec_camp_pvp_monster.born_point,
    MonsterList = ets:tab2list(?CONST_ETS_CAMP_PVP_MONSTER),
    get_attack_target({MonsterId, CampId}, Y, MonsterList).
get_attack_target(_, _, []) ->
    0;
get_attack_target({MonsterId, CampId}, Y, [MonsterRec|RestMonsterList]) ->
    MonsterId1 = MonsterRec#camp_pvp_monster.monster_id,
    MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterId1 rem ?CONST_SYS_NUM_MILLION),
    CampId1 = MonsterConfig#rec_camp_pvp_monster.camp,
    Harm = MonsterConfig#rec_camp_pvp_monster.harm,
    case MonsterConfig#rec_camp_pvp_monster.born_point of
        {_, Y} when CampId /= CampId1 , Harm == 0 ->
            MonsterId1;
        _ ->
            get_attack_target({MonsterId, CampId}, Y, RestMonsterList)
    end.

get_walk_point(BornX, TargetX) ->
    WalkPart = (TargetX - BornX) div 10 ,
    get_walk_point(BornX, TargetX, WalkPart, []).
get_walk_point(X, TargetX, WalkPart, Path) ->
    io:format("X is ~w, NewX is ~w ,Tagetx is ~w~n", [X, X + WalkPart, TargetX]),
    case (X - TargetX) * (X + WalkPart - TargetX) =< 0 of
        true ->
            lists:reverse([TargetX, X|Path]);
        false ->
            get_walk_point(X + WalkPart, TargetX, WalkPart, [X|Path])
    end.

check_boss_alive(MonsterId) ->
    BossId = get_attack_target(MonsterId),
    case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, BossId) of
        [] ->
            false;
        [MonsterRec] ->
            MonsterRec#camp_pvp_monster.state /= ?CONST_CAMP_PVP_MONSTER_STATE_DEAD
    end.