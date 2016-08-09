%% Author: Administrator
%% Created: 2014-2-26
%% Description: TODO: Add description to trans_partner
-module(trans_partner).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").
-include("record.task.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([trans_partner_soul/0]).

%%
%% API Functions
%%
%%-------------------------------------------------------------------------------------------------
%% 更改player中partner结构以及初始化partner_soul
trans_partner_soul() ->
    misc_sys:init(),
    mysql_api:start(),
   	?MSG_PRINT("change partner_soul start~p: ...", [?LINE]),
	case mysql_api:select_execute(<<"SELECT ",
									" `user_id`, `partner`", 
                                    "  FROM `game_player` ;">>) of
		{?ok, PlayerData} ->
			Len = erlang:length(PlayerData),
			change_partner_soul_ext(PlayerData, Len, 1);
		Error ->
			?MSG_PRINT("change partner_soul Error:~p ...",[Error])
	end,
	erlang:halt().

change_partner_soul_ext([[UserId, Partner]|TailData], Len, NowIdx) ->
	PartnerDecode		= mysql_api:decode(Partner),
	PartnerData			= partner_unzip(PartnerDecode),
	PartnerList			= PartnerData#partner_data.list,
	io:format("~p/~p\r", [NowIdx, Len]),
	PartnerList1		= open_partner_soul(PartnerList, PartnerList),
	NewPartnerData 		= PartnerDecode#partner_data{list = PartnerList1},
	ZipPartnerData		= partner_zip(NewPartnerData),
	BinPartner   		= mysql_api:encode(ZipPartnerData),
	PartnerSoul			= #partner_soul{exp = 0, lv = 0, skill_lv = 0, star_lv = 0, skill_id = 0},
	BinPartnerSoul		= mysql_api:encode(PartnerSoul),
	mysql_api:fetch_cast(<<"UPDATE `game_player` SET ",  
                            "  `partner`      	= ", BinPartner/binary,
						    " ,`partner_soul`   = ", BinPartnerSoul/binary,
						    " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>),
	change_partner_soul_ext(TailData, Len, NowIdx +1);
change_partner_soul_ext([], _, _) -> ?ok.

open_partner_soul([Partner|Tail], PartnerList) when is_record(Partner, partner) ->
	?MSG_PRINT("~p\r", [length(PartnerList)]),
	Id					= Partner#partner.partner_id,
	PartnerSoul			= #partner_soul{lv = 0, exp = 0, star_lv = 0, skill_lv = 0, skill_id = 0},
	NewPartner			= Partner#partner{partner_soul = PartnerSoul},
	PartnerList1		= lists:keyreplace(Id, #partner.partner_id, PartnerList, NewPartner),
	open_partner_soul(Tail, PartnerList1);
open_partner_soul([_Partner|Tail], PartnerList) ->
	?MSG_PRINT("~p\r", [length(PartnerList)]),
	open_partner_soul(Tail, PartnerList);
open_partner_soul([], PartnerList) ->
	?MSG_PRINT("~p\r", [length(PartnerList)]),
	PartnerList.	

%% 存储时去掉静态数据
partner_zip(PartnerData = #partner_data{list = List}) ->
	ZipList = partner_zip(List, []),
	PartnerData#partner_data{list = ZipList}.

partner_zip([], ResultList) ->
	ResultList;
partner_zip([#partner{
			 partner_id 		= PartnerId,
			 lv 				= Lv,	
			 hp 				= Hp, 
			 attr				= Attr,
			 attr_group			= AttrGroup,
			 attr_rate_group    = AttrRateGroup,
			 attr_assist		= AttrAssist,
			 attr_sum			= AttrSum,
			 attr_reflect_sum   = AttrReflectSum,
			 train				= Train,
			 anger 				= Anger, 
			 team 				= Team,
			 power 				= Power,
			 is_skipper 		= IsSkipper,
			 assist 			= Assist,
			 is_recruit		    = IsRecruit,
			 partner_soul		= PartnerSoul} | TailList], ResultList) ->
	NewResultList = [{PartnerId, Lv, Hp, Attr, AttrGroup, AttrRateGroup, AttrAssist, AttrSum, AttrReflectSum,
					  Train,  Anger, Team, Power, IsSkipper, Assist, IsRecruit, PartnerSoul} | ResultList],
	partner_zip(TailList, NewResultList).


%% 读取武将时恢复数据
partner_unzip(PartnerData = #partner_data{  
										    list = ZipList
										 }) ->
	UnZipList        = partner_unzip(ZipList, []),
	PartnerData#partner_data{list = UnZipList}.

partner_unzip([{PartnerId, Lv, Hp, Attr, AttrGroup, AttrRateGroup, AttrAssist, AttrSum, AttrReflectSum,
				Train, Anger, Team, Power, IsSkipper, Assist, IsRecruit, PartnerSoul} | TailList], ResultList) ->
	NewResultList =
		case data_partner:get_base_partner(PartnerId) of
			BasePartner when is_record(BasePartner, partner) ->
				Partner = BasePartner#partner{
											  	 partner_id 		= PartnerId,
												 lv 				= Lv,	
												 hp 				= Hp, 
												 attr				= Attr,
												 attr_group			= AttrGroup,
												 attr_rate_group    = AttrRateGroup,
			 									 attr_assist		= AttrAssist,
												 attr_sum			= AttrSum,
												 attr_reflect_sum   = AttrReflectSum,
												 train      		= Train,
												 anger 				= Anger, 
												 team 				= Team,
												 power 				= Power,
												 is_skipper 		= IsSkipper,
												 assist				= Assist,
												 is_recruit		    = IsRecruit,
												 partner_soul 		= PartnerSoul
											 },
				[Partner | ResultList];
			_ ->
				ResultList
		end,
	partner_unzip(TailList, NewResultList);
partner_unzip([{PartnerId, Lv, Hp, Attr, AttrGroup, AttrRateGroup, AttrAssist, AttrSum, AttrReflectSum,
				Train, Anger, Team, Power, IsSkipper, Assist, IsRecruit}|TailList], ResultList) ->
	NewResultList =
		case data_partner:get_base_partner(PartnerId) of
			BasePartner when is_record(BasePartner, partner) ->
				Partner = BasePartner#partner{
											  	 partner_id 		= PartnerId,
												 lv 				= Lv,	
												 hp 				= Hp, 
												 attr				= Attr,
												 attr_group			= AttrGroup,
												 attr_rate_group    = AttrRateGroup,
			 									 attr_assist		= AttrAssist,
												 attr_sum			= AttrSum,
												 attr_reflect_sum   = AttrReflectSum,
												 train      		= Train,
												 anger 				= Anger, 
												 team 				= Team,
												 power 				= Power,
												 is_skipper 		= IsSkipper,
												 assist				= Assist,
												 is_recruit		    = IsRecruit
											 },
				[Partner | ResultList];
			_ ->
				ResultList
		end,
	partner_unzip(TailList, NewResultList);
partner_unzip([], List) ->
	List.
