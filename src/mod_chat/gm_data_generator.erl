%% Author: Administrator
%% Created: 2013-1-24
%% Description: TODO: Add description to gm_data_generator
-module(gm_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").


%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%
%% gm_data_generator:generate().
generate(Ver)	->
	FunDatas1	= generate_gm_goods(get_gm_goods, Ver),
	FunDatas2	= generate_gm_type_partners(get_gm_type_partners, Ver),
	FunDatas3	= generate_gm_sex_partners(get_gm_sex_partners, Ver),
	FunDatas4	= generate_gm_all_partners(get_gm_all_partners, Ver),
	FunDatas5	= generate_gm_type_map(get_gm_type_map, Ver),
	FunDatas6	= generate_gm_keys(get_gm_keys, Ver),
	FunDatas7	= generate_gm_camp_goods(get_gm_camp_goods, Ver),
	FunDatas8	= generate_all_horse(get_all_horse, Ver),
	FunDatas9	= generate_gm_color_partners(get_gm_color_partners, Ver),
	misc_app:write_erl_file(data_gm,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl",
							 "../../include/record.goods.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, 
                             FunDatas5, FunDatas6, FunDatas7, FunDatas8,
                             FunDatas9], Ver).

%%
%% Local Functions
%%

%% gm_data_generator:generate_gm_goods(get_gm_goods).
generate_gm_goods(FunName, Ver) ->
	Datas	=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/goods/goods.equip.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	LvList	= lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
	ProList	= lists:seq(?CONST_SYS_PRO_XZ, ?CONST_SYS_PRO_JH),
	SexList	= lists:seq(?CONST_SYS_SEX_MALE, ?CONST_SYS_SEX_FAMALE),
	Acc		= generate_gm_goods(LvList, ProList, SexList, Datas, []),
	{FunName, Acc}.
generate_gm_goods([Lv | LvList], ProList, SexList, Datas, Acc)	->
	NewAcc	= generate_gm_goods(Lv, ProList, SexList, Datas, Acc),
	generate_gm_goods(LvList, ProList, SexList, Datas, NewAcc);
generate_gm_goods([], _ProList, _SexList, _Datas, Acc)			->
	Acc;
generate_gm_goods(Lv, [Pro | ProList], SexList, Datas, Acc)
  when is_integer(Lv)	->
	NewAcc	= generate_gm_goods(Lv, Pro, SexList, Datas, Acc),
	generate_gm_goods(Lv, ProList, SexList, Datas, NewAcc);
generate_gm_goods(Lv, [], _SexList, _Datas, Acc)
  when is_integer(Lv)	->
	Acc;
generate_gm_goods(Lv, Pro, [Sex | SexList], Datas, Acc)
  when is_integer(Lv) andalso is_integer(Pro)	->
	NewAcc	= generate_gm_goods(Lv, Pro, Sex, Datas, Acc),
	generate_gm_goods(Lv, Pro, SexList, Datas, NewAcc);
generate_gm_goods(Lv, Pro, [], _Datas, Acc)
  when is_integer(Lv) andalso is_integer(Pro)	->
	Acc;
generate_gm_goods(Lv, Pro, Sex, Datas, Acc)
  when is_integer(Lv) andalso is_integer(Pro) andalso is_integer(Sex)	->
	Key		= {Lv, Pro, Sex},
	Goods	= [Data || Data <- Datas,
					   is_record(Data, rec_goods_equip),
					   Data#rec_goods_equip.lv =< Lv,
					   (Data#rec_goods_equip.pro =:= ?CONST_SYS_PRO_NULL orelse Data#rec_goods_equip.pro =:= Pro),
					   (Data#rec_goods_equip.sex =:= ?CONST_SYS_SEX_NULL orelse Data#rec_goods_equip.sex =:= Sex)],
	GMGoods	= generate_gm_goods_2(Goods, []),
	Value	= [{GMGood#rec_goods_equip.goods_id, 1} || GMGood <- GMGoods, is_record(GMGood, rec_goods_equip)],
	When	= ?null,
	[{Key, Value, When} | Acc].

generate_gm_goods_2([Goods | GoodsList], Acc)	->
	SubType	= Goods#rec_goods_equip.subtype,
	NewAcc	= case lists:keyfind(SubType, #rec_goods_equip.subtype, Acc) of
				  Tuple when is_record(Tuple, rec_goods_equip)
					andalso (Goods#rec_goods_equip.lv > Tuple#rec_goods_equip.lv orelse Goods#rec_goods_equip.color > Tuple#rec_goods_equip.color)	->
					  lists:keyreplace(SubType, #rec_goods_equip.subtype, Acc, Goods);
				  ?false	->
					  [Goods | Acc];
				  _Other	->
					  Acc
			  end,
	generate_gm_goods_2(GoodsList, NewAcc);
generate_gm_goods_2([], Acc)	->
	Acc.

%% gm_data_generator:generate_gm_type_partners(get_gm_type_partners).
generate_gm_type_partners(FunName, Ver) ->
	Datas		=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	TypeList	= lists:seq(?CONST_PARTNER_TYPE_STORY, ?CONST_PARTNER_TYPE_LOOK),
	Acc			= generate_gm_type_partners(TypeList, Datas, []),
	{FunName, Acc}.
generate_gm_type_partners([Type | TypeList], Datas, Acc)	->
	Key			= Type,
	Value		= [Data#rec_partner.partner_id || Data <- Datas,
												  is_record(Data, rec_partner),
												  Data#rec_partner.type =:= Type],
	When		= ?null,
	NewAcc		= [{Key, Value, When} | Acc],
	generate_gm_type_partners(TypeList, Datas, NewAcc);
generate_gm_type_partners([], _Datas, Acc)	->	Acc.

%% gm_data_generator:generate_gm_sex_partners(get_gm_sex_partners).
generate_gm_sex_partners(FunName, Ver) ->
	Datas	=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	SexList	= lists:seq(?CONST_SYS_SEX_MALE, ?CONST_SYS_SEX_FAMALE),
	Acc		= generate_gm_sex_partners(SexList, Datas, []),
	{FunName, Acc}.
generate_gm_sex_partners([Sex | SexList], Datas, Acc)	->
	Key		= Sex,
	Value	= [Data#rec_partner.partner_id || Data <- Datas,
											  is_record(Data, rec_partner),
											  Data#rec_partner.sex =:= Sex],
	When	= ?null,
	NewAcc	= [{Key, Value, When} | Acc],
	generate_gm_sex_partners(SexList, Datas, NewAcc);
generate_gm_sex_partners([], _Datas, Acc)	->	Acc.

%% gm_data_generator:generate_gm_all_partners(get_gm_all_partners).
generate_gm_all_partners(FunName, Ver)	->
	Datas	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.yrl"),
	generate_gm_all_partners(FunName, Datas, []).
generate_gm_all_partners(FunName, [Data | Datas], [])	->
	Key		= ?null,
	Value	= [Data#rec_partner.partner_id],
	When	= ?null,
	Acc		= [{Key, Value, When}],
	generate_gm_all_partners(FunName, Datas, Acc);
generate_gm_all_partners(FunName, [Data | Datas], [{Key, Value, When}])	->
	NewValue	= [Data#rec_partner.partner_id | Value],
	NewAcc		= [{Key, NewValue, When}],
	generate_gm_all_partners(FunName, Datas, NewAcc);
generate_gm_all_partners(FunName, [], Acc)	->
	NewAcc	= lists:reverse(Acc),
	{FunName, NewAcc}.

%% gm_data_generator:generate_gm_type_map(get_gm_type_map).
generate_gm_type_map(FunName, Ver) ->
	Datas		=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/map/map.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	TypeList	= lists:seq(?CONST_MAP_TYPE_CITY, ?CONST_MAP_TYPE_MCOPY),
	Acc			= generate_gm_type_map(TypeList, Datas, []),
	{FunName, Acc}.
generate_gm_type_map([Type | TypeList], Datas, Acc)	->
	Key			= Type,
	Value		= [Data#rec_map.map_id || Data <- Datas,
										  is_record(Data, rec_map),
										  Data#rec_map.type =:= Type],
	When		= ?null,
	NewAcc		= [{Key, Value, When} | Acc],
	generate_gm_type_map(TypeList, Datas, NewAcc);
generate_gm_type_map([], _Datas, Acc)	->	Acc.

%% gm_data_generator:generate_gm_keys(get_gm_keys).
generate_gm_keys(FunName, Ver) ->
	Datas	=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/resource/rune.chest.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	Key		= ?null,
	Value	= [{Dat#rec_rune_chest.key_id, 99} || Dat <- Datas, is_record(Dat, rec_rune_chest)],
	When	= ?null,
	Acc		= [{Key, Value, When}],
	{FunName, Acc}.

%% gm_data_generator:generate_gm_camp_goods(get_gm_camp_goods).
generate_gm_camp_goods(FunName, Ver) ->
	Datas	=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp/camp.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	Key		= ?null,
	Value	= [{Dat#rec_camp.goods_id, ?CONST_GOODS_UNBIND, 1} || Dat <- Datas, is_record(Dat, rec_camp), Dat#rec_camp.goods_id =/= 0],
	When	= ?null,
	Acc		= [{Key, Value, When}],
	{FunName, Acc}.

%% 
generate_all_horse(FunName, Ver) ->
    Datas           = misc_app:get_data_list(Ver++"/goods/goods.equip.yrl"),
    Key             = ?null,
    Value           = [{Gid, 0, 1}|| #rec_goods_equip{goods_id = Gid, subtype = ?CONST_GOODS_EQUIP_HORSE}<- Datas],
    When            = ?null,
    {FunName, [{Key, Value, When}]}.
    
%% gm_data_generator:generate_gm_color_partners(get_gm_color_partners).
generate_gm_color_partners(FunName, Ver) ->
	Datas	=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	ColorList	= [1,2,3,4,5,6,7],
	Acc		= generate_gm_color_partners(ColorList, Datas, []),
	{FunName, Acc}.
generate_gm_color_partners([Sex | SexList], Datas, Acc)	->
	Key		= Sex,
	Value	= [Data#rec_partner.partner_id || Data <- Datas,
											  is_record(Data, rec_partner),
											  Data#rec_partner.color =:= 7],
	When	= ?null,
	NewAcc	= [{Key, Value, When} | Acc],
	generate_gm_color_partners(SexList, Datas, NewAcc);
generate_gm_color_partners([], _Datas, Acc)	->	Acc.