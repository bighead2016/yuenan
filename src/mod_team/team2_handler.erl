%%% 多人组队协议收发
%%% 1.请求进入大厅在各自的模块中定义协议
-module(team2_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 请求创建队伍
handler(?MSG_ID_TEAM2_CS_CREAT, Player, {Id}) ->
	case team_api:create(Player, Id) of
        {?ok, Player2} -> {?ok, Player2};
        {?error, ErrorCode} ->
			{?error, ErrorCode}
    end;
%% 请求加入队伍
handler(?MSG_ID_TEAM2_CS_JOIN, Player, {TeamId, Password}) ->
	case team_api:join(Player, TeamId, Password) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end;
%% 请求移除队伍成员
handler(?MSG_ID_TEAM2_CS_REMOVE, Player, {TUserId}) ->
	case team_api:remove(Player, TUserId) of
		{?ok, Player2} -> {?ok, Player2};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
%% 请求退出队伍
handler(?MSG_ID_TEAM2_CS_QUIT, Player, {}) ->
    team_api:quit(Player);

%% 请求更换队长
handler(?MSG_ID_TEAM2_CS_CHANGE_LEADER, Player, {NewLeaderUserId}) ->
	case team_api:change_leader(Player, NewLeaderUserId) of
        {?error, ErrorCode} ->
            {?error, ErrorCode};
        _ -> ?ok
    end;

%% 请求邀请角色
handler(?MSG_ID_TEAM2_CS_INVITE, Player, {UserId}) ->
    case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, Player#player.user_id) of
        [] ->
        	case team_api:invite(Player, UserId) of
                {?error, ErrorCode} -> {?error, ErrorCode};
                _ -> ?ok
            end;
        _ ->
            camp_pvp_api:invite(Player, UserId)
    end;

handler(?MSG_ID_TEAM2_CS_REPLY, Player, {?CONST_TEAM_TYPE_CAMP_PVP,TeamId,Decide}) ->
   case camp_pvp_api:reply_team(Player, TeamId, Decide) of
       {ok, Player2} ->
           {ok, Player2};
       _ ->
           {ok, Player}
   end;

%% 回复组队邀请
handler(?MSG_ID_TEAM2_CS_REPLY, Player, {TeamType,TeamId,Decide}) ->
	case team_api:reply(Player, TeamType, TeamId, Decide) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;

%% 队伍成员准备请求
handler(?MSG_ID_TEAM2_CS_SET_MEMBER_STATE, Player, {Type}) ->
	State	= case Type of
				  ?CONST_SYS_TRUE -> ?CONST_TEAM_PLAYER_STATE_WAIT;
				  ?CONST_SYS_FALSE -> ?CONST_TEAM_PLAYER_STATE_READY
			  end,
	team_api:set_member_state(Player, State);

%% 设置阵型
handler(?MSG_ID_TEAM2_CS_SET_CAMP, Player, {CampId}) ->
	case team_api:set_camp(Player, CampId) of
        {?error, ErrorCode} -> {?error, ErrorCode};
        _ -> ?ok
    end;

%% 设置阵型站位
handler(?MSG_ID_TEAM2_CS_SET_CAMP_POS, Player, {IdxFrom,IdxTo}) ->
	case team_api:set_camp_pos(Player, IdxFrom, IdxTo) of
        ?ok -> ?ok;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end;

%% 自动加入
handler(?MSG_ID_TEAM2_CS_AUTOJOIN, Player, {CopyId}) ->
    case team_api:auto_join(Player, CopyId) of
        {?ok, Player2} -> {?ok, Player2};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end;

%% 请求退出大厅
handler(?MSG_ID_TEAM2_CS_QUIT_HALL, Player, {}) ->
	case team_api:quit_hall(Player) of
		{?error, ErrorCode}	-> {?error, ErrorCode};
		{?ok, NewPlayer}	-> {?ok, NewPlayer}
	end;

%% 快速加入
handler(?MSG_ID_TEAM2_CS_QUICK_JOIN, Player, {TeamType, TeamId, Id, Password}) ->
	case team_api:quick_join(Player, TeamType, TeamId, Id, Password) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;

%% 队伍加锁解锁
handler(?MSG_ID_TEAM2_CS_LOCK_UNLOCK, Player, {Password}) ->
	case team_api:lock_and_unlock(Player, Password) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;

handler(?MSG_ID_TEAM2_CS_CHANGE_COPY2, Player, {Id}) ->
    case team_api:change_team(Player, Id) of
        ?ok -> ?ok;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end;

handler(?MSG_ID_TEAM2_AUTHOR_LIST, Player, {Type}) ->
    team_api:get_author_list(Player, Type),
    {?ok, Player};


%% 请求可邀请的替身列表
handler(?MSG_ID_TEAM2_CS_INVITE_AUTHOR, Player, {_TeamType}) ->
    team_api:get_invite_author_list(Player),
    {?ok, Player};
%% 设置授权列表
%% 设置授权列表
handler(?MSG_ID_TEAM2_CS_SET_AUTHOR_LIST, Player, {UserId,IsChoose,TeamType}) ->
    NewPlayer = team_api:set_author_list(Player, UserId, TeamType, IsChoose),
    {?ok, NewPlayer};


%% 邀请替身
handler(?MSG_ID_TEAM2_INVITE_AUTHOR, Player, {UserId}) ->
    team_api:invite2(Player, UserId),
    {?ok, Player};

%% 请求元宝雇佣信
handler(?MSG_ID_TEAM2_GOLD_HIRE, Player, {}) ->
    team_api:get_gold_hire_list(Player),
    {?ok, Player};
%% 元宝雇佣
handler(?MSG_ID_TEAM2_GOLD_HIRE_INVITE, Player, {UserId}) ->
    team_api:gold_invite(Player, UserId),
    {?ok, Player};
%% 快速跨服加入
handler(?MSG_ID_TEAM2_CS_QUICK_JOIN_CROSS, Player, {_TeamType,ServId,TeamId,_Id,Pass}) ->
    case team_api:cross_join(Player, {TeamId, ServId}, Pass) of
        {ok, Player2} ->
            {ok, Player2};
        {?error, ErrorCode} ->
            misc_packet:send_tips(Player#player.user_id, ErrorCode),
            {ok, Player};
        _ ->
            {ok, Player}
    end;
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	?error.
%%
%% Local Functions
%%
