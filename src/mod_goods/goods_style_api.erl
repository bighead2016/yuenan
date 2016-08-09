%%% 道具皮肤相关
-module(goods_style_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([get_skin_id/1, add_style/4, is_exist_style/3, get_cur_style/2, add_style_list/2,
         add_all_temp_horse/1, clear_time/2, add_style/5]).
-export([change_non_skin_style/3, change_skin_style/3]).
-export([is_hide/2, xor_hide/2]).

%%
%% API Functions
%%

%% 读取物品皮肤id
get_skin_id(#goods{type = ?CONST_GOODS_TYPE_EQUIP} = Goods) ->
    SubType = Goods#goods.sub_type, 
    Exts    = Goods#goods.exts,
    {SubType, Exts#g_equip.skin_id}.

%% 增加时装
%% add_style(StyleBag, 0, _) ->
%%     {<<>>, StyleBag};
add_style(Player, StyleBag, Style, Idx) ->
    case lists:keytake(Idx, 1, StyleBag) of
        {value, {_, StyleList}, StyleBag2} ->
            case lists:keytake(Style, 1, StyleList) of
                ?false ->
                    Packet = packet_style(Idx, Player, Style, 0),
                    {Packet, [{Idx, [{Style, 0}|StyleList]}|StyleBag2]};
                {value, {_, 0}, _} ->
                    {<<>>, StyleBag};
                {value, {_, _}, StyleList2} ->
                    Packet = packet_style(Idx, Player, Style, 0),
                    {Packet, [{Idx, [{Style, 0}|StyleList2]}|StyleBag2]}
            end;
        ?false ->
            Packet = packet_style(Idx, Player, Style, 0),
            {Packet, [{Idx, [{Style, 0}]}|StyleBag]}
    end.

add_style(Player, StyleBag, Style, Time, Idx) ->
    case lists:keytake(Idx, 1, StyleBag) of
        {value, {_, StyleList}, StyleBag2} ->
            case lists:keytake(Style, 1, StyleList) of
                ?false ->
                    Packet = packet_style(Idx, Player, Style, Time),
                    {Packet, [{Idx, [{Style, Time}|StyleList]}|StyleBag2]};
                {value, {_, T}, StyleList2}  ->
					NewTime =
						if Time > T andalso T =/= 0 -> Time;
						   Time =:= 0 orelse T =:= 0 -> 0;
						   true -> T
						end,
                    Packet = packet_style(Idx, Player, Style, NewTime),
                    {Packet, [{Idx, [{Style, NewTime}|StyleList2]}|StyleBag2]};
                _ ->
                    {<<>>, StyleBag}
            end;
        ?false ->
            Packet = packet_style(Idx, Player, Style, Time),
            {Packet, [{Idx, [{Style, Time}]}|StyleBag]}
    end.

packet_style(?CONST_GOODS_EQUIP_HORSE, _Player, Style, Time) ->
	horse_api:msg_sc_useskin(Style, Time);
packet_style(?CONST_GOODS_EQUIP_WEAPON, Player, Style, _Time) ->
	furnace_chest_api:packet_style(?CONST_GOODS_EQUIP_WEAPON, Player, Style);
packet_style(?CONST_GOODS_EQUIP_ARMOR, Player, Style, _Time) ->
	furnace_chest_api:packet_style(?CONST_GOODS_EQUIP_ARMOR, Player, Style);
packet_style(Idx, _Player, Style, _Time) ->
	furnace_api:msg_sc_style(Style, Idx).

add_style_list(Player, GoodsList) ->
    StyleData = Player#player.style,
    StyleBag  = StyleData#style_data.bag,
    {StyleBag2, Packet} = add_style_list_2(Player, StyleBag, GoodsList, <<>>),
	%?MSG_ERROR("StyleBag:~w, StyleBag2:~w", [StyleBag, StyleBag2]),
    StyleData2 = StyleData#style_data{bag = StyleBag2},
    {Player#player{style = StyleData2}, Packet}.
add_style_list_2(Player, StyleBag, [#goods{sub_type = Idx, exts = #g_equip{skin_id = Style}}|Tail], OldPacket) ->
    {Pakcet, StyleBag2} = add_style(Player, StyleBag, Style, Idx),
    add_style_list_2(Player, StyleBag2, Tail, <<OldPacket/binary, Pakcet/binary>>);
add_style_list_2(Player, StyleBag, [_|Tail], OldPacket) ->
    add_style_list_2(Player, StyleBag, Tail, OldPacket);
add_style_list_2(_Player, StyleBag, [], Packet) ->
    {StyleBag, Packet}.
    
%% 存在?
is_exist_style(_StyleData, 0, _Type) ->
    ?true;
is_exist_style(StyleData, Style, Type) ->
    case lists:keyfind(Type, 1, StyleData#style_data.bag) of
        {_, StyleList} ->
            lists:keyfind(Style, 1, StyleList) =/= ?false;
        _ ->
            ?false
    end.

%% 读取当前外形
get_cur_style(#player{} = Player, ?CONST_GOODS_ATTR_VIP = Type) ->
	StyleData = Player#player.style,
	HideFlags = StyleData#style_data.hide_flags,
	HideType = get_hide_flag_type(Type),
	case lists:keyfind(HideType, 1, HideFlags) of
		{_, ?CONST_SYS_TRUE} ->
			?CONST_SYS_TRUE;
		_ ->
			?CONST_SYS_FALSE
	end;
get_cur_style(#player{} = Player, ?CONST_GOODS_EQUIP_FUSION = Type) ->
    StyleData = Player#player.style,
    get_cur_style(StyleData, Type);
get_cur_style(#style_data{} = StyleData, ?CONST_GOODS_EQUIP_FUSION = Type) ->
    HideFlags = StyleData#style_data.hide_flags, 
    CurStyleList = StyleData#style_data.cur_skin,
    HideType = get_hide_flag_type(Type),
    case lists:keyfind(HideType, 1, HideFlags) of
        {_, ?CONST_SYS_TRUE} ->
            0;
        _ ->
            case lists:keyfind(Type, 1, CurStyleList) of
                ?false ->
                    0;
                {_, ClothStyle} ->
                    ClothStyle
            end
    end;
get_cur_style(#player{} = Player, Type) ->
    StyleData = Player#player.style,
    HideFlags = StyleData#style_data.hide_flags, 
    CurStyleList = StyleData#style_data.cur_skin,
    CurNonSkinList = StyleData#style_data.cur_non_skin,
    HideType = get_hide_flag_type(Type),
    case lists:keyfind(HideType, 1, HideFlags) of
        {_, ?CONST_SYS_FALSE} ->
            case lists:keyfind(Type, 1, CurStyleList) of
                {_, SkinId} when SkinId =/= 0 ->
                    SkinId;
                _ ->
                    Type2 = get_other_type(Type),
                    case lists:keyfind(Type2, 1, CurNonSkinList) of
                        {_, SkinId} when SkinId =/= 0 ->
                            SkinId;
                        _ ->
                            0
                    end
            end;
        {_, ?CONST_SYS_TRUE} ->
            Type2 = get_other_type(Type),
            case lists:keyfind(Type2, 1, CurNonSkinList) of
                {_, SkinId} when SkinId =/= 0 ->
                    SkinId;
                _ ->
                    0
            end;
        _ ->
            case lists:keyfind(Type, 1, CurStyleList) of
                {_, SkinId} when SkinId =/= 0 ->
                    SkinId;
                _ ->
                    Type2 = get_other_type(Type),
                    case lists:keyfind(Type2, 1, CurNonSkinList) of
                        {_, SkinId} when SkinId =/= 0 ->
                            SkinId;
                        _ ->
                            0
                    end
            end
    end;
get_cur_style(#style_data{} = StyleData, Type) ->
    HideFlags = StyleData#style_data.hide_flags, 
    CurStyleList = StyleData#style_data.cur_skin,
    CurNonSkinList = StyleData#style_data.cur_non_skin,
    HideType = get_hide_flag_type(Type),
    case lists:keyfind(HideType, 1, HideFlags) of
        {_, ?CONST_SYS_FALSE} ->
            case lists:keyfind(Type, 1, CurStyleList) of
                {_, SkinId} when SkinId =/= 0 ->
                    SkinId;
                _ ->
                    Type2 = get_other_type(Type),
                    case lists:keyfind(Type2, 1, CurNonSkinList) of
                        {_, SkinId} when SkinId =/= 0 ->
                            SkinId;
                        _ ->
                            0
                    end
            end;
        {_, ?CONST_SYS_TRUE} ->
            Type2 = get_other_type(Type),
            case lists:keyfind(Type2, 1, CurNonSkinList) of
                {_, SkinId} when SkinId =/= 0 ->
                    SkinId;
                _ ->
                    0
            end;
        _ ->
            case lists:keyfind(Type, 1, CurStyleList) of
                {_, SkinId} when SkinId =/= 0 ->
                    SkinId;
                _ ->
                    Type2 = get_other_type(Type),
                    case lists:keyfind(Type2, 1, CurNonSkinList) of
                        {_, SkinId} when SkinId =/= 0 ->
                            SkinId;
                        _ ->
                            0
                    end
            end
    end.

%% 改变变化外形
change_skin_style(Player, Style, Type) ->
    StyleData = Player#player.style,
    CurList = StyleData#style_data.cur_skin,
    CurList3 = 
        case lists:keytake(Type, 1, CurList) of
            ?false ->
                [{Type, Style}|CurList];
            {value, _, CurList2} ->
                [{Type, Style}|CurList2]
        end,
    StyleData2 = StyleData#style_data{cur_skin = CurList3},
    Player#player{style = StyleData2}.

%% 改变非变化外形
change_non_skin_style(Player, Style, Type) ->
    StyleData = Player#player.style,
    CurList = StyleData#style_data.cur_non_skin,
    CurList3 = 
        case lists:keytake(Type, 1, CurList) of
            ?false ->
                [{Type, Style}|CurList];
            {value, _, CurList2} ->
                [{Type, Style}|CurList2]
        end,
    StyleData2 = StyleData#style_data{cur_non_skin = CurList3},
    Player#player{style = StyleData2}.

%% 隐藏
is_hide(StyleData, Type) when is_record(StyleData, style_data) ->
    HideList  = StyleData#style_data.hide_flags,
    case lists:keyfind(Type, 1, HideList) of
        {_, ?CONST_SYS_TRUE} ->
            ?CONST_SYS_TRUE;
        _ ->
            ?CONST_SYS_FALSE
    end;
is_hide(Player, Type) ->
    StyleData = Player#player.style,
    HideList  = StyleData#style_data.hide_flags,
    case lists:keyfind(Type, 1, HideList) of
        {_, ?CONST_SYS_TRUE} ->
            ?CONST_SYS_TRUE;
        _ ->
            ?CONST_SYS_FALSE
    end.

%% 状态取反
xor_hide(Player, Type) ->
    StyleData = Player#player.style,
    HideList  = StyleData#style_data.hide_flags,
    {NewPacket, NewHideList} = 
        case lists:keytake(Type, 1, HideList) of
            {value, {_, ?CONST_SYS_TRUE}, HideList2} ->
                Packet = 
                    case Type of
                        ?CONST_GOODS_EQUIP_HORSE ->
                            player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_HORSE, ?CONST_SYS_FALSE);
                        ?CONST_GOODS_EQUIP_FUSION ->
                            player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_FASHION, ?CONST_SYS_FALSE);
						?CONST_GOODS_ATTR_VIP ->
							player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_VIP, ?CONST_SYS_FALSE);
                        _ ->
                            <<>>
                    end,
                {Packet, [{Type, ?CONST_SYS_FALSE}|HideList2]};
			{value, {_, ?CONST_SYS_FALSE}, HideList2} ->
                Packet = 
                    case Type of
                        ?CONST_GOODS_EQUIP_HORSE ->
                            player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_HORSE, ?CONST_SYS_TRUE);
                        ?CONST_GOODS_EQUIP_FUSION ->
                            player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_FASHION, ?CONST_SYS_TRUE);
						?CONST_GOODS_ATTR_VIP ->
							player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_VIP, ?CONST_SYS_TRUE);
                        _ ->
                            <<>>
                    end,
                {Packet, [{Type, ?CONST_SYS_TRUE}|HideList2]};
            _ ->
                Packet = 
                    case Type of
                        ?CONST_GOODS_EQUIP_HORSE ->
                            player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_HORSE, ?CONST_SYS_TRUE);
                        ?CONST_GOODS_EQUIP_FUSION ->
                            player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_FASHION, ?CONST_SYS_TRUE);
						?CONST_GOODS_ATTR_VIP ->
							player_api:msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_VIP, ?CONST_SYS_TRUE);
                        _ ->
                            <<>>
                    end,
                {Packet, [{Type, ?CONST_SYS_TRUE}|HideList]}
        end,
    NewStyleData = StyleData#style_data{hide_flags = NewHideList},
    {NewPacket, Player#player{style = NewStyleData}}.

add_all_temp_horse(Player) ->
    StyleList = data_horse:get_skin_tmp_list(),
    StyleData = Player#player.style,
    StyleBag = StyleData#style_data.bag,
    Sec = misc:seconds() + ?CONST_HORSE_TEMP_TIME,
    {StyleBag2, Packet} = add_all_temp_horse(Player, StyleBag, StyleList, <<>>, Sec),
    StyleData2 = StyleData#style_data{bag = StyleBag2},
    misc_packet:send(Player#player.user_id, Packet),
    Player#player{style = StyleData2}.
add_all_temp_horse(Player, StyleBag, [Style|Tail], OldPacket, Sec) ->
    {Packet, StyleBag2} = add_style(Player, StyleBag, Style, Sec, ?CONST_GOODS_EQUIP_HORSE),
    add_all_temp_horse(Player, StyleBag2, Tail, <<OldPacket/binary, Packet/binary>>, Sec);
add_all_temp_horse(_Player, StyleBag, [], Packet, _Sec) ->
    {StyleBag, Packet}.

clear_time(Player, _SkinId) ->
    StyleData = Player#player.style,
    StyleBag = StyleData#style_data.bag,
    CurSkinList = StyleData#style_data.cur_skin,
    case lists:keytake(?CONST_GOODS_EQUIP_HORSE, 1, StyleBag) of
        {_, {_, StyleList}, StyleBag2} ->
            Now = misc:seconds(),
%%             CurSkin = get_cur_style(StyleData, ?CONST_GOODS_EQUIP_HORSE),
            CurSkin = 
                case lists:keyfind(?CONST_GOODS_EQUIP_HORSE, 1, CurSkinList) of
                    ?false ->
                        0;
                    {_, HorseStyleT} ->
                        HorseStyleT
                end,
            {CurSkin2, Packet, NewStyleList} = clear_time(CurSkin, StyleList, [], Now, <<>>),
            NewStyleBag = [{?CONST_GOODS_EQUIP_HORSE, NewStyleList}|StyleBag2],
%%             ?MSG_ERROR("~p~n~p", [CurSkin, CurSkin2]),
            misc_packet:send(Player#player.user_id, Packet),
            Player2 = Player#player{style = StyleData#style_data{bag = NewStyleBag}},
            change_skin_style(Player2, CurSkin2, ?CONST_GOODS_EQUIP_HORSE);
        _ ->
            Player
    end.
    
clear_time(CurSkin, [{Style, 0}|Tail], OldStyleList, Now, OldPacket) ->
    clear_time(CurSkin, Tail, [{Style, 0}|OldStyleList], Now, OldPacket);
clear_time(CurSkin, [{Style, Sec}|Tail], OldStyleList, Now, OldPacket) when Sec < Now ->
    CurSkin2 = 
        if
            CurSkin =:= Style ->
                -1;
            ?true ->
                CurSkin
        end,
    Packet = horse_api:msg_sc_del_skin(Style),
    clear_time(CurSkin2, Tail, OldStyleList, Now, <<OldPacket/binary, Packet/binary>>);
clear_time(CurSkin, [{Style, Sec}|Tail], OldStyleList, Now, OldPacket) ->
    clear_time(CurSkin, Tail, [{Style, Sec}|OldStyleList], Now, OldPacket);
clear_time(CurSkin, [], StyleList, _Now, OldPacket) ->
    CurSkin2 = 
        if
            CurSkin =:= -1 ->
                if
                    StyleList =:= [] ->
                        0;
                    ?true ->
                        {S, _} = erlang:hd(StyleList),
                        S
                end;
            ?true ->
                CurSkin
        end,
    {CurSkin2, OldPacket, StyleList}.
    

%%
%% Local Functions
%%
get_other_type(?CONST_GOODS_EQUIP_FUSION_WEAPON) -> ?CONST_GOODS_EQUIP_WEAPON;
get_other_type(X) -> X.

get_hide_flag_type(?CONST_GOODS_EQUIP_FUSION_WEAPON) -> ?CONST_GOODS_EQUIP_FUSION;
get_hide_flag_type(?CONST_GOODS_EQUIP_FUSION) -> ?CONST_GOODS_EQUIP_FUSION;
get_hide_flag_type(?CONST_GOODS_EQUIP_FUSION_STEP) -> ?CONST_GOODS_EQUIP_FUSION;
get_hide_flag_type(?CONST_GOODS_EQUIP_HORSE) -> ?CONST_GOODS_EQUIP_HORSE;
get_hide_flag_type(?CONST_GOODS_ATTR_VIP) -> ?CONST_GOODS_ATTR_VIP;
get_hide_flag_type(_) -> ?null.