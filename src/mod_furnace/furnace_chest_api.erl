%% @author jin
%% @doc @todo Add description to furnace_chest_api.


-module(furnace_chest_api).

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([remove_armor/2, fix_hide_flags/1, packet_style/3, login_packet/2, get_active_equip/2, save_image/3]).

	
%% 卸下武器或者衣服
remove_armor(Player, EquipIdx) when EquipIdx =:= ?CONST_GOODS_EQUIP_WEAPON orelse EquipIdx =:= ?CONST_GOODS_EQUIP_ARMOR->
	StyleData = Player#player.style,
	CurSkinList = lists:keyreplace(EquipIdx, 1, StyleData#style_data.cur_skin, {EquipIdx, ?CONST_SYS_FALSE}),
	CurNonSkinList = lists:keyreplace(EquipIdx, 1, StyleData#style_data.cur_non_skin, {EquipIdx, ?CONST_SYS_FALSE}),
	StyleData2 = StyleData#style_data{cur_skin = CurSkinList, cur_non_skin = CurNonSkinList},
	Player#player{style = StyleData2};
remove_armor(Player, _EquipIdx) ->
	Player.

%% 修正隐藏装备列表
fix_hide_flags(Player) when is_record(Player, player) ->
	StyleData = Player#player.style,
	HideFlags = lists:ukeysort(1, StyleData#style_data.hide_flags),
	CurNonSkin = lists:ukeysort(1, StyleData#style_data.cur_non_skin),
	CurSkinList = lists:ukeysort(1, StyleData#style_data.cur_skin),
	StyleData2 = StyleData#style_data{hide_flags = HideFlags, cur_non_skin = CurNonSkin, cur_skin = CurSkinList},
	Player#player{style = StyleData2};
fix_hide_flags(Player) ->
	Player.

%% 打包装备激活状态数据
packet_style(Type, Player, Style) ->
	Info = Player#player.info,
	Pro = Info#info.pro,
	Sex = Info#info.sex,
	case catch get_chest_unique_id(Style, Type, Pro, Sex) of
		{?ok, UniqueId} ->
			furnace_api:msg_sc_equip_states(Type, UniqueId);
		_Other ->
			<<>>
	end.

%% 登录发协议
login_packet(Player, OldPacket) ->
	F = fun(Type, Acc) ->
				Packet = get_active_equip(Player, Type),
				<<Acc/binary, Packet/binary>>
		end,
	NewPacket = lists:foldl(F, OldPacket, [?CONST_GOODS_EQUIP_WEAPON, ?CONST_GOODS_EQUIP_ARMOR]),
	{Player, NewPacket}.

%% 获取激活装备
get_active_equip(Player, Type) when Type =:= ?CONST_GOODS_EQUIP_WEAPON orelse Type =:= ?CONST_GOODS_EQUIP_ARMOR ->
	Style = Player#player.style,
	Info = Player#player.info,
	Pro = Info#info.pro,
	Sex = Info#info.sex,
	case lists:keyfind(Type, 1, Style#style_data.bag) of
		{_, StyleList} ->
			F = fun({Mode, _}, Acc) ->
						case catch get_chest_unique_id(Mode, Type, Pro, Sex) of
							{?ok, UniqueId} ->
								Packet = furnace_api:msg_sc_equip_states(Type, UniqueId),
								<<Acc/binary, Packet/binary>>;
							_Other ->
								Acc
						end
				end,
			lists:foldl(F, <<>>, StyleList);
		_ ->
			<<>>
	end;
get_active_equip(_Player, _Type) -> ?ok.

%% 保存形象
save_image(Player, Weapon, Cloth) ->
	UserId = Player#player.user_id,
	StyleData = Player#player.style,
	WeaponStyle =
		case data_furnace:get_chest(Weapon) of
			?null ->
				?null;
			WeaponChest ->
				WeaponChest#rec_chest.mode
		end,
	ClothStyle =
		case data_furnace:get_chest(Cloth) of
			?null ->
				?null;
			ClothChest ->
				ClothChest#rec_chest.mode
		end,
	IsExistWeapon	= is_exist_style(StyleData, WeaponStyle, ?CONST_GOODS_EQUIP_WEAPON),
	IsExistCloth	= is_exist_style(StyleData, ClothStyle, ?CONST_GOODS_EQUIP_ARMOR),
	WeaponStyle2	= chk(IsExistWeapon, WeaponStyle),
	ClothStyle2		= chk(IsExistCloth, ClothStyle),
	CurSkinList = StyleData#style_data.cur_skin,
	CurNonSkinList = StyleData#style_data.cur_non_skin,
	CurNonSkinList2 = 
        case WeaponStyle2 =/= ?null of
			?true ->
                lists:keystore(?CONST_GOODS_EQUIP_WEAPON, 1, CurNonSkinList,  {?CONST_GOODS_EQUIP_WEAPON, WeaponStyle2});
            ?false ->
                CurNonSkinList
        end,
    CurSkinList2 =
		case ClothStyle2 =/= ?null of
			?true ->
				lists:keystore(?CONST_GOODS_EQUIP_ARMOR, 1, CurSkinList, {?CONST_GOODS_EQUIP_ARMOR, ClothStyle2});
			?false ->
				CurSkinList
		end,
	StyleData2   = StyleData#style_data{cur_non_skin = CurNonSkinList2, cur_skin = CurSkinList2}, 
    Player2 = Player#player{style = StyleData2},
    PacketOk = message_api:msg_notice(?TIP_FURNACE_FUSION_SAVE_OK),
    UserId = Player2#player.user_id,
    misc_packet:send(UserId, PacketOk),
    map_api:change_skin_weapon(Player2),
	map_api:change_skin_armor(Player2),
	{?ok, Player2}.
%% ====================================================================
%% Internal functions
%% ====================================================================
get_chest_unique_id(Mode, Type, Pro, Sex) ->
	case data_furnace:get_chest_unique_id({Mode, Type, Pro, Sex}) of
		?null ->
			?ignore;
		Data ->
			throw({?ok, Data})
	end,
	case data_furnace:get_chest_unique_id({Mode, Type, 0, Sex}) of
		?null ->
			?ignore;
		Data2 ->
			throw({?ok, Data2})
	end,
	case data_furnace:get_chest_unique_id({Mode, Type, Pro, 0}) of
		?null ->
			?ignore;
		Data3 ->
			throw({?ok, Data3})
	end,
	case data_furnace:get_chest_unique_id({Mode, Type, 0, 0}) of
		?null ->
			?null;
		Data4 ->
			throw({?ok, Data4})
	end.
				
is_exist_style(_StyleData, ?null, _Type) ->
    ?false;
is_exist_style(StyleData, Style, Type) ->
    case lists:keyfind(Type, 1, StyleData#style_data.bag) of
        {_, StyleList} ->
            lists:keyfind(Style, 1, StyleList) =/= ?false;
        _ ->
            ?false
    end.

chk(?false, _) -> ?null;
chk(_, ?null) -> ?null;
chk(_, X) -> X.

