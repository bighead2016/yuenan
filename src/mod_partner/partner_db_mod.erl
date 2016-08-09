%% Author: Administrator
%% Created: 2012-7-26
%% Description: TODO: Add description to pet_db_mod
-module(partner_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([write_partner/2, read_partner/1]).

%%
%% API Functions
%%

write_partner(UserId, PartnerTuple) ->
	BinPartner      = mysql_api:encode(PartnerTuple),
	?MSG_PRINT("BinPartner ~n~ts~n", [BinPartner]),
	mysql_api:fetch(<<"UPDATE `game_player` SET ",
					  " `partner` = ",     BinPartner/binary,
						" WHERE `user_id` = ", (misc:to_binary(UserId))/binary, ";">>),
	ok.

read_partner(UserId) ->
	case mysql_api:select_execute(<<"SELECT ",
									"`partner` ",
                                    "FROM  `game_player` WHERE `user_id` = ",
                                    (misc:to_binary(UserId))/binary, ";">>) of
        {?ok, [BinPartner]} ->
			?MSG_PRINT("BinPet ~n~p~n", [BinPartner]),
            PartnerData     = mysql_api:decode(BinPartner),
			?MSG_PRINT("PartnerData ~n~p~n", [PartnerData]),
            {?ok, {PartnerData}};
        Other ->
			?MSG_PRINT("Other ~n~p~n", [Other]),
            {?ok, ?null}
    end.

%%
%% Local Functions
%%

