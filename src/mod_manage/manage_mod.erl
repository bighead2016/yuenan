%%%

-module(manage_mod).

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
-include("record.man.hrl").
%%
%% Exported Functions
%%
-export([get_houtai_data/0, get_houtai_data_file/0, update_plat/0, get_plat_data/0,
         get_plat_data_file/0]).
%%
%% API Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_houtai_data() ->
    Props = [{pro,"wwsg"},{values,"all"},{checktick,"a7e603636b48869b7f1e073b266afd7f"}],
    SendData = mochiweb_util:urlencode(Props),
    case httpc:request(post,{"http://wgoms.4399houtai.com/main/?r=GetGameinfo/GetProInfo",[],"application/x-www-form-urlencoded",SendData},[],[]) of
        {ok, {_, _, Data}}-> do_houtai_data(Data), ?ok;    
        {ok, {_, Data}}-> do_houtai_data(Data),?MSG_SYS("1", []), ?ok;    
        {ok, _}-> ?MSG_SYS("1", []), ?ok;    
        {error, Reason}->?MSG_SYS("error cause ~p",[Reason]),?error  
    end.
get_houtai_data_file() ->
    case file:read_file("../run/server_info.log") of
        {?ok, File} ->
            do_houtai_data(File),
            ok;
        {?error, Reason} ->
            ?MSG_SYS("read file[../run/server_info.log] err[~p]", [Reason])
    end.

do_houtai_data(Data) ->
    List = re:split(Data, " |\n"),
    do_houtai_data_2(List, []).
do_houtai_data_2([_Game, Plat, Sid, _Time, _Port, _GmPort, IpTelcom, _IpUnicom, _IpSlave, 
                  _, _Phy, CombineList, _, _, _, _|Tail], OldList) ->
    Sid2 = misc:to_integer(Sid),
    Ip = misc:to_list(IpTelcom),
    CombineList2 = b2l(CombineList),
    ?MSG_ERROR("do_houtai_data_2 ~p",[{Plat, Sid}]),
    case mysql_api:select(<<"select `plat_id` from `game_plat_t` where `plat` = '", (misc:to_binary(Plat))/binary, "';">>) of
        {?ok, L} ->
            [do_houtai_data_3(PlatId, Sid2, Plat, CombineList2, Ip, IpTelcom)||[PlatId]<-L];
        _ ->
            ets_api:insert(?CONST_ETS_MAN_HOUTAI, #ets_man_houtai{key = {0, Sid2}, plat = Plat, plat_id = 0, sid = Sid2, 
                                                   combine = CombineList2, ip_telcom = Ip}),
            mysql_api:insert(<<"insert into `game_server_t`(`sid`,`plat_id`,`ip_telcom`,`combine`) values('", 
                               (misc:to_binary(Sid2))/binary, "','", 
                               (misc:to_binary(0))/binary, "','", 
                               (misc:to_binary(IpTelcom))/binary, "', ", 
                               (mysql_api:encode(CombineList2))/binary, ");">>)
    end,
    do_houtai_data_2(Tail, [{Sid2, Plat, IpTelcom, CombineList2}|OldList]);
do_houtai_data_2(List1, List) ->
    ?MSG_ERROR("do_houtai_data_2 err ~p;  ~p",[List1, List]),
    List.

do_houtai_data_3(PlatId, Sid, Plat, CombineList, Ip, Ip2) ->
    Node = misc:make_node(Plat, Sid, Ip),
    ?MSG_ERROR("do_houtai_data_3 ~p",[{Plat, Sid,Ip}]),
    ets_api:insert(?CONST_ETS_MAN_HOUTAI, #ets_man_houtai{key = {PlatId, Sid}, plat = Plat, plat_id = PlatId, sid = Sid, 
                                                   combine = CombineList, ip_telcom = Ip, node = Node}),
    case mysql_api:select(<<"select 1 from `game_server_t` where `plat_id` = '", 
                            (misc:to_binary(PlatId))/binary, "' and `sid` = '", (misc:to_binary(Sid))/binary, "';">>) of
        {?ok, []} ->
            mysql_api:insert(<<"insert into `game_server_t`(`sid`,`plat_id`,`ip_telcom`,`node`,`combine`) values('", 
                               (misc:to_binary(Sid))/binary, "','", 
                               (misc:to_binary(PlatId))/binary, "','", 
                               (misc:to_binary(Ip2))/binary, "', ", 
                               (mysql_api:encode(Node))/binary, ", ", 
                               (mysql_api:encode(CombineList))/binary, ");">>);
        _ ->
            mysql_api:select(<<"update `game_server_t` set `ip_telcom` = '", 
                               (misc:to_binary(Ip2))/binary, "', `combine` = ", 
                               (mysql_api:encode(CombineList))/binary, " where `sid` = '",
                               (misc:to_binary(Sid))/binary, "' and `node` = '", 
                               (mysql_api:encode(Node))/binary, "' and `plat_id` = '", 
                               (misc:to_binary(PlatId))/binary, "';">>)
    end,
    if
        1 =:= Sid ->
            do_houtai_data_3(PlatId, 0, Plat, CombineList, Ip, Ip2);
        16 =:= Sid andalso (1 =:= PlatId orelse 0 =:= PlatId) ->
            do_houtai_data_3(PlatId, 0, Plat, CombineList, Ip, Ip2);
        ?true ->
            ?true
    end.


    

%% binary转term
b2l(Bin) ->
    Bin2 = <<"[", Bin/binary, "]">>,
    misc:bitstring_to_term(Bin2).

%% desc:加载平台信息
update_plat() ->
    L = data_misc:get_platform_list(),
    update_plat(L).
update_plat([{Id, _, _}|Tail]) ->
    #rec_platform_info{platform_2 = Plat, login_key = Key} = data_misc:get_platform_info(Id),
    case mysql_api:select(<<"select 1 from `game_plat_t` where `plat_id` = '", (misc:to_binary(Id))/binary, "';">>) of
        {?ok, []} ->
            mysql_api:select(<<"insert `game_plat_t`(`plat_id`,`plat`,`login_key`) values('", (misc:to_binary(Id))/binary,  
                               "', '", (misc:to_binary(Plat))/binary, "', '", (misc:to_binary(Key))/binary, "');">>);
        {?ok, _} ->
            mysql_api:select(<<"update `game_plat_t` set `plat` = '", (misc:to_binary(Plat))/binary, 
                               "', `login_key` = '", (misc:to_binary(Key))/binary, "' where `plat_id` = '", (misc:to_binary(Id))/binary, "';">>)
    end,
    update_plat(Tail);
update_plat([]) ->
    ?ok.

%%----------------平台信息
get_plat_data() ->
    Props = [{pro,"wwsg"},{agent,"all"},{checktick,"52a0db2aa8dcf7822985369f3f8a2190"}],
    SendData = mochiweb_util:urlencode(Props),
    case httpc:request(post,{"http://wgoms.4399houtai.com/main/?r=GetGameinfo/GetAgencyInfo",[],"application/x-www-form-urlencoded",SendData},[],[]) of
        {ok, {_, _, Data}}-> get_plat_data_2(Data), file:write_file(plat, [Data]), ?ok;    
        {ok, {_, Data}}-> get_plat_data_2(Data),?MSG_SYS("1", []), ?ok;    
        {ok, _}-> ?MSG_SYS("1", []), ?ok;    
        {error, Reason}->?MSG_SYS("error cause ~p",[Reason]),?error  
    end.
get_plat_data_file() ->
    case file:read_file("../run/plat_info.log") of
        {?ok, File} ->
            get_plat_data_2(File),
            ok;
        {?error, Reason} ->
            ?MSG_SYS("read file[../run/plat_info.log] err[~p]", [Reason])
    end.

get_plat_data_2(Data) ->
    List = re:split(Data, "[\n\r]"),
    List2 = [re:split(L, "[\s]+")||L<-List],
    get_plat_data_2(List2, []).
get_plat_data_2([[_]|Tail], OldList) ->
    get_plat_data_2(Tail, OldList);
get_plat_data_2([[_Game, Plat, _X, _X1, _X2, _X3, _X4, _X5, _X6, _X7, LoginKey, PlatId, _X12]|Tail], OldList) -> % 13
    ?MSG_SYS("~p|~p|13", [Plat, LoginKey]),
    PlatId2 = misc:to_integer(PlatId),
    case mysql_api:select(<<"select 1 from `game_plat_t` where `plat_id` = '", (misc:to_binary(PlatId2))/binary, "';">>) of
        {?ok, []} ->
            mysql_api:select(<<"insert `game_plat_t`(`plat_id`,`plat`,`login_key`) values('", (misc:to_binary(PlatId2))/binary,  
                               "', '", (misc:to_binary(Plat))/binary, 
                               "', '", (misc:to_binary(LoginKey))/binary, "');">>);
        {?ok, _} ->
            mysql_api:select(<<"update `game_plat_t` set `plat` = '", (misc:to_binary(Plat))/binary, 
                               "' where `plat_id` = '", (misc:to_binary(PlatId2))/binary, "';">>)
    end,
    get_plat_data_2(Tail, [{Plat, PlatId2}|OldList]);
get_plat_data_2([[_Game, Plat, _X, _X1, _X2, _X3, _X4, _X5, _X6, _X7, _X8, _X9, LoginKey, PlatId, _X12]|Tail], OldList) -> % 15
    ?MSG_SYS("~p|~p|15", [Plat, LoginKey]),
    PlatId2 = misc:to_integer(PlatId),
    case mysql_api:select(<<"select 1 from `game_plat_t` where `plat_id` = '", (misc:to_binary(PlatId2))/binary, "';">>) of
        {?ok, []} ->
            mysql_api:select(<<"insert `game_plat_t`(`plat_id`,`plat`,`login_key`) values('", (misc:to_binary(PlatId2))/binary,  
                               "', '", (misc:to_binary(Plat))/binary, 
                               "', '", (misc:to_binary(LoginKey))/binary, "');">>);
        {?ok, _} ->
            mysql_api:select(<<"update `game_plat_t` set `plat` = '", (misc:to_binary(Plat))/binary, 
                               "' where `plat_id` = '", (misc:to_binary(PlatId2))/binary, "';">>)
    end,
    get_plat_data_2(Tail, [{Plat, PlatId2}|OldList]);
get_plat_data_2([X|Tail], OldList) ->
    ?MSG_SYS("~p", [X]),
    get_plat_data_2(Tail, OldList);
get_plat_data_2([], List) ->
    List.




    



