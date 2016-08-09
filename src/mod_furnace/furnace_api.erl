%% Author: zero
%% Created: 2012-11-5
%% Description: TODO: Add description to furnace_api
-module(furnace_api).

%%
%% Include files
%%
-export([
		 init/1,
		 login/1,
		 login_packet/2,
		 trans_soul_id_value2/4
		]).
-export([
		 msg_equip_forge_return/2,
		 msg_equip_plus_return/4,
		 msg_get_user_stren_return/2,
         msg_plus_confirm_return/1,
		 msg_stren_queue_return/4,
		 msg_sc_cancel_stren_queue/0,
		 msg_stren_part_return/3,
		 msg_plus_inherit_return/1,
		 msg_goods_forge_return/1,
		 msg_stren_value_update/1,
         msg_sc_upgrade_multi/1,
		 msg_sc_fusion_return/3,
		 msg_sc_style/2,
		 msg_sc_ok_com_stone_query/1,
		 msg_sc_equip_states/2,
		 msg_sc_ok_transfer/1
		]).

%%
%% Exported Functions
%%
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.player.hrl").

%%
%% API Functions
%%
%% 初始化
init(N) ->                                  
    {
	 QueuesFlag, Queues
	}				= furnace_queue_api:refresh_queue(N),
    #furnace_data{queues_flag = QueuesFlag, queues = Queues}.

%% 登录
%% 1.重算cd列表
login(Player) ->
    FurnaceData = Player#player.furnace,
    NewFurnaceData = furnace_queue_api:refresh(FurnaceData),
    NewPlayer = Player#player{furnace = NewFurnaceData},
    NewPlayer.

login_packet(Player, Packet) ->
    Packet2 = furnace_stren_api:list_stren(Player),
    FashionPacket = furnace_fusion_api:show_all(Player),
    {Player, <<Packet/binary, Packet2/binary, FashionPacket/binary>>}.

trans_soul_id_value2(EquipType, EquipColor, EquipLv, SoulList) ->
    furnace_mod:trans_soul_id_value2(EquipType, EquipColor, EquipLv, SoulList).

%% -------------------------------------------
%% 强化队列推送（更新）
%%[QueueId,EndTime,Type,Status]
msg_stren_queue_return(QueueId,EndTime,Type,Status) ->
    misc_packet:pack(?MSG_ID_FURNACE_STREN_QUEUE_RETURN, ?MSG_FORMAT_FURNACE_STREN_QUEUE_RETURN, [QueueId,EndTime,Type,Status]).

%% 无强化队列(取消强化队列)
msg_sc_cancel_stren_queue() ->
	misc_packet:pack(?MSG_ID_FURNACE_SC_CANCEL_STREN_QUEUE, ?MSG_FORMAT_FURNACE_SC_CANCEL_STREN_QUEUE, []).

%% 角色强化信息返回
%%[UserId,{SubType,Lv}]
msg_get_user_stren_return(UserId,List1) when is_list(List1) ->
	misc_packet:pack(?MSG_ID_FURNACE_GET_USER_STREN_RETURN, ?MSG_FORMAT_FURNACE_GET_USER_STREN_RETURN, [UserId,List1]);
msg_get_user_stren_return(Id, Equip) when is_record(Equip, ctn) ->
    Ext 	= Equip#ctn.ext,
    ExtList = tuple_to_list(Ext),
    F = fun(StrLv, {OldList, Idx}) ->
                case furnace_stren_api:can_stren(Idx) of
                    ?CONST_SYS_TRUE ->
                        {[{Idx, StrLv}|OldList], Idx + 1};
                    ?CONST_SYS_FALSE ->
                        {OldList, Idx + 1}
                end
        end,
    {List, _} = lists:foldl(F, {[], 1}, ExtList),
    msg_get_user_stren_return(Id, List).

%% 装备部位强化返回
%%[UserId,SubType,Lv]
msg_stren_part_return(UserId,SubType,Lv) ->
	misc_packet:pack(?MSG_ID_FURNACE_STREN_PART_RETURN, ?MSG_FORMAT_FURNACE_STREN_PART_RETURN, [UserId,SubType,Lv]).

%% 装备锻造返回
%%[Result,Type]
msg_equip_forge_return(Result, Type) ->
    misc_packet:pack(?MSG_ID_FURNACE_EQUIP_FORGE_RETURN, ?MSG_FORMAT_FURNACE_EQUIP_FORGE_RETURN, [Result, Type]).

%% 多位置升阶返回
%%[Result]
msg_sc_upgrade_multi(Result) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_UPGRADE_MULTI, ?MSG_FORMAT_FURNACE_SC_UPGRADE_MULTI, [Result]).

%% 洗练继承返回
%%[Result]
msg_plus_inherit_return(Result) ->
    misc_packet:pack(?MSG_ID_FURNACE_PLUS_INHERIT_RETURN, ?MSG_FORMAT_FURNACE_PLUS_INHERIT_RETURN, [Result]).

%% 装备洗练返回
%%[CtnType,PartnerId,Index,{OldPlusType,OldPlusVal,NewPlusType,NewPlusVal,IsLock}]
msg_equip_plus_return(CtnType,PartnerId,Index,List1) ->
    misc_packet:pack(?MSG_ID_FURNACE_EQUIP_PLUS_RETURN, ?MSG_FORMAT_FURNACE_EQUIP_PLUS_RETURN, [CtnType,PartnerId,Index,List1]).

%% 洗练确认返回
%%[Result]
msg_plus_confirm_return(Result) ->
    misc_packet:pack(?MSG_ID_FURNACE_PLUS_CONFIRM_RETURN, ?MSG_FORMAT_FURNACE_PLUS_CONFIRM_RETURN, [Result]).

%% 道具合成返回
%%[Result]
msg_goods_forge_return(Result) ->
	misc_packet:pack(?MSG_ID_FURNACE_GOODS_FORGE_RETURN, ?MSG_FORMAT_FURNACE_GOODS_FORGE_RETURN, [Result]).

%% 强化成功属性更新
%%[{Type,Value}]
msg_stren_value_update(List1) ->
	misc_packet:pack(?MSG_ID_FURNACE_STREN_VALUE_UPDATE, ?MSG_FORMAT_FURNACE_STREN_VALUE_UPDATE, [List1]).

%% 外形
%%[StyleId,EquipIdx]
msg_sc_style(StyleId,EquipIdx) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_STYLE, ?MSG_FORMAT_FURNACE_SC_STYLE, [StyleId,EquipIdx]).

%% 时装合成返回
%%[Result, Idx, IsNew]
msg_sc_fusion_return(Result, Idx, IsNew) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_FUSION_RETURN, ?MSG_FORMAT_FURNACE_SC_FUSION_RETURN, [Result, Idx, IsNew]).

%% 一键合成宝石查询回复
%%[CostGold]
msg_sc_ok_com_stone_query(CostGold) ->
	misc_packet:pack(?MSG_ID_FURNACE_SC_OK_COM_STONE_QUERY, ?MSG_FORMAT_FURNACE_SC_OK_COM_STONE_QUERY, [CostGold]).

%% 返回装备激活状态
%%[Type,UniqueId]
msg_sc_equip_states(Type,UniqueId) ->
	misc_packet:pack(?MSG_ID_FURNACE_SC_EQUIP_STATES, ?MSG_FORMAT_FURNACE_SC_EQUIP_STATES, [Type,UniqueId]).

%% 一键转移结果
%%[Result]
msg_sc_ok_transfer(Result) ->
	misc_packet:pack(?MSG_ID_FURNACE_SC_OK_TRANSFER, ?MSG_FORMAT_FURNACE_SC_OK_TRANSFER, [Result]).

%%
%% Local Functions
%%

