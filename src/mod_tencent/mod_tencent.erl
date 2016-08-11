
-module(mod_tencent).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").

-include("tencent.hrl").
%%
%% Exported Functions
%%
-export([
         is_login/1,
         client_get_tencent_info/1,
		 client_deposit/4,
         check_login/1,
         deposit_check/0,
         deposit_check_none/0,
         make_agrs/1,
         get_packet/2,
         get_vip_info/1,
         mark_invite/2,
         check_invite/1,
         send_invite_info/1,
         take_invite_award/2,
         do_market/0,
         do_player_market/2,
         finish_task/2,
         robot_lv_up/1
	     ]).

%%
%% API Functions
%%

robot_lv_up(Player) ->
    guide_finish(Player).


guide_finish(Player) ->
    Guide   = Player#player.guide,
    Fun = fun(Tuple) ->
        if 
            is_record(Tuple, guide) ->
                Tuple#guide{state = 1};
            true ->
                Tuple
        end
    end,
    Player#player{guide = lists:map(Fun,Guide)}.




client_deposit(Player, Money,Pfkey,GoodsUrl) ->
	case misc:https_request(Player#player.user_id,"/v3/pay/buy_goods",
		   [{"pfkey",misc:to_list(Pfkey)},
		    {"ts",misc:to_list(misc:seconds())},
			{"payitem","1*"++integer_to_list(Money)++"*1"},
			{"goodsmeta","yuanbao*cash"},
            {"appmode","1"},
			{"goodsurl",misc:to_list("http://1251146242.cdn.myqcloud.com/1251146242/s1/zqsg/Resource/zh_CN/res/tx/item_3.jpg")},
			{"zoneid",misc:to_list(Player#player.serv_id)}
			]) of
        {ok, XmlContent} ->
            ?MSG_DEBUG("pay check reply = ~p", [XmlContent]),
            {Element,_} = xmerl_scan:string(XmlContent),
            case misc:get_xml_value("/data/ret",Element) of
                "0"->
                    Token = misc:get_xml_value("/data/token",Element),
                    Url  = misc:get_xml_value("/data/url_params",Element),
                    ?MSG_DEBUG("pay token= ~p;Url = ~p", [Token,Url]),
                    ets_api:insert(?CONST_ETS_TENCENT_PAY_TOKEN,#ets_tencent_pay_token
                                                                {
                                                                    token         = Token,   
                                                                    user_id         =  Player#player.user_id,
                                                                    account         =  misc:to_list(Player#player.account),
                                                                    crash           = Money
                                                                }),

                    Packet = misc_packet:pack(?MSG_ID_TENCENT_DEPOSIT_RETURN, ?MSG_FORMAT_TENCENT_DEPOSIT_RETURN, [Url]),
                    {?ok,Player,Packet};
                Code ->
                    send_err(Player,misc:get_xml_value("/data/msg",Element)),
                    ?MSG_ERROR("pay check error,code = ~p,content= ~p", [Code,XmlContent]),
                    {?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK}
            end;
        Other ->
            send_err(Player,"连接平台失败,请稍后再尝试"),
            ?MSG_ERROR("pay check err = ~p", [Other]),
            {?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK}
    end.





% PayNum      = get_value("pay_num"),
%     Account     = misc:to_binary(http_uri:decode(get_value("account"))),
%     Money       = 0, % misc:to_integer(get_value("money")),
%     Cash        = misc:to_integer(get_value("cash")),
%     Time        = misc:to_integer(get_value("time")),
%     PayType     = misc:to_integer(get_value("pay_type")),
%     ServId      = misc:to_integer(get_value("serv_id")),


% http://ip/cgi-bin/temp.py?openid=test001&
% appid=33758&ts=1328855301&payitem=323003*8*1&token=53227955F80B805B50FFB511E5AD51E025360&
% billno=-APPDJT18700-20120210-1428215572&version=v3&zoneid=1&providetype=0&amt=80&payamt_coins=20&
% pubacct_payamt_coins=10&sig=VvKwcaMqUNpKhx0XfCvOqPRiAnU%3D

% amt: 80
% appid: 33758
% billno: -APPDJT18700-20120210-1428215572 (计算sig时，本接口billno中的“-”符号必需手动转换成%2D)
% openid: test001
% payamt_coins: 20
% payitem: 323003*8*1
% ts: 1328855301
% providetype: 0
% pubacct_payamt_coins: 10
% token: 53227955F80B805B50FFB511E5AD51E025360
% version: v3
% zoneid: 1


deposit_check() ->
    Token = misc:to_list(get("token")),
    case ets_api:lookup(?CONST_ETS_TENCENT_PAY_TOKEN, Token) of
        ?null ->
            ?MSG_DEBUG("pay check token null = ~p", [Token]),
            {false,0};
        TokenInfo ->
            UserID = TokenInfo#ets_tencent_pay_token.user_id,
            Account = TokenInfo#ets_tencent_pay_token.account,
            Crash  = TokenInfo#ets_tencent_pay_token.crash,
            ets_api:delete(?CONST_ETS_TENCENT_PAY_TOKEN, Token),
            Time = misc:seconds(),
            ServId = misc:to_integer(get("zoneid")),


            Billno = misc:chage_to_16(misc:to_list(get("billno"))),


            Args = make_agrs(["amt","appid","openid","payamt_coins","payitem","ts","providetype","pubacct_payamt_coins","token","version","zoneid"])++[{"billno",Billno}],

            ?MSG_DEBUG("pay check Args= ~p", [Args]),

            % Sign = misc:make_sign("/pay"++misc:to_list(ServId),Args),
            Sign = misc:make_sign("/pay"++misc:to_list(1),Args),

            PFSign = http_uri:decode(misc:to_list(get("sig"))),

            ?MSG_DEBUG("Sign= ~p,PFSign = ~p", [Sign,PFSign]),

            case Sign == PFSign of
                true ->
                    put("pay_num",misc:to_list(UserID * 10000000000 +Time -1)),
                    put("account",misc:to_list(Account)),
                    put("cash",misc:to_list(Crash)),
                    put("time",misc:to_list(Time)),
                    put("pay_type","1"),
                    put("serv_id",misc:to_list(ServId)),
                    {true,UserID};
                false ->
                    {false,UserID}
            end
    end.


deposit_check_none() ->
    Time = misc:seconds(),
    put("pay_num",misc:to_list(get("billno"))),
    put("account",misc:to_list(get("openid"))),
    put("cash",misc:to_list(get("payamt_coins"))),
    put("money",misc:to_list(get("payitem"))),
    put("time",misc:to_list(Time)),
    put("pay_type","1"),
    put("serv_id",misc:to_list(get("zoneid"))),
    ?ok.

confirm_delivery(UserID,Args) ->
    case misc:https_request(UserID,"/v3/pay/confirm_deliver",Args) of
        {ok, XmlContent} ->
            ?MSG_DEBUG("pay confirm_delivery reply = ~p", [XmlContent]),
            {Element,_} = xmerl_scan:string(XmlContent),
            case misc:get_xml_value("/data/ret",Element) of
                "0"->
                    true;
                _ ->
                    false
            end
    end.



make_agrs(Args) ->
    Fun = fun(Arg) ->
        {Arg,misc:to_list(get(Arg))}
    end,
    lists:map(Fun,Args).


%% 邀请登记
mark_invite(Player,InviteOpenID) ->
    LoginCheckMode = config:read(platform_info, #rec_platform_info.login_check),
    % ?MSG_ERROR("UserID = ~p,InviteOpenID = ~p,LoginCheckMode = ~p",[Player#player.user_id,misc:to_list(InviteOpenID),LoginCheckMode]),
    case LoginCheckMode == ?CONST_SYS_LOGIN_CHECK_TENCENT of
        false ->         %% 有些平台不能返回被邀请信息
            case misc:to_list(InviteOpenID) /= "0" of
                true ->
                    case ets_api:lookup(?CONST_ETS_TENCENT_INVITE_INFO, misc:to_list(Player#player.account)) of
                        ?null ->
                            ets_api:insert(?CONST_ETS_TENCENT_INVITE_INFO,#ets_tencent_invite_info{
                                        today_invite_num = 1,
                                        last_time = misc:seconds(),
                                        open_id      = misc:to_list(Player#player.account),
                                        invite_list  = [{misc:to_list(misc:seconds()),misc:seconds()}]
                                }),
                            misc_packet:send_tips(Player#player.user_id, ?TIP_PARTY_REQUEST_PK);
                        InviteInfo1 ->
                            case misc:check_same_day(InviteInfo1#ets_tencent_invite_info.last_time) of
                                true ->
                                    InviteInfo = InviteInfo1;
                                false ->
                                    InviteInfo = InviteInfo1#ets_tencent_invite_info{today_invite_num = 0,last_time = misc:seconds()},
                                    ets_api:insert(?CONST_ETS_TENCENT_INVITE_INFO,InviteInfo)
                            end,
                            
                            case  InviteInfo#ets_tencent_invite_info.today_invite_num >= 2 of
                                true ->
                                    misc_packet:send_tips(Player#player.user_id, ?TIP_TENCENT_INVITE_MAX);
                                false ->
                                    ets_api:insert(?CONST_ETS_TENCENT_INVITE_INFO,InviteInfo#ets_tencent_invite_info{today_invite_num = InviteInfo#ets_tencent_invite_info.today_invite_num+1,
                                                                                                                     invite_list  = InviteInfo#ets_tencent_invite_info.invite_list++[{misc:to_list(misc:seconds()),misc:seconds()}]
                                        }),
                                    misc_packet:send_tips(Player#player.user_id, ?TIP_PARTY_REQUEST_PK)
                            end
                    end;
                false ->
                    case ets_api:lookup(?CONST_ETS_TENCENT_INVITE_INFO, misc:to_list(Player#player.account)) of
                        ?null ->
                            void;
                        InviteInfo1 ->
                            case misc:check_same_day(InviteInfo1#ets_tencent_invite_info.last_time) of
                                true ->
                                    void;
                                false ->
                                    InviteInfo = InviteInfo1#ets_tencent_invite_info{today_invite_num = 0,last_time = misc:seconds()},
                                    ets_api:insert(?CONST_ETS_TENCENT_INVITE_INFO,InviteInfo)
                            end
                    end
            end;
        true ->
            case ets_api:lookup(?CONST_ETS_TENCENT_INVITE_INFO, misc:to_list(InviteOpenID)) of
                ?null ->
                    ets_api:insert(?CONST_ETS_TENCENT_INVITE_INFO,#ets_tencent_invite_info{
                                                                            open_id      = misc:to_list(InviteOpenID),
                                                                            invite_list  = [{misc:to_list(Player#player.account),misc:seconds()}]
                                                                    });
                InviteInfo ->
                    case lists:keyfind(misc:to_list(Player#player.account),1,InviteInfo#ets_tencent_invite_info.invite_list) of
                        false ->
                            NewInviteList = InviteInfo#ets_tencent_invite_info.invite_list++[{misc:to_list(Player#player.account),misc:seconds()}];
                        _ ->
                            NewInviteList = lists:keyreplace(misc:to_list(Player#player.account),1,InviteInfo#ets_tencent_invite_info.invite_list,{misc:to_list(Player#player.account),misc:seconds()})
                    end,
                    ets_api:update_element(?CONST_ETS_TENCENT_INVITE_INFO,misc:to_list(InviteOpenID),[{#ets_tencent_invite_info.invite_list,NewInviteList}])
            end
    end.

%% 邀请检查
check_invite(Player) ->
    case ets_api:lookup(?CONST_ETS_TENCENT_INVITE_INFO, misc:to_list(Player#player.account)) of
        ?null ->
            Player2 = Player;
        InviteInfo ->
            TencentData = mod_tencent_api:get_tencent_data(Player),
            NewTencentData = merge_inviteInfo(TencentData,InviteInfo),
            Player2 = Player#player{tencent = NewTencentData}
    end,
    Player2.

send_invite_info(Player) ->
    TencentData = mod_tencent_api:get_tencent_data(Player),
    LoginCheckMode = config:read(platform_info, #rec_platform_info.login_check),
    Login5 =
    case LoginCheckMode == ?CONST_SYS_LOGIN_CHECK_TENCENT of
        true ->
            TencentData#tencent_data.login_5;
        false ->
            case ets_api:lookup(?CONST_ETS_TENCENT_INVITE_INFO, misc:to_list(Player#player.account)) of
                ?null ->
                    0;
                InviteInfo ->
                    case  InviteInfo#ets_tencent_invite_info.today_invite_num >= 2 of
                        true ->
                            1;
                        false ->
                            0
                    end
            end
    end,
    Date = [{ID}||ID <- TencentData#tencent_data.share_codes],
    Packet = misc_packet:pack(?MSG_ID_TENCENT_INVITE_INFO, ?MSG_FORMAT_TENCENT_INVITE_INFO, 
        [length(TencentData#tencent_data.invite_list),TencentData#tencent_data.invite_login,
            TencentData#tencent_data.share_step,TencentData#tencent_data.invite_5,TencentData#tencent_data.invite_10,
            TencentData#tencent_data.invite_20,TencentData#tencent_data.invite_40,Login5,Date]),
    % ?MSG_ERROR("send_invite_info, num = ~p,Login5 = ~p",[length(TencentData#tencent_data.invite_list),Login5]),
    misc_packet:send(Player#player.user_id, Packet).




merge_inviteInfo(TencentData,InviteInfo) ->
    Fun = fun({Account,Seconds},NewInviteList) ->
        case lists:keyfind(Account,1,NewInviteList) of
            false ->
                NewInviteList++[{Account,Seconds}];
            _ ->
                lists:keyreplace(Account,1,NewInviteList,{Account,Seconds})
        end
    end,
    NewInviteList = lists:foldl(Fun,TencentData#tencent_data.invite_list,InviteInfo#ets_tencent_invite_info.invite_list),
    Now = misc:seconds(),
    Fun2 = fun({Account,Seconds}) ->
        misc:check_yesterday(Now,Seconds)
    end,
    LastLoginNum = length(lists:filter(Fun2,NewInviteList)),
    TencentData#tencent_data{invite_list = NewInviteList,invite_login = LastLoginNum}.




get_vip_info(Player) ->
     LoginCheckMode = config:read(platform_info, #rec_platform_info.login_check),
    case LoginCheckMode of
        ?CONST_SYS_LOGIN_CHECK_TENCENT ->
        	case misc:http_request(Player#player.user_id,"/v3/user/is_vip",[]) of
                {ok, XmlContent} ->
                    ?MSG_DEBUG("vip check reply = ~p", [XmlContent]),
                    {Element,_} = xmerl_scan:string(XmlContent),
                    case misc:get_xml_value("/data/ret",Element) of
                        "0"->
                            IsYearVip = list_to_integer(misc:get_xml_value("/data/is_yellow_year_vip",Element,"0")),
                            VipLevel  = list_to_integer(misc:get_xml_value("/data/yellow_vip_level",Element,"0")),
                            ets_api:update_element(?CONST_ETS_TENCENT_INFO, Player#player.user_id, [{#ets_tencent_info.vip_lv,VipLevel},{#ets_tencent_info.is_year_vip,IsYearVip}]),
                            ?MSG_DEBUG("tencent vip IsYearVip= ~p;VipLevel = ~p", [IsYearVip,VipLevel]),
                            client_get_tencent_info(Player),
                            ?ok;
                        Code ->
                            ?MSG_ERROR("vip check error,code = ~p,content= ~p", [Code,XmlContent]),
                            {?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK}
                    end;
                Other ->
                    ?MSG_DEBUG("vip check err = ~p", [Other]),
                    {?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK}
            end;
        _ ->
            ?ok
    end.

%% 平黄砖等级{0没,其他对应等级},是否有每日礼包{0没,1有},等级礼包{0没得领,其他对应相应等级},黄砖新手礼包，是否年费用户)
client_get_tencent_info(Player) ->
    TencentData = mod_tencent_api:get_tencent_data(Player),
    case ets_api:lookup(?CONST_ETS_TENCENT_INFO, Player#player.user_id) of
        ?null ->
            IsYearVip = 0,
            VipLevel = 0;
        TencentInfo ->
            IsYearVip = TencentInfo#ets_tencent_info.is_year_vip,
            VipLevel = TencentInfo#ets_tencent_info.vip_lv
    end,
    Packet = misc_packet:pack(?MSG_ID_PLATFROM_INFO_RETURN, ?MSG_FORMAT_PLATFROM_INFO_RETURN, [VipLevel,TencentData#tencent_data.daily_pack,TencentData#tencent_data.daily_pack_year,TencentData#tencent_data.lv_pack,TencentData#tencent_data.new_pack,IsYearVip]),
    misc_packet:send(Player#player.user_id, Packet).

% 类型（1分享，2五个，3十个，4二十个，5四十个，6上线五个）
take_invite_award(Player,Type) ->
    TencentData = mod_tencent_api:get_tencent_data(Player),
    InviteNum = length(TencentData#tencent_data.invite_list),
    Ret = 
    case Type of
        1 ->
            case TencentData#tencent_data.share_step < 3 of
                true ->
                    case TencentData#tencent_data.share_step == 2 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_invite_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{share_step = TencentData#tencent_data.share_step+1},
                                    % NewTencentData = TencentData#tencent_data{share_step = 0},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                            NewTencentData = TencentData#tencent_data{share_step = TencentData#tencent_data.share_step+1},
                            {share,Player}
                    end;
                false ->
                    NewTencentData = TencentData,
                    {?error, "已经分享过"}
            end;
        2 ->
            case TencentData#tencent_data.invite_5 == 0 of
                true ->
                    case InviteNum >= 10 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_invite_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{invite_5 = 1},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                           NewTencentData = TencentData,
                            {?error, "邀请人数不足，继续努力哟"} 
                    end;
                false ->
                    NewTencentData = TencentData,
                    {?error, "已经领取过奖励"}
            end;
        3 ->
            case TencentData#tencent_data.invite_10 == 0 of
                true ->
                    case InviteNum >= 20 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_invite_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{invite_10 = 1},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                           NewTencentData = TencentData,
                            {?error, "邀请人数不足，继续努力哟"} 
                    end;
                false ->
                    NewTencentData = TencentData,
                    {?error, "已经领取过奖励"}
            end;
        4 ->
            case TencentData#tencent_data.invite_20 == 0 of
                true ->
                    case InviteNum >= 40 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_invite_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{invite_20 = 1},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                           NewTencentData = TencentData,
                            {?error, "邀请人数不足，继续努力哟"} 
                    end;
                false ->
                    NewTencentData = TencentData,
                    {?error, "已经领取过奖励"}
            end;
        5 ->
            case TencentData#tencent_data.invite_40 == 0 of
                true ->
                    case InviteNum >= 60 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_invite_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{invite_40 = 1},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                           NewTencentData = TencentData,
                            {?error, "邀请人数不足，继续努力哟"} 
                    end;
                false ->
                    NewTencentData = TencentData,
                    {?error, "已经领取过奖励"}
            end;
        6 ->
            case TencentData#tencent_data.login_5 == 0 of
                true ->
                    case TencentData#tencent_data.invite_login >= 5 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_invite_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{login_5 = 1},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                           NewTencentData = TencentData,
                            {?error, "邀请人数不足，继续努力哟"} 
                    end;
                false ->
                    NewTencentData = TencentData,
                    {?error, "已经领取过奖励"}
            end;
        _ ->
            case lists:member(Type,TencentData#tencent_data.share_codes) of
                true ->
                    NewTencentData = TencentData,
                    {?error, "已经领取过奖励"};
                false ->
                    case welfare_mod:reward_goods(Player, get_invite_goods(Type)) of
                        {?ok, Player2, _GoodsList} ->
                            NewTencentData = TencentData#tencent_data{share_codes = TencentData#tencent_data.share_codes++[Type]},
                            {?ok,Player2};
                        {?error, _ErrorCode} ->
                            NewTencentData = TencentData,
                            {?error, "物品创建失败"}
                    end
            end
    end,
    case Ret of
        {?ok,Player3} ->
            Player4 = Player3#player{tencent = NewTencentData},
            send_invite_info(Player4),
            send_err(Player,"领取成功！"),
            Player4;
        {share,Player3} ->
            Player4 = Player3#player{tencent = NewTencentData},
            send_invite_info(Player4),
            Player4;
        {?error,ErrString} ->
            send_err(Player,ErrString),
            Player
    end.


%% 1每日；2等级；3黄砖新手
get_packet(Player,Type) ->
    case ets_api:lookup(?CONST_ETS_TENCENT_INFO, Player#player.user_id) of
        ?null ->
            IsYearVip = 0,
            VipLevel = 0;
        TencentInfo ->
            IsYearVip = TencentInfo#ets_tencent_info.is_year_vip,
            VipLevel = TencentInfo#ets_tencent_info.vip_lv
    end,
    TencentData = mod_tencent_api:get_tencent_data(Player),
    Ret = 
    case VipLevel > 0 of
        true ->
            case Type of
                1 ->
                    case TencentData#tencent_data.daily_pack == 0 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{daily_pack = 1},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                            NewTencentData = TencentData,
                            {?error, "已经领取过该礼包"}
                    end;
                2 ->
                    Info = Player#player.info,
                    case TencentData#tencent_data.lv_pack =< Info#info.lv  of
                        true ->
                            ?MSG_ERROR("Lv = ~w",[Info#info.lv]),
                            case welfare_mod:reward_goods(Player, get_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{lv_pack = TencentData#tencent_data.lv_pack + 10},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                            NewTencentData = TencentData,
                            {?error, "等级不足"}
                    end;
                3 ->
                    case TencentData#tencent_data.new_pack == 0 of
                        true ->
                           case welfare_mod:reward_goods(Player, get_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{new_pack = 1},
                                   {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                            NewTencentData = TencentData,
                            {?error, "已经领取过该礼包"}
                    end;
                4 ->
                    case IsYearVip > 0 andalso TencentData#tencent_data.daily_pack_year == 0 of
                        true ->
                            case welfare_mod:reward_goods(Player, get_goods(Type)) of
                                {?ok, Player2, _GoodsList} ->
                                    NewTencentData = TencentData#tencent_data{daily_pack_year = 1},
                                    {?ok,Player2};
                                {?error, _ErrorCode} ->
                                    NewTencentData = TencentData,
                                    {?error, "物品创建失败"}
                            end;
                        false ->
                            NewTencentData = TencentData,
                            {?error, "已经领取过该礼包"}
                    end
            end;
        false ->
             NewTencentData = TencentData,
             {?error, "黄砖用户才能领取哦"}
    end,
    case Ret of
        {?ok,Player3} ->
            Player4 = Player3#player{tencent = NewTencentData},
            client_get_tencent_info(Player4),
            send_err(Player,"领取成功！"),
            Player4;
        {?error,ErrString} ->
            send_err(Player,ErrString),
            Player
    end.

check_login(UserID) ->
    case ets_api:lookup(?CONST_ETS_TENCENT_INFO, UserID) of
        ?null ->
            void;
        TencentInfo ->
            case  misc:seconds()-TencentInfo#ets_tencent_info.last_login > 3600 of
                true ->
                    is_login(UserID);
                false ->
                    void
            end
    end.

is_login(UserID) ->
    ets_api:update_element(?CONST_ETS_TENCENT_INFO, UserID, [{#ets_tencent_info.last_login,misc:seconds()}]),
    LoginCheckMode = config:read(platform_info, #rec_platform_info.login_check),
    case LoginCheckMode of
        ?CONST_SYS_LOGIN_CHECK_TENCENT ->
            misc:http_request(UserID,"/v3/user/is_login",[]);
        _ ->
            void
    end.


% Pro, Sex, GoodsId, BindState, Count
get_goods(Type) ->
    case Type of
        1 ->
            [{0,0,1040507018,1,1},{0,0,1093000002,1,3},{0,0,1093000005,1,5}];
        2 ->
            [{0,0,1040507018,1,1},{0,0,1040607023,1,1},{0,0,1040707028,1,1}];
        3 ->
            [{0,0,1040507018,1,1},{0,0,1040607023,1,5},{0,0,1040707028,1,1},{0,0,1093000005,1,10}];
        4 ->
            [{0,0,1093000001,1,3}]
    end.

% （1分享，2五个，3十个，4二十个，5四十个，6上线五个）
% 101  1093000003*5 拜访礼 1040606022*1顶级礼券卡
% 102  1092105098*5精良草料 1040606022*1顶级礼券卡
% 103 11040402005*5初级体力丹   1040606022*2顶级礼券卡
%  104  1040707028*1超级功勋卡  1040606022*2顶级礼券卡
% 105  1040907051*5白银绑定卡   1093000005*5养生丹
% 106  1040907051*5白银绑定卡   1093000005*5养生丹
% 107  1040907051*10白银绑定卡 1093000001*5祭星灯
% 108  1040907052*2黄金绑定卡  1093000001*5祭星灯
% 109 1093000102*1二级物攻宝石  1093000112*1二级术攻宝石
% 110  1093000104*1四级物攻宝石 1093000114*1四级术攻宝石
% 111  1040907052*10黄金绑定卡

get_invite_goods(Type) ->
    case Type of
        1 ->
            [{0,0,1040507018,1,1},{0,0,1040607023,1,1},{0,0,1093000005,1,20}];
        2 ->
            [{0,0,1040507018,1,2},{0,0,1093000005,1,10}];
        3 ->
            [{0,0,1040507018,1,5},{0,0,1093000005,1,20}];
        4 ->
            [{0,0,1040507018,1,10},{0,0,1040607023,1,2}];
        5 ->
            [{0,0,1040507018,1,20},{0,0,1040607023,1,5}];
        6 ->
            [{0,0,1040507018,1,2},{0,0,1093000002,1,5}];
        101 ->
            [{0,0,1093000003,1,5},{0,0,1040606022,1,1}];
        102 ->
            [{0,0,1092105098,1,5},{0,0,1040606022,1,1}];
        103 ->
            [{0,0,11040402005,1,5},{0,0,1040606022,1,2}];
        104 ->
            [{0,0,1040707028,1,1},{0,0,1040606022,1,2}];
        105 ->
            [{0,0,1040907051,1,5},{0,0,1093000005,1,5}];
        106 ->
            [{0,0,1040907051,1,5},{0,0,1093000005,1,5}];
        107 ->
            [{0,0,1040907051,1,10},{0,0,1093000001,1,5}];
        108 ->
            [{0,0,1040907052,1,2},{0,0,1093000001,1,5}];
        109 ->
            [{0,0,1093000102,1,1},{0,0,1093000112,1,1}];
        110 ->
            [{0,0,1093000104,1,1},{0,0,1093000114,1,1}];
        111 ->
            [{0,0,1040907052,1,10}]
    end.

send_err(Player,ErrString) ->
     Packet = misc_packet:pack(?MSG_ID_TENCENT_ERR_RETURN, ?MSG_FORMAT_TENCENT_ERR_RETURN, [ErrString]),
    misc_packet:send(Player#player.user_id, Packet).


do_market() ->
    CMD = misc:to_list(get("cmd")),
    Account   = misc:to_list(get("openid")),
    ServId = config:read_deep([server, base, sid]),
    case player_api:lookup_account_2(misc:to_binary(Account), ServId) of
        {_, UserId} -> 
            ?ok;
        _ ->
            UserId    = 0
    end,
    ?MSG_ERROR("Account = ~p,ServId = ~p,UserId = ~p",[Account,ServId,UserId]),
    Step   = misc:to_integer(get("step")),
    case player_api:check_online(UserId) of
        ?true ->
            case player_api:process_call(UserId, mod_tencent, do_player_market, [CMD, Step]) of
                ?false ->
                    
                    {?true, 1001, "{\"ret\":1001,\"msg\":\"玩家不在线\",\"zoneid\":\""++misc:to_list(ServId)++"\"}"};
                Ret ->
                    Ret
            end;
        ?false ->
            {?true, 1001, "{\"ret\":1001,\"msg\":\"玩家不在线\",\"zoneid\":\""++misc:to_list(ServId)++"\"}"}
    end.


% 应用的返回包应该包含如下参数：
% ret: 返回码。需要为“整数”类型
% msg: 错误信息。编码格式：utf8 
% zoneid: 应用给玩家在哪个区/服的角色发放奖励。为英文字符串，不可包含中文。用于平台记录，不具备实际功能。

% 3.6 协议返回码
% 应用的返回码 分为标准返回码和自定义返回码两类。

% 标准返回码如下：
% 0: OK 或 OK
% 1: 用户尚未在应用内创建角色
% 2：用户尚未完成本步骤
% 3：该步骤奖励已发放过
% 100: token已过期
% 101: token不存在
% 102: 奖励发放失败
% 103: 请求参数错误

% {"ret":0,"msg":"OK","zoneid":"1"}
% 1号 1040406008 顶级体力丹*2,4号 1040406008 顶级体力丹*5
% 15级 1040907049 黄金充值卡      25级 2011107001 绝影

do_player_market(Player,[CMD,Step]) ->
    TencentData = mod_tencent_api:get_tencent_data(Player),
    Receives = TencentData#tencent_data.receive_tasks,
    Finishs  = TencentData#tencent_data.finish_tasks,
    Awards   = TencentData#tencent_data.award_tasks,
    ServId = misc:to_list(Player#player.serv_id),
    Reply =
    case CMD of
        "check" ->
            NewPlayer = Player,
            case lists:member(Step,Finishs) of
                true ->
                    {?true, 0, "{\"ret\":0,\"msg\":\"OK\",\"zoneid\":\""++ServId++"\"}"};
                false ->
                    {?true, 2, "{\"ret\":2,\"msg\":\"未完成\",\"zoneid\":\""++ServId++"\"}" }
            end;
        "award" ->
            case check_finish(Player,Step) of
                true ->
                    case lists:member(Step,Awards) of
                        true ->
                            NewPlayer = Player,
                            {?true, 3, "{\"ret\":3,\"msg\":\"已发放过\",\"zoneid\":\""++ServId++"\"}"};
                            
                        false ->
                            case market_awrad(Player,Step) of
                                {?ok,NewPlayer} ->
                                    {?true, 0, "{\"ret\":0,\"msg\":\"OK\",\"zoneid\":\""++ServId++"\"}"};
                                _ ->
                                    NewPlayer = Player,
                                    {?true, 102, "{\"ret\":102,\"msg\":\"发放失败\",\"zoneid\":\""++ServId++"\"}"}
                            end
                    end;
                false ->
                    NewPlayer = Player,
                    {?true, 2, "{\"ret\":2,\"msg\":\"未完成\",\"zoneid\":\""++ServId++"\"}"}
            end;
        "check_award" ->
            case check_finish(Player,Step) of
                true ->
                    case lists:member(Step,Awards) of
                        true ->
                            
                            NewPlayer = Player,
                            {?true, 3, "{\"ret\":3,\"msg\":\"已发放过\",\"zoneid\":\""++ServId++"\"}"};
                        false ->
                            case market_awrad(Player,Step) of
                                {?ok,NewPlayer} ->
                                    {?true, 0, "{\"ret\":0,\"msg\":\"OK\",\"zoneid\":\""++ServId++"\"}"};
                                _ ->
                                    NewPlayer = Player,
                                    {?true, 102, "{\"ret\":102,\"msg\":\"发放失败\",\"zoneid\":\""++ServId++"\"}"}
                            end
                    end;
                false ->
                    NewPlayer = Player,
                    {?true, 2, "{\"ret\":2,\"msg\":\"未完成\",\"zoneid\":\""++ServId++"\"}"}
            end;
        _ ->
            NewPlayer = Player,
            {?true, 103, "{\"ret\":2,\"msg\":\"参数错误\",\"zoneid\":\""++ServId++"\"}"}
    end,
    {?ok, Reply, NewPlayer}.


finish_task(Player,TaskId) ->
    TencentData = mod_tencent_api:get_tencent_data(Player),
    NewTencentData = TencentData#tencent_data{finish_tasks = (TencentData#tencent_data.finish_tasks -- [TaskId])++[TaskId]},
    NewPlayer = Player#player{tencent = NewTencentData}.



get_award(Step) ->
    case Step of
        1 ->
            [{0,0,1040406008,1,2}];
        2 ->
            [{0,0,1040907049,1,1}];
        3 ->
            [{0,0,2011107001,1,1}];
        4 ->
            [{0,0,1040406008,1,5}];
        _ ->
            []
    end.

check_finish(Player,Step) ->
    Lv = case Step of
        2 ->
            15;
        3 ->
            25;
        _ ->
            1
    end,
    Info = Player#player.info,
    Info#info.lv >= Lv.


market_awrad(Player,Step) ->
    case welfare_mod:reward_goods(Player, get_award(Step)) of
        {?ok, Player2, _GoodsList} ->
            TencentData = mod_tencent_api:get_tencent_data(Player2),
            NewTencentData = TencentData#tencent_data{award_tasks = TencentData#tencent_data.award_tasks++[Step]},
            {?ok,Player2#player{tencent = NewTencentData}};
        {?error, _ErrorCode} ->
            {?error, "物品创建失败"}
    end.