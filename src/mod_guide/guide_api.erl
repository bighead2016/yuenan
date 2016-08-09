%% Author: Administrator
%% Created: 2012-10-22
%% Description: TODO: Add description to guide_api
-module(guide_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").

%%
%% Exported Functions
%%
-export([add_module/2, finish_module/2, init_player_guide/1, login_packet/2, read/1,
         flag_got/2, is_finish_guide/2, read_rank/1]).
-export([msg_scinfo/1]).

%%
%% API Functions
%%

%% 初始化
init_player_guide(GuideList) ->
	guide_mod:init(GuideList, []).
%% 读取静态信息
read(SysId) ->
    data_guide:get_guide(SysId).
read_rank(SysRank) ->
    data_guide:get_guide_rank(SysRank).

%% 开启引导点
add_module(GuideList, Module) when is_number(Module) orelse is_list(Module) ->
	guide_mod:add_module(GuideList, Module);
add_module(GuildList, _) ->
    GuildList.

finish_module(GuideList, Module) ->
	guide_mod:finish_module(GuideList, Module).

login_packet(Player, Packet) when ?CONST_SYS_USER_STATE_GM =:= Player#player.state ->
    GuideList = Player#player.guide,
    Packet2   = guide_api:msg_scinfo(GuideList),
    {Player, <<Packet/binary, Packet2/binary>>};
login_packet(Player, Packet) ->
    GuideList = Player#player.guide,
    Packet2 = guide_api:msg_scinfo(GuideList),
    {Player, <<Packet/binary, Packet2/binary>>}.

%% 领取引导奖励标识
flag_got(Player, Module) ->
    UserId     = Player#player.user_id,
    GuideList  = Player#player.guide,
    GuildList2 = guide_mod:flag_got(UserId, GuideList, Module),
    Player#player{guide = GuildList2}.

is_finish_guide(Player, Module) ->
	GuideList  = Player#player.guide,
	case lists:keyfind(Module, #guide.module, GuideList) of
		Tuple when is_record(Tuple, guide) ->
			case Tuple#guide.state of
				?CONST_GUIDE_FINISHED ->
					?true;
				_Other ->
					?false
			end;
		_OtherTuple ->
			?false
	end.
				
%% level_up(#player{info = #info{lv = ?CONST_GUIDE_CAMP_EXT_LV}} = Player) ->
%%     GuideList  = Player#player.guide,
%%     GuideList2 = add_module(GuideList, ?CONST_GUIDE_CAMP_EXT_GUIDE_ID),
%%     Player#player{guide = GuideList2};
%% level_up(Player) -> Player.

%% 模块信息
%%[{Module,State}]
msg_scinfo([]) -> <<>>;
msg_scinfo(List1) ->
    List2 = [{Module, State}||#guide{module = Module, state = State} <- List1],
    misc_packet:pack(?MSG_ID_GUIDE_SCINFO, ?MSG_FORMAT_GUIDE_SCINFO, [List2]).

%%
%% Local Functions
%%