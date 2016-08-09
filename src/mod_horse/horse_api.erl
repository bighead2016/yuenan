%%% 坐骑接口
-module(horse_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").

-include("record.data.hrl").
-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.player.hrl").

%%
%% Exported Functions 
%%
-export([init/0, login/1, login_packet/2, request_not_save_attr/4]).
-export([
		 get_attr_list/3, save_refresh/5,
		 make_horse/1,use_goods/6,get_horse_skill/1,
		 horse_data_msg/2,mall_lv_up/5,
		 get_horse/4,refresh/1, get_horse_train/1,
		 error_message/2,error_message2/2, msg_attr_not_save/1,
         pack_horse_skin/2, get_horse_lv/1
		]).
-export([
         msg_sc_del_develop/1,
         msg_sc_develop/3, msg_sc_horseskill/1,
         msg_sc_crit/1, msg_stren_count/1, msg_sc_skill_have/1,
         msg_sc_useskin/2, msg_sc_del_skin/1
        ]).

%%
%% API Functions
%%

%% 初始化结构
init() ->
    HorseStable = horse_stable_api:init(),
    HorseSkill  = horse_skill_api:init(),
    HorseTrain  = horse_train_api:init(),
    #horse_data{
                pony_stable = HorseStable,
                skill       = HorseSkill,
                train       = HorseTrain 
               }.

%% 上线
login(Player) ->
    horse_train_api:reset_times(Player).

%% 上线处理
login_packet(Player, OldPacket) ->
    Packet      = horse_stable_api:list_all(Player),
    CountPacket = horse_train_api:login_packet(Player),
    SkillPacket = horse_skill_api:login_packet(Player),
    
    Player2     = goods_style_api:clear_time(Player, 0),
    StyleData   = Player2#player.style,
    StyleBag    = StyleData#style_data.bag,
    SkinPacket  = 
        case lists:keyfind(?CONST_GOODS_EQUIP_HORSE, 1, StyleBag) of
            {_, StyleList} ->
                pack_horse_skin(StyleList, <<>>);
            _ ->
                <<>>
        end,
    {Player2, <<OldPacket/binary, Packet/binary, CountPacket/binary, SkillPacket/binary, SkinPacket/binary>>}.

pack_horse_skin([{SkinId, Time}|Tail], OldPacket) ->
    Packet = horse_api:msg_sc_useskin(SkinId, Time),
    pack_horse_skin(Tail, <<OldPacket/binary, Packet/binary>>);
pack_horse_skin([], Packet) ->
    Packet.

get_horse_train(Player) ->
    HorseData = Player#player.horse,
    HorseData#horse_data.train.

refresh(Player) ->
    Player2 = horse_train_api:reset_times(Player),
    {?ok, Player2}.

get_horse_lv(UserId) ->
    case player_api:get_player_fields(UserId, [#player.horse]) of
        {?ok, [HorseData]} ->
            HorseTrain = HorseData#horse_data.train,
            HorseTrain#horse_train.lv;
        _X ->
			case cross_arena_mod:get_cross_player(UserId) of
				PlayerData when is_record(PlayerData, player) ->
					case PlayerData#player.horse of
						HorseData when is_record(HorseData, horse_data) ->
							Tain = HorseData#horse_data.train,
							Tain#horse_train.lv;
						_ ->
							0
					end;
				_ ->
					0
			end	
    end.

request_not_save_attr(Player, CtnType,PartnerId,Grid) ->
    {?ok,EquipInfo}         = get_horse(Player, CtnType, PartnerId, Grid),      %% 坐骑信息
    Exts                    = EquipInfo#goods.exts,
    case Exts#g_equip.ride_list of
        [_, AttrList] when is_list(AttrList)->
            Packet = msg_attr_not_save(AttrList),
            misc_packet:send(Player#player.user_id, Packet);
        _ ->
            ok
    end,
    {ok, Player}.

save_refresh(Player, IsSave, CtnType,PartnerId,Grid) ->
    {?ok,EquipInfo}         = get_horse(Player, CtnType, PartnerId, Grid),      %% 坐骑信息
    Exts                    = EquipInfo#goods.exts,
    case IsSave of
        false ->
            case Exts#g_equip.ride_list of
                [AttrList, _] when is_list(AttrList) ->
                    Exts2                   = Exts#g_equip{ride_list = AttrList},
                    EquipInfo2              = EquipInfo#goods{exts = Exts2},
                    {?ok, Player2, _Packet}  = horse_mod:replace(Player,CtnType,PartnerId,Grid,EquipInfo2), %% 更新新的坐骑
                    Player3                 = player_attr_api:refresh_attr_equip(Player2), %%　更新属性
                    {ok, Player3};
                _ ->
                    {ok, Player}
            end;
        _ ->
            case Exts#g_equip.ride_list of
                [_, AttrList] when is_list(AttrList)->
                    Exts2                   = Exts#g_equip{ride_list = AttrList}, 
                    EquipInfo2              = EquipInfo#goods{exts = Exts2},
                    {?ok, Player2, Packet}  = horse_mod:replace(Player,CtnType,PartnerId,Grid,EquipInfo2), %% 更新新的坐骑
                    Player3                 = player_attr_api:refresh_attr_equip(Player2), %%　更新属性
                    misc_packet:send(Player#player.net_pid, Packet),
                    {ok, Player3};
                _ ->
                    {ok, Player}
            end
    end.

%%-----------------------------------------------------------------------
%% 生成坐骑
%% return : Goods | {?error, ErrorCode}
make_horse(Goods) ->
	horse_mod:make_horse(Goods).

%% 获取强化等级的属性
%% horse_api:get_attr_list(1,20,1).
get_attr_list(HorseTrain, Color, Lv) ->
    case data_horse:get_horse_lv(HorseTrain#horse_train.lv) of
        ?null -> [];
        #rec_horse_lv{add_attr = Value} ->
            [{?CONST_PLAYER_ATTR_FORCE, Value}, {?CONST_PLAYER_ATTR_FATE, Value}, {?CONST_PLAYER_ATTR_MAGIC, Value}]
    end.

get_horse(Player, Type, ParentId, HorseGrid) ->
	horse_mod:get_horse(Player, Type, ParentId, HorseGrid).
%% 
%% cal_attr_list(AttrList,ColorNum) ->
%% 	cal_attr_list(AttrList,ColorNum,[]).
%% 
%% cal_attr_list([],_,AttrList) ->
%% 	AttrList;
%% cal_attr_list([{Type,Value}|List],ColorNum,AttrList) ->
%% 	Value2		= misc:ceil(Value * ColorNum),	
%% 	AttrList2 	= [{Type,Value2}|AttrList],
%% 	cal_attr_list(List,ColorNum,AttrList2).

%% 获取装备坐骑技能id
%% horse_api: get_horse_skill(Player).
%% arg 		: Player
%% return 	: ?null | {?ok,GoodsId,SkilId,Attr}
get_horse_skill(Player) ->
	UserId 		= Player#player.user_id,
	Equip		= Player#player.equip,
	CtnType 	= ?CONST_GOODS_CTN_EQUIP_PLAYER,
	case lists:keyfind({UserId,CtnType}, 1, Equip) of
		?false ->
			{?ok, 0, 0, ?null, ?null};
		{_,Container} ->
			case ctn_bag2_api:read(Container, ?CONST_GOODS_EQUIP_HORSE) of %% 读取背包的物品
				{?ok, ?null} ->
					{?ok, 0, 0, ?null, ?null};
				{?ok, Goods} ->
					Exts 		= Goods#goods.exts,
					SkillId		= Exts#g_equip.skill_id,
					Attr		= get_horse_skill_attr(SkillId),
					Selection	= {Goods#goods.color, Goods#goods.lv, Exts#g_equip.strength_lv, Exts#g_equip.exp},
					{?ok, Goods#goods.goods_id, SkillId, Attr, Selection}
			end
	end.

%% 获取坐骑技能属性
get_horse_skill_attr(SkillId) ->
	case data_horse:get_horse_skill(SkillId) of
		?null -> 
			player_attr_api:record_attr();
		HorseSkill -> 
			HorseSkill#rec_horse_skill.attr
	end.

%% 使用小马
use_goods(Player, GoodsId, _Color, _Bind, _HorseId, Grow) ->
	horse_mod:use_goods(Player, GoodsId, Grow).

%% 错误消息
error_message(Player,ErrorCode) ->
	Packet = message_api:msg_notice(ErrorCode),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok,Player}.

error_message2(Pid,ErrorCode) ->
	Packet = message_api:msg_notice(ErrorCode),
	misc_packet:send(Pid, Packet).


horse_data_msg(Lv,Exp) ->
	PacketLv	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_HORSE_LV, Lv),		 	
	PacketExp  	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_HORSE_EXP, Exp),
	<<PacketLv/binary,PacketExp/binary>>.

%%
mall_lv_up(Player,CtnType,PartnerId,Grid,Goods) ->
	horse_mod:mall_lv_up(Player,CtnType,PartnerId,Grid,Goods).

%% 坐骑培养数据返回
%%[{Pos,GoodsId,HorseId,Color,Time}] 
msg_sc_develop(Idx, GoodsId, Time) ->
	misc_packet:pack(?MSG_ID_HORSE_SC_DEVELOP, ?MSG_FORMAT_HORSE_SC_DEVELOP, [Idx, GoodsId, Time]).
%% 删除小马驹
%%[Pos]
msg_sc_del_develop(Pos) ->
    misc_packet:pack(?MSG_ID_HORSE_SC_DEL_DEVELOP, ?MSG_FORMAT_HORSE_SC_DEL_DEVELOP, [Pos]).
%% 坐骑学习技能返回
%%[Res]
msg_sc_horseskill(Res) ->
	misc_packet:pack(?MSG_ID_HORSE_SC_HORSESKILL, ?MSG_FORMAT_HORSE_SC_HORSESKILL, [Res]).
%% 坐骑技能
%%[SkillId]
msg_sc_skill_have(SkillId) ->
    misc_packet:pack(?MSG_ID_HORSE_SC_SKILL_HAVE, ?MSG_FORMAT_HORSE_SC_SKILL_HAVE, [SkillId]).
%% 暴击类型返回
%%[Type]
msg_sc_crit(Type) ->
	misc_packet:pack(?MSG_ID_HORSE_SC_CRIT, ?MSG_FORMAT_HORSE_SC_CRIT, [Type]).
%% 免费强化次数
%%[Count]
msg_stren_count(Count) ->
	misc_packet:pack(?MSG_ID_HORSE_STREN_COUNT, ?MSG_FORMAT_HORSE_STREN_COUNT, [Count]).
%% 可用的坐骑皮肤
%%[SkinId]
msg_sc_useskin(SkinId, Time) ->
    misc_packet:pack(?MSG_ID_HORSE_SC_USESKIN, ?MSG_FORMAT_HORSE_SC_USESKIN, [SkinId, Time]).
%% 删除皮肤
%%[SkinId]
msg_sc_del_skin(SkinId) ->
    misc_packet:pack(?MSG_ID_HORSE_SC_DEL_SKIN, ?MSG_FORMAT_HORSE_SC_DEL_SKIN, [SkinId]).

%% 坐骑未保存的属性
%%[{Type,Value}]
msg_attr_not_save(List1) ->
    misc_packet:pack(?MSG_ID_HORSE_ATTR_NOT_SAVE, ?MSG_FORMAT_HORSE_ATTR_NOT_SAVE, [List1]).
%%
%% Local Functions
%%

