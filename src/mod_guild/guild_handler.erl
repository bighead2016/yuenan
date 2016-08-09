%% Author: php
%% Created: 
%% Description: TODO: Add description to guild2_handler
-module(guild_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求军团列表
handler(?MSG_ID_GUILD_CS_LIST, Player, {}) ->
	guild_mod:all_list(Player), 
	{?ok, Player};
%% 请求军团详情信息
handler(?MSG_ID_GUILD_CS_DATA, Player, {}) ->
	guild_mod:info(Player);
%% 加载成员列表请求
handler(?MSG_ID_GUILD_CS_MEMBER, Player, {}) ->
	guild_mod:member_list(Player),
	{?ok, Player};
%% 请求cd时间
handler(?MSG_ID_GUILD_CS_CD, Player, {}) -> 
	Packet 	= guild_mod:request_cd_data(Player#player.user_id), 
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player};
%% 清除cd时间
handler(?MSG_ID_GUILD_CS_CLEAN_CD, Player, {}) ->
	guild_mod:clean_cd(Player),
	{?ok, Player};
%% 军团申请列表请求
handler(?MSG_ID_GUILD_CS_APPLY_LIST, Player, {}) -> 
	guild_mod:apply_list(Player),
	{?ok, Player};

%% 创建军团请求
handler(?MSG_ID_GUILD_CS_CREATE, Player, {GuildName,IsUseCash}) ->
	guild_mod:create(Player, GuildName, IsUseCash);
%% 解散军团请求
handler(?MSG_ID_GUILD_DISBAND, Player, {}) ->
    case guild_pvp_api:is_can_guild_operation(Player) of
        false ->
            ok;
        _ ->
	       guild_mod:disband(Player)
    end,
	{?ok, Player};
%% 退出军团请求
handler(?MSG_ID_GUILD_QUIT, Player, {}) ->
    case guild_pvp_api:is_can_guild_operation(Player) of
        false ->
            {ok, Player};
        _ ->
           guild_mod:quit(Player)
    end;
	
%% 加入军团申请
handler(?MSG_ID_GUILD_CS_APPLY, Player, {GuildId}) ->
	guild_mod:apply(Player, GuildId),
	{?ok, Player};
%% 取消申请加入军团
handler(?MSG_ID_GUILD_CS_CANCEL_APPLY, Player, {GuildId}) ->
	guild_mod:apply_cancel(Player, GuildId),
	{?ok, Player};
%% 申请请求处理
handler(?MSG_ID_GUILD_CS_DEAL_APPLY, Player, {Type,UserId}) ->
    case guild_pvp_api:is_can_guild_operation(Player) of
        false ->
            ok;
        _ ->
           guild_mod:deal_with_apply(Player,UserId, Type)
    end,
	{?ok, Player};
%% 邀请入团
handler(?MSG_ID_GUILD_CS_INVITE, Player, {UserId}) ->
    case guild_pvp_api:is_can_guild_operation(Player) of
        false ->
            ok;
        _ ->
           guild_mod:invite(Player, UserId)
    end,
	{?ok, Player};
%% 处理军团邀请
handler(?MSG_ID_GUILD_CS_DEAL_INVITE, Player, {GuildId,Type}) ->
    guild_mod:deal_with_invite(Player, GuildId,Type);
	
%% 捐献申请
handler(?MSG_ID_GUILD_CS_DONATE, Player, {Type,Value}) ->
	guild_skill_mod:donate(Player,Type,Value);
%% 技能捐献申请
handler(?MSG_ID_GUILD_CS_SKILL_DONATE, Player, {SkillId,Type,Value}) ->
	guild_skill_mod:skill_up_donate(Player,Type,Value,SkillId);
%% 军团技能列表请求
handler(?MSG_ID_GUILD_CS_SKILL_LIST, Player, {}) ->
	guild_skill_mod:skill_data(Player),
	{?ok, Player};
%% 学习军团技能申请
handler(?MSG_ID_GUILD_CS_SKILL_LEARN, Player, {SkillId}) ->
	guild_skill_mod:skill_up(Player,SkillId),
	{?ok, Player};
%% 学习军团术法申请
handler(?MSG_ID_GUILD_CS_MAGIC_LEARN, Player, {MagicId}) ->
	guild_skill_mod:magic_up(Player,MagicId);
%% 术法列表请求
handler(?MSG_ID_GUILD_CS_MAGIC_LIST, Player, {}) ->
	guild_skill_mod:magic_data(Player),
	{?ok, Player};
%% 请求军团宝藏信息
handler(?MSG_ID_GUILD_CS_TREASURE, Player, {}) ->
 	guild_skill_mod:shop_data(Player),
	{?ok, Player};
%% 购买军团宝藏
handler(?MSG_ID_GUILD_CS_BUY_TREASURE, Player, {SkillLv,GoodsId,Num}) ->
	guild_skill_mod:shop_buy(Player,GoodsId,Num,SkillLv);
%% 踢出成员
handler(?MSG_ID_GUILD_CS_KICK_OUT, Player, {UserId}) ->
    case guild_pvp_api:is_can_guild_operation(Player) of
        false ->
            ok;
        _ ->
           guild_mod:kick_out(Player, UserId)
    end,
	{?ok, Player};
%% 提升至军团长
handler(?MSG_ID_GUILD_CS_CHIEF, Player, {UserId,Type}) ->
    case guild_pvp_api:is_can_guild_operation(Player) of
        false ->
            ok;
        _ ->
        	case Type of
        		1 ->
        			guild_mod:change_chief(Player,UserId);
        		2 ->
        			guild_mod:vice_chief(Player,UserId),
        			{?ok, Player}
        	end
    end;
%% 移除职位
handler(?MSG_ID_GUILD_CS_REMOVE_POS, Player, {UserId}) ->
	guild_mod:remove_duty(Player, UserId),
	{?ok, Player};
%% 弹劾军团长
handler(?MSG_ID_GUILD_CS_IMPEACH_CHIEF, Player, {}) ->
	guild_mod:impeach_chief(Player);

%% 自动提升职位
handler(?MSG_ID_GUILD_CS_PROMOTE_POS, Player, {}) ->
	guild_mod:promote(Player);

%% 修改个人留言
handler(?MSG_ID_GUILD_CS_INTRODUCE, Player, {_Introduce}) -> 
%% 	guild_mod:change_message(Player, Introduce),
	{?ok, Player};
%% 修改军团公告
handler(?MSG_ID_GUILD_CS_ANNOUNCE, Player, {Type,Announce}) ->
	guild_mod:change_announce(Player, Announce, Type),
	{?ok, Player};
%% 加载军团日志
handler(?MSG_ID_GUILD_CS_LOG, Player, {}) ->
	guild_mod:log_list(Player),
	{?ok, Player};
%% 请求仓库信息
handler(?MSG_ID_GUILD_CTN_REQUEST, Player, {}) ->
	guild_ctn_mod:ctn_data(Player),
	{?ok, Player};
%% 分配仓库物品
handler(?MSG_ID_GUILD_DISTRIBUTE, Player, {UserId,{_,List}}) ->
	guild_ctn_mod:distribute(Player,UserId,List),
	{?ok, Player};
%% 请求军团成员信息
handler(?MSG_ID_GUILD_MEMBER_INFO, Player, {}) ->
	List 	= guild_api:get_online_info(Player),
	Packet 	= guild_api:msg_sc_member_info(List),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player};
%% 成员名字信息
handler(?MSG_ID_GUILD_CS_MEMBER_NAME, Player, {}) ->
	guild_mod:member_name(Player),
	{?ok, Player};
%% 请求CD剩余时间
handler(?MSG_ID_GUILD_CS_CD_LEAVE_TIME, Player, {}) ->
	guild_mod:request_cd_leave_time(Player#player.user_id),
	{?ok, Player};
%% 成员详情信息
handler(?MSG_ID_GUILD_CS_MEM_DETAIL, Player, {UserId}) ->
	Pacekt	= guild_api:get_detail_data(UserId),
	misc_packet:send(Player#player.net_pid, Pacekt),
	{?ok, Player};
%% 快速邀请
handler(?MSG_ID_GUILD_CS_SUP_APPLY, Player, {}) ->
	guild_mod:sup_apply(Player), 
	{?ok, Player};
%% 快速申请
handler(?MSG_ID_GUILD_SUP_APPLY_ADD, Player, {GuildId}) ->
	guild_mod:sup_apply_add(Player,GuildId),
	{?ok, Player};

%% 设置下线超时踢人时间
handler(?MSG_ID_GUILD_TIMEOUT_TICK, Player, {Day}) ->
    guild_api:set_timeout(Player,Day),
    {?ok, Player};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
