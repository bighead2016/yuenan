
-module(manage_interface_mod).
%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").
-include("record.task.hrl").
%%
%% Exported Functions
%%
-export([treat_admin_cast/2, check_ip/1, treat_http_request/2, chinese_to_bin/1,do_multifunction/1,
         change_money_type/1, chinese_to_utf8/1, convert_ctn_type/1, convert_date/3,
         convert_goods_bind/1, convert_goods_color/1, convert_pro/1, convert_sex/1, 
         convert_time/3, date_format/1, real_ban_date/1, real_end/1, real_forbid_date/1,
         real_integer/1, real_start/1, sql_escape_bin/1]).
-export([convert_date/1, convert_time/1, convert_date_time/1]).
-export([white_ip_list/0]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 处理HTTP请求
treat_http_request(_Socket, <<"GET /favicon.ico", _RequestBin/binary>>) ->
    ?ok;
treat_http_request(Socket, <<"GET ", RequestBin/binary>>) ->
    try
        {CMD, KVList}           = get_cmd_parm(RequestBin),
        {_Status, _Len, Result} = do_handle_request(CMD, KVList),
        send_data(Socket, Result, ?HTTP_CODE_200),
        ?ok
    catch
        What:Why ->
            ?MSG_SYS("What ~p, Why ~p, ~p", [What, Why, erlang:get_stacktrace()]),
            {What, Why}
    end;
treat_http_request(Socket, Request) ->
    ?MSG_SYS("bad request: ~p", [Request]),
    send_data(Socket, "bad request: " ++ misc:encode(Request), ?HTTP_CODE_400),
    ?ok.

get_cmd_parm(Packet) ->
    List = misc:to_list(Packet),
    NN = string:str(List, " "),
    List2 = string:substr(List, 1, NN - 1),
    
    try
        case string:str(List2, "?") of
            0 -> 
                {no_cmd, []};
            N ->
                CMD         = string:substr(List2, 2, N - 2),
                KVList      = total_params(List2),
                KeyValue    = key_value_list(List2),
                set_kv_list(KeyValue),
                {CMD, KVList}
        end
    catch
        X:Y ->
            ?MSG_SYS("1[~p|~p]~n~p", [X, Y, erlang:get_stacktrace()]),
            {no_cmd, []}
    end.

send_data(Socket, Data, HttpCode) ->
    Data2           = misc:to_binary(Data),
    HttpCode2       = misc:to_binary(HttpCode),
    ResponseHeader  = <<"HTTP/1.1 ", HttpCode2/binary, " OK\r\n\r\n">>,
    gen_tcp:send(Socket, <<ResponseHeader/binary, Data2/binary>>),
    gen_tcp:close(Socket).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% http://deposit?pay_num=11111&account=11111&money=11111&cash=11111&order_type=&time=11111&pay_type=11111
%% 泛功能接口
do_handle_request("multifunction", KVList) -> 
    Flag = get_value("flag"),
    case string:to_upper(misc:md5(lists:sort(KVList))) of
        _Flag -> 
            do_mutilfunction();
        Other ->
            ?MSG_SYS("Flag ~p, Other ~p", [Flag, Other]),
            {?false, 10, "flag_error"}
    end;

%% 1 重置玩家位置：很可能玩家已经卡死，踢下线即可

%% 不识别的指令？
do_handle_request(Other, KVList) ->
    ?MSG_SYS("admin unknown cmd  ~p, ~p", [Other, KVList]),
    {?false, 11, "param_error"}.

%%
%% Local Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 泛功能接口
do_mutilfunction() ->
    Api_method      = get_value("api_method"),
    catch do_multifunction(Api_method).

do_multifunction("sel_key")->
    PlatId   = get_value("plat_id"),
    Sql = 
        case PlatId of
            ?null ->
                <<"select `plat_id`,`plat`,`login_key` from `game_plat_t`;">>;
            _ ->
                <<"select `plat_id`,`plat`,`login_key` from `game_plat_t` where `plat_id` = '", (misc:to_binary(PlatId))/binary, "';">>
        end,
    case mysql_api:select(Sql) of
        {?ok, List} ->
            make_list(List);
        _ ->
            {?false, 6, "failed"}
    end;
do_multifunction("set_key")->
    PlatId   = get_value("plat_id"),
    Plat     = get_value("plat"),
    LoginKey = get_value("login_key"),
    if
        ?null =/= PlatId andalso ?null =/= LoginKey ->
            Sql = <<"select 1 from `game_plat_t` where `plat_id` = '", (misc:to_binary(PlatId))/binary, "';">>,
            case mysql_api:select(Sql) of
                {?ok, _} ->
                    Sql2 = <<"update `game_plat_t` set `login_key` = '", (misc:to_binary(LoginKey))/binary, 
                             "' where `plat_id` = '", (misc:to_binary(PlatId))/binary, "';">>,
                    mysql_api:update(Sql2);
                _ ->
                    Sql2 = <<"insert into `game_plat_t`(`plat_id`,`plat`,`login_key`) values ('", (misc:to_binary(PlatId))/binary, 
                             "','", (misc:to_binary(Plat))/binary, "','", (misc:to_binary(LoginKey))/binary, "');">>,
                    mysql_api:insert(Sql2)
            end,
            {?true, 1, "success"};
        ?true ->
            {?false, 6, "failed"}
    end;
do_multifunction("syn_server")->
    case manage_mod:get_houtai_data() of
        ?ok ->
            {?true, 1, "success"};
        ?error ->
            {?false, 6, "failed"}
    end;
do_multifunction("syn_plat")->
    case manage_mod:get_plat_data() of
        ?ok ->
            {?true, 1, "success"};
        ?error ->
            {?false, 6, "failed"}
    end;
do_multifunction("sel_server")->
    PlatId   = get_value("plat_id"),
    Sid      = get_value("sid"),
    Sql = 
        case PlatId of
            ?null ->
                case Sid of
                    ?null ->
                        <<"select `plat_id`,`sid`,`ip_telcom`,`combine` from `game_server_t`;">>;
                    _ ->
                        <<"select `plat_id`,`sid`,`ip_telcom`,`combine` from `game_server_t` where `sid` = '", (misc:to_binary(Sid))/binary, "';">>
                end;
            _ ->
                case Sid of
                    ?null ->
                        <<"select `plat_id`,`sid`,`ip_telcom`,`combine` from `game_server_t` where `plat_id` = '", (misc:to_binary(PlatId))/binary, "';">>;
                    _ ->
                        <<"select `plat_id`,`sid`,`ip_telcom`,`combine` from `game_server_t` where `sid` = '", (misc:to_binary(Sid))/binary, 
                            "' and `plat_id` = '", (misc:to_binary(PlatId))/binary, "';">>
                end
        end,
    case mysql_api:select(Sql) of
        {?ok, List} ->
            make_serv_list(List);
        _ ->
            {?false, 6, "failed"}
    end;
do_multifunction(_) ->
    {?false, 6, "failed"}.

make_list(List) ->
    Desc = {obj, [
                  {"plat_id", <<"平台id">>}
                  ,{"plat", <<"平台">>}
                  ,{"login_key", <<"登录key">>}
                 ]},
    Data = make_list_2(List, []),
    Result = rfc4627:encode(
               {obj, [{"state", <<"success">>}
                      ,{"desc", Desc}
                      ,{"data", Data}]}),
    {?true, length(Result), Result}.
make_list_2([[PlatId, Plat, LoginKey]|Tail], OldList) ->
    Data = {obj, [
                  {"plat_id", misc:to_binary(PlatId)},
                  {"plat", misc:to_binary(Plat)},
                  {"login_key", misc:to_binary(LoginKey)}
                 ]},
    make_list_2(Tail, [Data|OldList]);
make_list_2([], List) ->
    lists:reverse(List).

%%
make_serv_list(List) ->
    Desc = {obj, [
                  {"plat_id", <<"平台id">>},
                  {"sid", <<"服务器id">>},
                  {"ip", <<"ip">>},
                  {"combine", <<"合服列表">>}
                 ]},
    Data = make_serv_list_2(List, []),
    Result = rfc4627:encode(
               {obj, [{"state", <<"success">>}
                      ,{"desc", Desc}
                      ,{"data", Data}]}),
    {?true, length(Result), Result}.
make_serv_list_2([[PlatId, Sid, Ip, Combine]|Tail], OldList) ->
    Data = {obj, [
                  {"plat_id", misc:to_binary(PlatId)},
                  {"sid", misc:to_binary(Sid)},
                  {"ip", misc:to_binary(Ip)},
                  {"combine", mysql_api:decode(Combine)}
                 ]},
    make_serv_list_2(Tail, [Data|OldList]);
make_serv_list_2([], List) ->
    lists:reverse(List).
         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 检查IP是否在白名单中
check_ip(_Ip) -> ?true.
%%     IpList = white_ip_list(),
%%     lists:any(fun(Ip2) -> misc:to_binary(Ip2) =:= misc:to_binary(Ip) end, IpList).

%% 返回IP白名单
white_ip_list() ->
    [_, Ip] = string:tokens(misc:to_list(node()), "@"),
    case config:read(server_info, #rec_server_info.white_ip_list) of
        ?null -> [Ip];
        List  -> [Ip|List]
    end.

total_params(Param) ->
    [_, Param2]     = string:tokens(Param, "?"),
    List            = [begin
                           case string:tokens(X, "=") of
                               [Key] -> Key;
                               ["flag", _Value] -> "";
                               [Key, Value] -> lists:concat([Key, Value])
                           end
                       end || X <- string:tokens(Param2, "&")],
    lists:concat(List).

key_value_list(Param) ->
    [_, Param2] = string:tokens(Param, "?"),
    [begin
         case string:tokens(X, "=") of
             [Key] -> {Key, ""};
             [Key, Value] -> {Key, Value}
         end
     end || X <- string:tokens(Param2, "&")].

%% 处理admin模块的cast消息
treat_admin_cast(Player, [add_equip, GoodsId, Count]) ->
    goods_api:add_goods_gm(Player, GoodsId, Count);
treat_admin_cast(Player, [user_ban, Duration]) ->
    player_api:user_ban(Player, Duration);
treat_admin_cast(Player, [user_unban]) ->
    player_api:user_unban(Player);
%% treat_admin_cast(_Player, [user_list]) ->
%%  player_api:all_user_online();
treat_admin_cast(Player, [chat_ban, Duration]) ->
    player_api:user_chat_ban(Player, Duration);
treat_admin_cast(Player, [chat_unban]) ->
    player_api:user_chat_unban(Player);
treat_admin_cast(Player, [set_viplv, ToVipLv]) ->
    ToVipLv2 = misc:betweet(ToVipLv, 0, 10),
    player_api:vip(Player, ToVipLv2);
treat_admin_cast(Player, _) ->
    {?ok, Player}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%各种兼容，获得程序可处理的数据%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 获取整形 检验数据
real_integer([]) -> 0;
real_integer({}) -> 0;
real_integer(Data) ->
    misc:to_integer(Data).

%% -1为永久
real_forbid_date(Num) when Num < 0 orelse Num > 315360000 ->
    315360000;  %10年后，你还来，I服了U
real_forbid_date(Num) ->
    Num.
%% -1为永久
real_ban_date(Num) when Num < 0 orelse Num > 2000000000->
    2000000000;
real_ban_date(Num) ->
    Num.

real_start("") ->
    0;
real_start(<<>>) ->
    0;
real_start(Data) ->
    Data.

real_end("") ->
    2000000000;
real_end(<<>>) ->
    2000000000;
real_end(Data) ->
    Data.

%% SQL字符串转义 加%
sql_escape_bin(Data) ->
    misc:to_binary(sql_escape(Data)).

sql_escape(?null) -> "%";
sql_escape([]) -> "%";
sql_escape(<<"">>) -> "%";
sql_escape(Data) ->
    Data2 = misc:to_list(Data),
    lists:concat(["%", Data2, "%"]).

%% key-value
set_kv_list([{Key, Value}|T]) ->
%%     ?MSG_SYS("~n Key=~p, Value=~p", [Key, Value]),
    erlang:put(Key, Value),
    set_kv_list(T);
set_kv_list([]) -> ?ok.

get_value(Key) ->
    case erlang:get(Key) of
        undefined -> ?null;
        Value -> Value
    end.

%% 货币类型，同时发放多个币种时，使用逗号分隔，
%% 与货币数量money_amount币种对应。
%% 1=元宝/金币，2=绑定元宝/金币，3=铜币，4=绑定铜币， 5=礼券
%% 若无货币需要发放，此字段为空
change_money_type("1") -> ?CONST_SYS_CASH;
change_money_type("2") -> ?CONST_SYS_CASH_BIND;
change_money_type("3") -> ?CONST_SYS_GOLD_BIND;
change_money_type("4") -> ?CONST_SYS_GOLD_BIND;
change_money_type("5") -> 0;
change_money_type(_) -> 0.

%% 中文转utf-8字符串
%% 中国--->"\u4E2D\u56FD"
chinese_to_bin(Data) ->
    Data2 = chinese_to_utf8(Data),
    erlang:list_to_binary(Data2).

chinese_to_utf8(Data) ->
    Data2 = unicode:characters_to_list(Data),
    utf8_to_string(Data2, []).

utf8_to_string([], Acc) ->
    Acc;
utf8_to_string([One|T], Acc) ->
    String = erlang:integer_to_list(One, 16),
    utf8_to_string(T, Acc ++ lists:concat(["\u", String])).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 性别转换
convert_sex(?CONST_SYS_SEX_NULL) -> <<"空">>;
convert_sex(?CONST_SYS_SEX_MALE) -> <<"男">>;
convert_sex(?CONST_SYS_SEX_FAMALE) -> <<"女">>;
convert_sex(_) -> <<"error">>.
%% 职业转换
convert_pro(?CONST_SYS_PRO_NULL) -> <<"空">>;
convert_pro(?CONST_SYS_PRO_XZ) -> <<"陷阵">>;
convert_pro(?CONST_SYS_PRO_FJ) -> <<"飞军">>;
convert_pro(?CONST_SYS_PRO_TJ) -> <<"天机">>;
convert_pro(?CONST_SYS_PRO_GM) -> <<"鬼谋">>;
convert_pro(?CONST_SYS_PRO_KX) -> <<"控弦">>;
convert_pro(?CONST_SYS_PRO_JH) -> <<"惊鸿">>;
convert_pro(_) -> <<"error">>.
%% 日期转换
convert_date({Y,M,D}) -> convert_date(Y,M,D);
convert_date({{Y,M,D},_Time}) -> convert_date(Y,M,D).
convert_date(Y,M,D) ->
    misc:to_list(Y)++"年"++date_format(M)++"月"++date_format(D)++"日".
%% 时间转换
convert_time({H,M,S}) -> convert_time(H,M,S);
convert_time({_Date,{H,M,S}}) -> convert_time(H,M,S).
convert_time(H,M,S) ->
    misc:to_list(H)++":"++misc:to_list(M)++":"++misc:to_list(S).
%% 日期时间转换
%% admin_mod:convert_date_time(2343543453).
convert_date_time(Seconds) when is_number(Seconds) ->
    convert_date_time(misc:seconds_to_localtime(Seconds));
convert_date_time({{Y,M,D},{H,Min,S}}) ->
    misc:to_list(Y)++"年"++date_format(M)++"月"++date_format(D)++"日"++
    "--" ++
    misc:to_list(H)++":"++misc:to_list(Min)++":"++misc:to_list(S).

date_format(D) ->
    if D < 10 -> "0" ++ misc:to_list(D); ?true  -> misc:to_list(D) end.
%% 转换物品颜色
convert_goods_color(?CONST_SYS_COLOR_WHITE)     -> <<"白">>;
convert_goods_color(?CONST_SYS_COLOR_GREEN)     -> <<"绿">>;
convert_goods_color(?CONST_SYS_COLOR_BLUE)      -> <<"蓝">>;
convert_goods_color(?CONST_SYS_COLOR_YELLOW)    -> <<"金">>;
convert_goods_color(?CONST_SYS_COLOR_PURPLE)    -> <<"紫">>;
convert_goods_color(?CONST_SYS_COLOR_ORANGE)    -> <<"橙">>;
convert_goods_color(?CONST_SYS_COLOR_RED)       -> <<"红">>;
convert_goods_color(_) -> <<"error">>.
%% 转换物品绑定状态
convert_goods_bind(?CONST_GOODS_UNBIND) -> <<"未绑定">>;
convert_goods_bind(?CONST_GOODS_BIND)   -> <<"已绑定">>;
convert_goods_bind(_) -> <<"error">>.
%% 转换容器类型
convert_ctn_type(?CONST_GOODS_CTN_BAG)              -> <<"背包">>;
convert_ctn_type(?CONST_GOODS_CTN_DEPOT)            -> <<"仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_BAG_TEMP)         -> <<"临时背包">>;
convert_ctn_type(?CONST_GOODS_CTN_EQUIP_PLAYER)     -> <<"角色装备栏">>;
convert_ctn_type(?CONST_GOODS_CTN_EQUIP_PARTNER)    -> <<"武将装备栏">>;
convert_ctn_type(?CONST_GOODS_CTN_LOTTERY_DEPOT)    -> <<"宝箱仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_HOME_DEPOT)       -> <<"家园仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_GUILD)            -> <<"军团仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_REMOTE_DEPOT)     -> <<"远程仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_REMOTE_SHOP)      -> <<"远程道具店">>;
convert_ctn_type(_) -> <<"error">>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%