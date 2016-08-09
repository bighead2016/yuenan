-module(mod_tencent_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").

-include("tencent.hrl").

-compile(export_all).

login(Player) ->
    Sql = <<"select `tencent` from `game_tencent` where `user_id` = '", (misc:to_binary(Player#player.user_id))/binary, "'">>,
    case mysql_api:select(Sql) of
        {?ok, [TencentData]} ->
            TencentData2 = mysql_api:decode(TencentData),
            case is_record(TencentData2,tencent_data) of
                true ->
                    Player#player{tencent = TencentData2};
                false ->
                    Player#player{tencent = init()}
            end;
        {?ok, []} ->
            Player#player{tencent = init()};
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.

login(Player,[]) ->
	{?ok, login(Player)}.

get_tencent_data(#player{} = Player) ->
	case Player#player.tencent of
		Tencent when is_record(Tencent,tencent_data) -> judge_next_day(Tencent);
        ?null ->
            player_api:process_send(Player#player.user_id, ?MODULE, login, []),
            init()
	end.

judge_next_day(Tencent) ->
    case misc:check_same_day(Tencent#tencent_data.time) of
        true ->
            Tencent;
        false ->
            Tencent#tencent_data
                {
                    daily_pack = 0,         %% 每日礼包是否已领
                    daily_pack_year = 0,
                    share_step = 0,
                    time = misc:seconds()
                }
    end.

init() ->
   #tencent_data
        {
            daily_pack = 0,         %% 每日礼包是否已领
            daily_pack_year = 0,
            new_pack = 0,           %% 新手礼包是否已领
            lv_pack = 10,           %% 等级礼包进度
            time = misc:seconds()
        }.


%% 退出时保存
logout(Player) ->
    TencentData = Player#player.tencent,
    mysql_api:insert(<<"replace into `game_tencent` (`user_id`,`tencent`) values ('", 
                       (misc:to_binary(Player#player.user_id))/binary, "', ", 
                       (mysql_api:encode(TencentData))/binary, " )">>),
    ok.