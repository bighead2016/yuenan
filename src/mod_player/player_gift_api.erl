%% Author: cobain
%% Created: 2013-6-15
%% Description: TODO: Add description to player_gift_api
-module(player_gift_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%%
%% Exported Functions
%%
-export([get_gift/3, get_gift_reward/4]).
-export([generate_code/3, get_code_type/1, generate_code_festival/2, get_code_type_festival/1]).
-export([reward_gift/1,reward_gift_goods/1]).
%%
%% API Functions
%%

%%=====================================激活码============================================
%% 各种平台自己算的激活码入口 -- 纯算法校验
%% 1:新手礼包
%% get_gift(Player, ?CONST_PLAYER_GIFT_TYPE_COMMON, Code) ->
%% 	CodeUpper	= string:to_upper(misc:to_list(Code)),
%%     case get_code_type(Code) of
%%         ?CONST_PLAYER_GIFT_TYPE_COMMON -> {?error, ?TIP_COMMON_BAD_SING};
%%         CodeType when is_number(CodeType) ->
%%             get_gift(Player, CodeType, Code);
%%         {?error, ErrorCode} -> {?error, ErrorCode}
%%     end;

%% 用来发全服补偿的
reward_gift_goods(GoodsId) ->
    UserNameList = get_user_name_list(),
    Title = "Quà nạp đầu",
    Content = "Quà nạp lần đầu",
    Fun = fun(UserName) -> 
        do_reward_goods(UserName,GoodsId)
    end,
    Result  = lists:map(Fun, UserNameList).



do_reward_goods(UserName,GoodsId) ->
    Title = "Quà nạp đầu",
    Content = "Quà nạp lần đầu",
    case mysql_api:select_execute(<<"SELECT `account`, `user_id`, `reg_time`, `lv`,",
                                    "`login_ip`, `login_time_last`, `pro`, `sex`, `cash`, `cash_bind`, `gold_bind` FROM `game_user`",
                                    " WHERE `user_name` = '", (misc:to_binary(UserName))/binary, "';">>) of
        {?ok, [[Account, UserId, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex, Cash, CashBind, GoldBind]]} ->
            case  player_api:get_player_fields(UserId, [#player.info]) of
                {?ok,[Info]} ->
                     GoodsList = goods_api:make(GoodsId, 1),
                     {UserName, mail_api:send_system_mail_to_one3(UserName, Title, Content, 0, [], GoodsList, 0, 0, 
                                                                          0, ?CONST_COST_PLAYER_GM, 0)};
                _ ->
                    void
            end;
        _ ->
            void
    end.

%% 用来发全服补偿的
do_reward(UserName,GiftType) ->
    Title = "Quà nạp đầu",
    Content = "Quà nạp lần đầu",
    case mysql_api:select_execute(<<"SELECT `account`, `user_id`, `reg_time`, `lv`,",
                                    "`login_ip`, `login_time_last`, `pro`, `sex`, `cash`, `cash_bind`, `gold_bind` FROM `game_user`",
                                    " WHERE `user_name` = '", (misc:to_binary(UserName))/binary, "';">>) of
        {?ok, [[Account, UserId, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex, Cash, CashBind, GoldBind]]} ->
            case  player_api:get_player_fields(UserId, [#player.info]) of
                {?ok,[Info]} ->
                     GoodsList = get_goods(Info#info.pro,Info#info.sex,GiftType),
                     {UserName, mail_api:send_system_mail_to_one3(UserName, Title, Content, 0, [], GoodsList, 0, 0, 
                                                                          0, ?CONST_COST_PLAYER_GM, 0)};
                _ ->
                    void
            end;
        _ ->
            void
    end.
    
%% 用来发全服补偿的
reward_gift(GiftType) ->
    UserNameList = get_user_name_list(),
    Title = "Quà nạp đầu",
    Content = "Quà nạp lần đầu",
    Fun = fun(UserName) -> 
        do_reward(UserName,GiftType)
    end,
    Result  = lists:map(Fun, UserNameList).


get_goods(Pro,Sex,GiftType)->
    Gift = data_player:get_player_gift(GiftType),
    GoodsData = Gift#rec_player_gift.goods,
    Fun         = fun({GoodsId, Bind, Count}, AccGoods) ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({?CONST_SYS_PRO_NULL, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({ProTmp, SexTmp, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro andalso SexTmp =:= Sex ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({?CONST_SYS_PRO_NULL, SexTmp, GoodsId, Bind, Count}, AccGoods) when SexTmp =:= Sex ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({ProTmp, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     (_, AccGoods) -> AccGoods
                  end,
    GoodsList   = lists:foldl(Fun, [], GoodsData),
    GoodsList.

%% 所有玩家列表
get_user_name_list() ->
    case mysql_api:select_execute(<<"SELECT `user_name` FROM `game_user` WHERE `exist` = 1;">>) of
        {?ok, []} -> [];
        {?ok, NameList} -> lists:map(fun([Name]) -> Name end, NameList);
        _Other -> []
    end.

%% 各种激活码入口
get_gift(Player, GiftTypeX, Code) ->
    %%?MSG_ERROR("gift code:~p   ~p  ~n",[GiftTypeX,Code]),
    CodeUpper	= string:to_upper(misc:to_list(Code)),
    case center_api:chk_gift(CodeUpper) of
        {?ok, GiftType, Gift} ->
            case get_gift_2(Player, GiftType, Gift, CodeUpper) of
                {?ok, Player2} ->
                    {?ok, Player2};
                {?error, ErrorCode} -> 
                    center_api:rollback(CodeUpper),
                    {?error, ErrorCode}
            end;
        Error ->
            ?MSG_ERROR("Center code err:~p~n",[Error]),
            try
                Len =  erlang:length(CodeUpper),
                GiftTypeX21 = 
                    if
                        Len > 0 ->
                            try
                                misc:to_integer([erlang:hd(CodeUpper)])
                            catch
                                _:_ ->
                                    ?CONST_PLAYER_GIFT_TYPE_PHONE
                            end;
                        ?true ->
                            GiftTypeX
                    end,
                GiftTypeX2 = 
                    case GiftTypeX21 < 10 of
                        true ->
                            GiftTypeX21+200;
                        false ->
                            GiftTypeX21
                    end,
                GiftTypeX3 = 
                    try
                        ?ok = check_get_gift_code(Player, GiftTypeX2, Code, CodeUpper),
                        GiftTypeX2
                    catch
                        _:_ ->
                            ?ok = check_get_phone_gift_code(Player, CodeUpper),
                            ?CONST_PLAYER_GIFT_TYPE_PHONE
                    end,
                Gift = data_player:get_player_gift(GiftTypeX3),
                case get_gift_2(Player, GiftTypeX3, Gift, CodeUpper) of
                    {?ok, Player2} ->
                        {?ok, Player2};
                    {?error, ErrorCode} -> 
                        {?error, ErrorCode}
                end
            catch 
                X:Y ->
                    %%?MSG_ERROR("code 1[~p|~p|~n~p]", [X, Y, erlang:get_stacktrace()]),
                    {?error, ?TIP_COMMON_BAD_SING}
            end
    end.
get_gift_2(Player, GiftType, Gift, Code) ->
    case check_get_gift(Player, GiftType) of
        ?ok ->
            Point	= get_gift_point(GiftType),
            case get_gift_reward(Player, Gift, Point,Code) of
                ?ok ->
                    {?ok, Player3}	= get_gift_reward_final(Player, GiftType, Code),
                    PacketGifts		= player_api:msg_sc_get_gift_info((Player3#player.info)#info.gifts),
                    PacketSuccess	= message_api:msg_notice(?TIP_PLAYER_GET_GIFT_SUCCESS),
                    misc_packet:send(Player3#player.net_pid, <<PacketSuccess/binary, PacketGifts/binary>>),
                    case GiftType of
                        ?CONST_PLAYER_GIFT_TYPE_MAIDEN ->
                            TipPacket = message_api:msg_notice(?TIP_PLAYER_GIFT_GOODS, 
                                                               [{Player#player.user_id,(Player3#player.info)#info.user_name}], 
                                                               [], 
                                                               [{?TIP_SYS_COMM,<<"首充礼包">>},{?TIP_SYS_GIFT,misc:to_list(GiftType)}]), 
                            misc_app:broadcast_world(TipPacket);
                        _ -> ?ok
                    end,
                    {?ok, Player3};
                {?ok, Player2, PacketBag} ->
                    {?ok, Player3}  = get_gift_reward_final(Player2, GiftType, Code),
                    PacketGifts     = player_api:msg_sc_get_gift_info((Player3#player.info)#info.gifts),
                    PacketSuccess   = message_api:msg_notice(?TIP_PLAYER_GET_GIFT_SUCCESS),
                    misc_packet:send(Player3#player.net_pid, <<PacketSuccess/binary, PacketBag/binary, PacketGifts/binary>>),
                    case GiftType of
                        ?CONST_PLAYER_GIFT_TYPE_MAIDEN ->
                            TipPacket = message_api:msg_notice(?TIP_PLAYER_GIFT_GOODS, 
                                                               [{Player#player.user_id,(Player3#player.info)#info.user_name}], 
                                                               [], 
                                                               [{?TIP_SYS_COMM,<<"首充礼包">>},{?TIP_SYS_GIFT,misc:to_list(GiftType)}]), 
                            misc_app:broadcast_world(TipPacket);
                        _ -> ?ok
                    end,
                    {?ok, Player3};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

%% 检查领取礼包条件
check_get_gift(Player, GiftType) ->
    try
        ?ok		= check_get_gift_record((Player#player.info)#info.gifts, GiftType),
        ?ok		= check_get_gift_ext(Player, GiftType),
        ?ok
    catch
        throw:Return -> Return;
        Error:Reason ->
            % ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_SING}
    end.

%% 检查是否已领取过该类型礼包
check_get_gift_record(GiftList, GiftType) ->
    case lists:member(GiftType, GiftList) of
        ?false -> ?ok;
        ?true -> throw({?error, ?TIP_PLAYER_ALREADY_GET_GIFT})
    end.

%% 检查激活码ets_api:lookup(ets_sys, key).
% 角色礼包类型：新手礼包 
check_get_gift_code(Player, ?CONST_PLAYER_GIFT_TYPE_NEWBIE, _Code, CodeUpper) ->
    CodeType	= misc:to_list(?CONST_PLAYER_GIFT_TYPE_NEWBIE),
    CodeStr		= misc:to_list(CodeUpper),
    case generate_code(CodeType, Player#player.serv_id, Player#player.account) of
        CodeStr -> 
            ?ok;% 验证通过，发放奖励
        X -> 
            case string:to_upper(misc:to_list(X)) of
                CodeStr ->
                    ?ok;% 验证通过，发放奖励
                _ ->
                    ?MSG_ERROR("1[~p|~p|~p]", [CodeUpper, X, {CodeType, Player#player.serv_id, Player#player.account}]),
                    throw({?error, ?TIP_COMMON_BAD_SING})% 验证失败
            end
    end;
% 角色礼包类型：收藏礼包 
check_get_gift_code(_Player, ?CONST_PLAYER_GIFT_TYPE_COLLECT, _Code, CodeUpper) ->
    case CodeUpper of
        [] -> ?ok;
        _ -> throw({?error, ?TIP_COMMON_BAD_SING})
    end;
% 角色礼包类型：首冲礼包
check_get_gift_code(_Player, ?CONST_PLAYER_GIFT_TYPE_MAIDEN, _Code, CodeUpper) ->
    case CodeUpper of
        [] -> ?ok;
        _ -> throw({?error, ?TIP_COMMON_BAD_SING})
    end.

% 角色礼包类型：手机绑定礼包 
check_get_phone_gift_code(Player, Code) ->
    %%     CodeType    = misc:to_list(?CONST_PLAYER_GIFT_TYPE_PHONE),
    CodeStr     = misc:to_list(Code),
    SId = lists:concat(["S", Player#player.serv_id]),
    Account = lists:concat([misc:to_list(Player#player.account), "sj"]),
    case generate_code("", SId, Account) of
        CodeStr -> ?ok;% 验证通过，发放奖励
        C -> 
            case string:to_upper(misc:to_list(C)) of
                CodeStr ->
                    ?ok;% 验证通过，发放奖励
                _ ->
                    ?MSG_ERROR("1[~p|~p|~p]", [C, CodeStr, {?CONST_PLAYER_GIFT_TYPE_PHONE, Player#player.serv_id, Player#player.account}]),
                    throw({?error, ?TIP_COMMON_BAD_SING})% 验证失败
            end
    end.

%% 额外检查
% 角色礼包类型：首冲礼包
check_get_gift_ext(Player, ?CONST_PLAYER_GIFT_TYPE_MAIDEN) ->
    Code = % 新手卡元宝数
        case config:read_deep([server, base, platform_id]) of
            11 -> 50;
            14 -> 50;
            _  -> 50
        end,
    case player_money_api:read_cash_sum(Player#player.user_id) of
        {?ok, CashSum} when CashSum >= Code -> ?ok;
        {?ok, CashSum} when CashSum < Code -> throw({?error, ?TIP_PLAYER_BAD_CASH_SUM});
        _ -> throw({?error, ?TIP_PLAYER_OLD_MAIDEN})
    end;
check_get_gift_ext(_Player, _CodeType) -> ?ok.

%% 领取礼包最终处理
get_gift_reward_final(Player, ?CONST_PLAYER_GIFT_TYPE_SHOP1, Code) ->
    delete_code(Code),
    {?ok, Player};
get_gift_reward_final(Player, ?CONST_PLAYER_GIFT_TYPE_SHOP2, Code) ->
    delete_code(Code),
    {?ok, Player};
get_gift_reward_final(Player, ?CONST_PLAYER_GIFT_TYPE_SHOP3, Code) ->
    delete_code(Code),
    {?ok, Player};
get_gift_reward_final(Player, ?CONST_PLAYER_GIFT_TYPE_SHOP4, Code) ->
    delete_code(Code),
    {?ok, Player};
get_gift_reward_final(Player, ?CONST_PLAYER_GIFT_TYPE_SHOP5, Code) ->
    delete_code(Code),
    {?ok, Player};
get_gift_reward_final(Player, ?CONST_PLAYER_GIFT_TYPE_MAIDEN, _Code) ->
    Info            = Player#player.info,
    Gifts           = [?CONST_PLAYER_GIFT_TYPE_MAIDEN|Info#info.gifts],
    Info2           = Info#info{gifts = Gifts},
    {?ok, Player#player{info = Info2}};
get_gift_reward_final(Player, CodeType, Code) ->
    Info            = Player#player.info,
    Gifts           = [CodeType|Info#info.gifts],
    Info2           = Info#info{gifts = Gifts},
    delete_code(Code),
    {?ok, Player#player{info = Info2}}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% Local Functions
%%
get_gift_point(?CONST_PLAYER_GIFT_TYPE_NEWBIE) -> ?CONST_COST_GIFT_TYPE_NEWBIE;% 角色礼包类型：新手礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_COLLECT) -> ?CONST_COST_GIFT_TYPE_COLLECT;% 角色礼包类型：收藏礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_PHONE) -> ?CONST_COST_GIFT_TYPE_PHONE;% 角色礼包类型：手机绑定礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_LOGIN_DAILY) -> ?CONST_COST_GIFT_TYPE_LOGIN_DAIL;% 角色礼包类型：每日登陆礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_SUMMER) -> ?CONST_COST_GIFT_TYPE_SUMMER;% 角色礼包类型：夏日礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_ORDER) -> ?CONST_COST_GIFT_TYPE_ORDER;% 角色礼包类型：预约礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MEDIA_4399) -> ?CONST_COST_GIFT_TYPE_MAIDEN;% 角色礼包类型：预约礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MAIDEN) -> ?CONST_COST_GIFT_TYPE_MAIDEN;% 角色礼包类型：首冲礼包 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MEDIA_07073_20) -> ?CONST_COST_GIFT_TYPE_MEDIA_1;% 角色礼包类型：媒体礼包(07073|20) 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MEDIA_07073_30) -> ?CONST_COST_GIFT_TYPE_MEDIA_2;% 角色礼包类型：媒体礼包(07073|30) 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MEDIA_07073_50) -> ?CONST_COST_GIFT_TYPE_MEDIA_3;% 角色礼包类型：媒体礼包(07073|50) 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MEDIA_265G_30) -> ?CONST_COST_GIFT_TYPE_MEDIA_4;% 角色礼包类型：媒体礼包(265G|50) 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MEDIA_BD_20) -> ?CONST_COST_GIFT_TYPE_MEDIA_5;% 角色礼包类型：媒体礼包(百度|20)
get_gift_point(?CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_6) -> ?CONST_COST_GIFT_TYPE_360_6;% 角色礼包类型：夏末礼包188 
get_gift_point(?CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_7) -> ?CONST_COST_GIFT_TYPE_360_7;% 角色礼包类型：夏末礼包188 
get_gift_point(?CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_8) -> ?CONST_COST_GIFT_TYPE_360_8;% 角色礼包类型：夏末礼包188 
get_gift_point(?CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_9) -> ?CONST_COST_GIFT_TYPE_360_9;% 角色礼包类型：夏末礼包188 
get_gift_point(?CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_15) -> ?CONST_COST_GIFT_TYPE_360_15;% 角色礼包类型：夏末礼包188 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_WEIXIN) -> ?CONST_COST_GIFT_TYPE_WEIXIN;% 角色礼包类型：夏末礼包188 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_SUMMER_188) -> ?CONST_COST_GIFT_TYPE_SUMMER_1;% 角色礼包类型：夏末礼包188 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_SUMMER_888) -> ?CONST_COST_GIFT_TYPE_SUMMER_2;% 角色礼包类型：夏末礼包888 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_SUMMER_1888) -> ?CONST_COST_GIFT_TYPE_SUMMER_3;% 角色礼包类型：夏末礼包1888 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_SUMMER_5888) -> ?CONST_COST_GIFT_TYPE_SUMMER_4;% 角色礼包类型：夏末礼包5888 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_SUMMER_10888) -> ?CONST_COST_GIFT_TYPE_SUMMER_5;% 角色礼包类型：夏末礼包10888 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_SUMMER_88888) -> ?CONST_COST_GIFT_TYPE_SUMMER_6;% 角色礼包类型：夏末礼包88888 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MID_AUTUNM) -> ?CONST_COST_GIFT_TYPE_MID_AUTUNM;% 角色礼包类型：夏末礼包88888 
get_gift_point(?CONST_PLAYER_GIFT_TYPE_MEDIA_4399_2) -> ?CONST_COST_GIFT_TYPE_MEDIA_1;% 角色礼包类型：夏末礼包88888 
get_gift_point(_) -> ?CONST_COST_GIT_TYPE_SHOP.% 角色礼包类型：夏末礼包188 


%% 生成MD5激活码
%% player_gift_api:generate_code(1, 1, <<"wx1">>).
%% 激活码类型 + md5(Key + wwsg + 服务器ID + 激活码类型 + 平台账号)
generate_code(CodeType, ServId, Account) ->
    Key			= misc:to_list(config:read(platform_info, #rec_platform_info.login_key)), %config:read_deep([server, release, login_key]),
    CodeTypeStr	= misc:to_list(CodeType),
    CodeBase	= misc:md5(Key ++ "wwsg" ++ misc:to_list(ServId) ++ CodeTypeStr ++ misc:to_list(Account)),
    CodeTypeStr ++ CodeBase.

%% 生成MD5激活码(中秋活动等)
%% player_gift_api:generate_code_festival(1,  <<"wx1">>).
%% 激活码类型 + md5(Key +  平台账号 + 激活码类型)
generate_code_festival(CodeType, Account) ->
    Key			= misc:to_list(config:read(platform_info, #rec_platform_info.login_key)), %config:read_deep([server, release, login_key]),
    CodeTypeStr	= misc:to_list(CodeType),
    CodeBase	= misc:md5(Key  ++  misc:to_list(Account) ++ CodeTypeStr),
    CodeTypeStr ++ CodeBase.

%% 根据激活码获取礼包类型
%% player_gift_api:get_code_type("141f6773fbbfd406d3cf6127e578acc92").
%% player_gift_api:get_code_type(<<"141f6773fbbfd406d3cf6127e578acc92">>).
get_code_type(Code) ->
    try get_code_type_ext(Code)
    catch _Error:_Reason -> {?error, ?TIP_PLAYER_BAD_CODE}
    end.

get_code_type_ext([]) -> {?error, ?TIP_PLAYER_BAD_CODE};% 无效激活码
get_code_type_ext(Code) when is_list(Code) ->
    CodeTypeStr	= lists:sublist(Code, 1),
    misc:to_integer(CodeTypeStr);
get_code_type_ext(<<"">>) -> {?error, ?TIP_PLAYER_BAD_CODE};% 无效激活码
get_code_type_ext(Code) when is_binary(Code) ->
    <<CodeType:1/binary, _Binary/binary>>	= Code,
    misc:to_integer(CodeType).

%% 根据激活码获取礼包类型(节日类型 前两位表示类型)
%% player_gift_api:get_code_type_festival("811167a5cba76152c03bf9462adcfcd565").
%% player_gift_api:get_code_type_festival(<<"811167a5cba76152c03bf9462adcfcd565">>).
get_code_type_festival(Code) ->
    try get_code_type_festival_ext(Code)
    catch _Error:_Reason -> {?error, ?TIP_PLAYER_BAD_CODE}
    end.

get_code_type_festival_ext([]) -> {?error, ?TIP_PLAYER_BAD_CODE};% 无效激活码
get_code_type_festival_ext(Code) when is_list(Code) ->
    CodeTypeStr	= lists:sublist(Code, 2),
    misc:to_integer(CodeTypeStr);
get_code_type_festival_ext(<<"">>) -> {?error, ?TIP_PLAYER_BAD_CODE};% 无效激活码
get_code_type_festival_ext(Code) when is_binary(Code) ->
    <<CodeType:2/binary, _Binary/binary>>	= Code,
    misc:to_integer(CodeType).

%% 
% get_gift_reward(Player, Gift, Point , Code) when  ->
%     UserId		= Player#player.user_id,
%     case get_gift_reward_goods(Player, Gift#rec_player_gift.goods, Point) of
%         {?ok, Player2, PacketBag} ->
%             Player3	= partner_api:give_partner_list(Player2, Gift#rec_player_gift.partner_list, ?CONST_PARTNER_TEAM_IN, 0),
%             get_gift_reward_cash(UserId, Gift#rec_player_gift.cash, Point),
%             get_gift_reward_cash_bind(UserId, Gift#rec_player_gift.cash_bind, Point),
%             get_gift_reward_gold(UserId, Gift#rec_player_gift.gold, Point),
%             {?ok, Player3, PacketBag};
%         {?error, ErrorCode} -> {?error, ErrorCode}
%     end;

%% -- 越南 改成发邮件
%% send_interest_mail_to_one2(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, BCash, Point)
get_gift_reward(Player, Gift, Point,Code) when is_record(Gift, rec_player_gift) ->
    case lists:member(Point,[?CONST_COST_GIFT_TYPE_MAIDEN]) of
        true ->
            UserId     = Player#player.user_id,
            case get_gift_reward_goods(Player, Gift#rec_player_gift.goods, Point) of
                {?ok, Player2, PacketBag} ->
                    Player3 = partner_api:give_partner_list(Player2, Gift#rec_player_gift.partner_list, ?CONST_PARTNER_TEAM_IN, 0),
                    get_gift_reward_cash(UserId, Gift#rec_player_gift.cash, Point),
                    get_gift_reward_cash_bind(UserId, Gift#rec_player_gift.cash_bind, Point),
                    get_gift_reward_gold(UserId, Gift#rec_player_gift.gold, Point),
                    {?ok, Player3, PacketBag};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end;
        false ->
            Info = Player#player.info,
            Name = Info#info.user_name,
            GoodsList = Gift#rec_player_gift.goods,
            GoodsList2 =lists:flatten([goods_api:make(GoodsId, Bind, Count)||{GoodsId,Bind,Count}<-GoodsList]), 
            Title = "Phần Thưởng Mã Kích Hoạt",
            Content = io_lib:format("Đây là Túi quà thông qua Mã Kích Hoạt ~p（~p）", [Gift#rec_player_gift.gift_type,Code]),
            mail_api:send_interest_mail_to_one2(Name, Title, Content, 0, [],GoodsList2, 0, 0, 0, Point),
            ?ok
    end.




get_gift_reward_goods(Player, [], _Point) -> {?ok, Player, <<>>};
get_gift_reward_goods(Player = #player{info = #info{pro = Pro, sex = Sex}}, GoodsData, Point) ->
    Fun			= fun({GoodsId, Bind, Count}, AccGoods) ->
                          GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({?CONST_SYS_PRO_NULL, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) ->
                          GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({ProTmp, SexTmp, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro andalso SexTmp =:= Sex ->
                          GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({?CONST_SYS_PRO_NULL, SexTmp, GoodsId, Bind, Count}, AccGoods) when SexTmp =:= Sex ->
                          GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({ProTmp, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro ->
                          GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     (_, AccGoods) -> AccGoods
                  end,
    GoodsList	= lists:foldl(Fun, [], GoodsData),
    case ctn_bag_api:put(Player, GoodsList, Point, 1, 1, 0, 0, 0, 1, []) of
        {?ok, Player2, _, PacketBag} ->
            {?ok, Player2, PacketBag};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

get_gift_reward_cash(_UserId, 0, _Point) -> ?ok;
get_gift_reward_cash(UserId, Cash, Point) ->
    player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, Point).

get_gift_reward_cash_bind(_UserId, 0, _Point) -> ?ok;
get_gift_reward_cash_bind(UserId, CashBind, Point) ->
    player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, CashBind, Point).

get_gift_reward_gold(_UserId, 0, _Point) -> ?ok;
get_gift_reward_gold(UserId, Gold, Point) ->
    player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, Point).

delete_code(Code) ->
    center_api:del_code(Code).
