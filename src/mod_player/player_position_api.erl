%% Author: cobain
%% Created: 2012-8-15
%% Description: TODO: Add description to player_position
-module(player_position_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([creat/1, current_position/1, position_info/1, upgrade/2, salary_info/1, 
         refresh_attr/1, open_position/1]).

%%
%% API Functions
%%
creat(PositionId) ->
	#position_data{
				   position			= PositionId,	% 当前官衔ID
				   date				= 0				% 领取俸禄日期
				  }.

%% 请求当前官衔
current_position(Player) ->
	PositionData	= Player#player.position,
	PositionData#position_data.position.

%% 请求官衔信息
position_info(Player)	->
	Info				= Player#player.info,
	TotalMeritorious	= Info#info.meritorioust,
	Packet				= player_api:msg_player_sc_position_info(TotalMeritorious),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok.

read(PositionId) ->
    data_player:get_player_position(PositionId).

open_position(Player) ->
    PositionData = Player#player.position,
    if
        PositionData#position_data.position > 1 ->
            {?ok, Player};
        ?true ->
            UserId = Player#player.user_id,
            NextPositionId = 1,
            case read(NextPositionId) of
                ?null ->
                    {?ok, Player};
                PositionNext ->
                    {?ok, Player2}  = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_POSITION, NextPositionId, 1),
                    {?ok, Player3}  = upgrade_position_for_task(Player2, PositionNext#player_position.task_id, 0),
                    PositionData2   = PositionData#position_data{position = NextPositionId},
                    NewPlayer2      = Player3#player{position = PositionData2},
                    NewPlayer3      = player_attr_api:refresh_attr_position(NewPlayer2),
                    NewPlayer4      = partner_api:partner_position_up(NewPlayer3),
                    {?ok, NewPlayer5} = task_api:update_position(NewPlayer4, NextPositionId),
                    UpgradePacket   = player_api:msg_player_sc_upgrade(NextPositionId),
                    UPgradePacket2  = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_POSITION, NextPositionId),
                    NewPacket       = <<UpgradePacket/binary, UPgradePacket2/binary>>,
                    misc_packet:send(UserId, NewPacket),
                    map_api:open_position(NewPlayer5),
                    {?ok, NewPlayer5}
            end
%%             open_inner(Player);
    end.
%% open_inner(Player) -> % 这样处理是为了减少发包量
%%     UserId          = Player#player.user_id,
%%     Info            = Player#player.info,
%%     PositionData    = Player#player.position,
%%     Meritorioust    = Info#info.meritorioust,
%%     PositionId      = PositionData#position_data.position,
%%     Position        = read(PositionId), 
%%     PositionIdNext  = Position#player_position.next_id,
%%     case read(PositionIdNext) of
%%         ?null ->
%%             {?ok, Player};
%%         PositionNext ->
%%             NextMeritorious = PositionNext#player_position.meritorious,
%%             {NewPlayer, NewPacket, NewPositionId} = 
%%                 if
%%                     Meritorioust >= NextMeritorious -> % 跳级了
%%                         {?ok, Player2}  = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_POSITION, PositionIdNext, 1),
%%                         {?ok, Player3}  = upgrade_position_for_task(Player2, PositionNext#player_position.task_id, PositionIdNext),
%%                         {?ok, Player4}  = task_api:update_position(Player3, PositionIdNext),
%%                         UpgradePacket   = player_api:msg_player_sc_upgrade(PositionIdNext),
%%                         UPgradePacket2  = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_POSITION, PositionIdNext),
%%                         TotalPacket     = <<UpgradePacket/binary, UPgradePacket2/binary>>,
%%                         {Player5, Packet4, PositionIdNext2} = upgrade_inner(Player4, TotalPacket, PositionIdNext),
%%                         {Player5, Packet4, PositionIdNext2};
%%                     ?true -> % 没升级
%%                         UpgradePacket   = player_api:msg_player_sc_upgrade(PositionId),
%%                         UPgradePacket2  = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_POSITION, PositionId),
%%                         {Player, <<UpgradePacket/binary, UPgradePacket2/binary>>, PositionId}
%%                 end,
%%             PositionData2   = PositionData#position_data{position = NewPositionId},
%%             NewPlayer2      = NewPlayer#player{position = PositionData2},
%%             NewPlayer3      = player_attr_api:refresh_attr_position(NewPlayer2),
%%             NewPlayer4      = partner_api:partner_position_up(NewPlayer3),
%%             misc_packet:send(UserId, NewPacket),
%%             map_api:open_position(NewPlayer4),
%%             {?ok, NewPlayer4}
%%     end.
%% 
%% upgrade_inner(Player, TotalPacket, PositionId) ->
%%     Info            = Player#player.info,
%%     Meritorioust    = Info#info.meritorioust,
%%     Position        = read(PositionId), 
%%     PositionIdNext  = Position#player_position.next_id,
%%     case read(PositionIdNext) of
%%         ?null ->
%%             {Player, TotalPacket, PositionId};
%%         PositionNext ->
%%             NextMeritorious = PositionNext#player_position.meritorious,
%%             if
%%                 Meritorioust >= NextMeritorious ->
%%                     {?ok, Player2}  = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_POSITION, PositionIdNext, 1),
%%                     {?ok, Player3}  = upgrade_position_for_task(Player2, PositionNext#player_position.task_id, PositionIdNext),
%%                     {?ok, Player4}  = task_api:update_position(Player3, PositionIdNext),
%%                     UpgradePacket   = player_api:msg_player_sc_upgrade(PositionIdNext),
%%                     UPgradePacket2  = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_POSITION, PositionIdNext),
%%                     TotalPacket2    = <<TotalPacket/binary, UpgradePacket/binary, UPgradePacket2/binary>>,
%%                     {Player5, Packet4, PositionIdNext2} = upgrade_inner(Player4, TotalPacket2, PositionIdNext),
%%                     {Player5, Packet4, PositionIdNext2};
%%                 ?true ->
%%                     {Player, TotalPacket, PositionId}
%%             end
%%     end.

%% 官衔升级
%% 这个处理时有可能会出现多次升级的情况
upgrade(Player, UpPositionId)  ->
    case player_sys_api:is_open_sys(Player, ?CONST_MODULE_POSITION) of
        ?true ->
			{?ok, Player2} = upgrade_inner(Player, UpPositionId),
			team_api:update_team_player(Player2),
			{?ok, Player2};
        ?false -> {?ok, Player}
    end.
upgrade_inner(Player, UpPositionId) ->
	Info			= Player#player.info,
	PositionData	= Player#player.position,
	Meritorioust	= Info#info.meritorioust,
	PositionId		= PositionData#position_data.position,
	Position		= read(PositionId), 
	PositionIdNext	= Position#player_position.next_id,
	case UpPositionId >= PositionIdNext of
		?true ->
			case read(PositionIdNext) of
		        ?null ->
		            {?ok, Player};
		        PositionNext ->
		            NextMeritorious = PositionNext#player_position.meritorious,
		        	if
		        		Meritorioust >= NextMeritorious ->
		        			PositionData2	= PositionData#position_data{position = PositionIdNext},
		        			Player2			= Player#player{position = PositionData2},
		        			Player3			= player_attr_api:refresh_attr_position(Player2),
		        			Player4			= partner_api:partner_position_up(Player3),
		        			{?ok, Player5}	= achievement_api:add_achievement(Player4, ?CONST_ACHIEVEMENT_POSITION, PositionIdNext, 1),
		        			{?ok, Player6}	= upgrade_position_for_task(Player5, PositionNext#player_position.task_id, PositionIdNext),
%% 		                    {?ok, Player7}	= new_serv_api:finish_achieve(Player6, ?CONST_NEW_SERV_POSITION, PositionIdNext, 1),
                            {?ok, Player8}  = task_api:update_position(Player6, PositionIdNext),
							UpgradePacket   = player_api:msg_player_sc_upgrade(PositionIdNext),
		                    UPgradePacket2  = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_POSITION, PositionIdNext),
		        			misc_packet:send(Player8#player.net_pid, <<UpgradePacket/binary, UPgradePacket2/binary>>),
		        			map_api:change_position(Player8),
                            schedule_power_api:do_upgrade_position(Player8),
		        			upgrade_inner(Player8, UpPositionId);
		        		?true -> {?ok, Player}% 阅历不足
		        	end
		    end;
		?false ->
			{?ok, Player}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   俸禄信息
%% @name   salary_info/1
%% @dep    
%% @param  Player					玩家信息
%% @return FlagSalary				是否领取
%% @return Salary					俸禄
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
salary_info(Player) ->
	PositionData	= Player#player.position,
	Today			= misc:date_num(),
	FlagSalary		= case PositionData#position_data.date of
						  Today -> ?true; _ -> ?false
					  end,
	PositionId		= PositionData#position_data.position,
	Position		= data_player:get_player_position(PositionId),
	Salary			= Position#player_position.salary,
	{FlagSalary, Salary}.

%% 任务更新官衔
upgrade_position_for_task(Player, 0, _PositionIdNext) -> {?ok, Player};
upgrade_position_for_task(Player, TaskList, PositionIdNext) when is_list(TaskList) ->
    TaskList2 = lists:reverse(TaskList),
    Player2 = task_api:upgrade_position(Player, TaskList2, PositionIdNext),
    {?ok, Player2};
upgrade_position_for_task(Player, TaskId, PositionIdNext) ->
	Player2	= task_api:upgrade_position(Player, TaskId, PositionIdNext),
	{?ok, Player2}.
%% 
refresh_attr(PositionData)
  when is_record(PositionData, position_data) ->
	PositionId		= PositionData#position_data.position,
	Position		= data_player:get_player_position(PositionId),
	Position#player_position.attr;
refresh_attr(PositionData) ->
	?MSG_ERROR("PositionData:~p~n", [PositionData]),
	player_attr_api:record_attr().
%%
%% Local Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 领取俸禄
%% salary(Player) ->
%%  Today           = misc:date_num(),
%%  PositionData    = Player#player.position,
%%  case PositionData#position_data.date of
%%      Today ->% 今天已经领取俸禄
%%          {?ok, Player};
%%      _ ->
%%          PositionId      = PositionData#position_data.position,
%%          Position        = data_player:get_player_position(PositionId),
%%          case player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, Position#player_position.salary, 0) of
%%              ?ok ->
%%                  PositionData2   = PositionData#position_data{date = Today},
%%                  Player2         = Player#player{position = PositionData2},
%%                  FlagSalary      = case PositionData2#position_data.date of
%%                                        Today -> ?true; _ -> ?false
%%                                    end,
%%                    Packet           = 
%%                      case player_sys_api:is_open_sys(Player2, ?CONST_MODULE_POSITION) of
%%                          ?true   ->
%%                              player_api:msg_player_sc_position_info(PositionId, FlagSalary);
%%                             ?false   ->
%%                              player_api:msg_player_sc_position_info(0, FlagSalary)
%%                         end,
%%                  misc_packet:send(Player2#player.net_pid, Packet),
%%                  {?ok, Player2};
%%              {?error, _ErrorCode} ->
%%                  {?ok, Player}
%%          end
%%  end.















