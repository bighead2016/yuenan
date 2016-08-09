%% 阵法api
-module(camp_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([init/3, init_partner/2, init_partner_ext/2, get_curent_camp/1, get_curent_camp_cb/2, 
         get_player_camp/2, camp_position_count/2, read_camp/2, camp_attr_ext/2,
         get_max_lv/1]).

-export([camp_info/1, 
		 exchange_pos/4, 
		 set_pos/6, 
		 start_camp/2, 
		 upgrade/2, 
		 get_pos/2, 
		 remove/3, 
		 remove_partner_by_id/3,
		 remove_partner_all_camp/2,
		 get_pos_by_id/3,
         get_empty/2,
		 get_empty_desc/2,
         level_up/1,
		 default_camp/0,
         login_packet/2,
		 curcamp_have_empty/1
     ]).
-export([
		 msg_camp_sc_use/1,
		 msg_camp_sc_info/2,
         msg_sc_new/1,
		 msg_camp_sc_pos_update/5,
		 msg_camp_sc_pos_remove/3,
		 msg_camp_sc_pos_null/1
		]).
%%
%% API Functions
%%
init(UserId, Pro, {CampId, Lv}) ->
    RecCamp = data_camp:get_camp({CampId, Lv}),
    Position = RecCamp#rec_camp.position,
	%%按职业设置人物初始站位
	StartIdx = 
		if Pro =:= ?CONST_SYS_PRO_XZ ->
				2;
			?true ->
				5
		end,
    NewCampList = 
        case camp_mod:get_empty(Position, StartIdx) of
            {?ok, Idx} ->
                NewPosition = erlang:setelement(Idx, Position, #camp_pos{id = UserId, idx = Idx, type = ?CONST_CAMP_TYPE_PLAYER}),
                [#camp{camp_id=CampId, lv=Lv, position=NewPosition}];
            {?error, ErrorCode} ->
                ?MSG_ERROR("create_camp:ErrorCode=~p", [ErrorCode]),
                []
        end,
    #camp_data{camp_use = CampId, camp = NewCampList}.

%% 初始武将站位(公孙婷)
init_partner(Player, PartnerId) ->
	Pro = (Player#player.info)#info.pro,
	Sex = (Player#player.info)#info.sex,
	ID = 
		if Pro =:= ?CONST_SYS_PRO_XZ ->
			   ?CONST_PARTNER_THE_FIRST;
		   ?true ->
			   ?CONST_PARTNER_THE_SECOND
		end,
	case lists:member(PartnerId, [ID]) of
		?true ->
			RecPlayerInit = data_player:get_player_init({Pro, Sex}),
			{CampId, _} = RecPlayerInit#rec_player_init.camp,
			CampIdx = 
				case PartnerId =:= ?CONST_PARTNER_THE_FIRST of
					?true ->
						5;
					?false ->
						2
				end,
			case camp_api:set_pos(Player, CampId, CampIdx, ?CONST_SYS_PARTNER, PartnerId, ?CONST_CAMP_SET_POS_TYPE_1) of
				{?ok, TempPlayer1} ->
					{?ok, TempPlayer1};
				{?error, _ErrorCode} ->
					{?ok, Player}
			end;
		?false ->
			{?ok, Player}
	end.
%% 初始武将上阵
init_partner_ext(Player, PartnerId) ->
	CurCamp		= get_curent_camp(Player),
	CampId		= CurCamp#camp.camp_id,
	Position	= CurCamp#camp.position,
	 case get_empty_desc(Position, 9) of
        {?ok, CampIdx} ->
				case camp_api:set_pos(Player, CampId, CampIdx, ?CONST_SYS_PARTNER, PartnerId, ?CONST_CAMP_SET_POS_TYPE_1) of
					{?ok, TempPlayer1} ->
						{?ok, TempPlayer1};
					{?error, _ErrorCode} ->
						{?ok, Player}
				end;
		 _ ->
			 {?ok, Player}
	 end.
			
login_packet(Player, Packet) ->
    Packet2 = camp_info(Player),
    {Player, <<Packet/binary, Packet2/binary>>}.

%% 升级学习阵法
level_up(Player) ->
    Info = Player#player.info,
    Lv = Info#info.lv,
    CampLvList = data_camp:get_camp_list(),
    level_up(Player, CampLvList, Lv).

level_up(Player, [{CampId, Lv}|Tail], Lv) ->
    case upgrade(Player, CampId) of
        {?ok, Player2} ->
            {?ok, Player3} = task_api:update_camp(Player2, Lv+1),
            level_up(Player3, Tail, Lv);
        {?error, _ErrorCode} ->
            level_up(Player, Tail, Lv)
    end;
level_up(Player, [{_, _}|Tail], Lv) ->
    level_up(Player, Tail, Lv);
level_up(Player, [], _) ->
    Player.

camp_info(Player) ->
    camp_mod:camp_info(Player).

%% 阵型位置总数
camp_position_count(CampId, Lv) ->
	RecCamp 	= data_camp:get_camp({CampId, Lv}),
    Position	= RecCamp#rec_camp.position,
	Fun			= fun(?CONST_SYS_FALSE, Acc) -> Acc; (?CONST_SYS_TRUE, Acc) -> Acc + 1 end,
	lists:foldl(Fun, 0, misc:to_list(Position)).

%% 读取阵型
read_camp(CampId, Lv) ->
	RecCamp 	= data_camp:get_camp({CampId, Lv}),
	#camp{
		  camp_id    	= CampId,            		% 阵法id
		  lv          	= Lv,            			% 等级
		  position		= RecCamp#rec_camp.position	% 阵型 {#camp_pos, ...} 固定9个格子
		 }.

%% 读取战斗中阵型属性加成
camp_attr_ext(0, 0) -> [];
camp_attr_ext(CampId, Lv) ->
	RecCamp 	= data_camp:get_camp({CampId, Lv}),
	[{RecCamp#rec_camp.cacl_type, RecCamp#rec_camp.type, RecCamp#rec_camp.value}].

%% 获取当前玩家阵法信息
get_curent_camp(#player{camp = CampData}) -> get_curent_camp(CampData);
get_curent_camp(#camp_data{camp_use = CurentCampId, camp = CampList}) ->
    case lists:keyfind(CurentCampId, #camp.camp_id, CampList) of
        Camp when is_record(Camp, camp) -> Camp;
        ?false -> default_camp()
    end;
get_curent_camp(UserId) ->
	player_api:process_call(UserId, ?MODULE, get_curent_camp_cb, []).
get_curent_camp_cb(Player, _) ->
    Camp = get_curent_camp(Player),
    {?ok, Camp, Player}.

get_player_camp(#player{camp = #camp_data{camp = CampList}}, CampId) ->
	case lists:keyfind(CampId, #camp.camp_id, CampList) of
        Camp when is_record(Camp, camp) -> {?ok, Camp};
        ?false -> {?error, ?TIP_CAMP_NOT_EXIST}
    end.

% 通过武将id删除其在阵法中的位置
remove_partner_by_id(Player, Id, #camp{camp_id = CampId, position = Position}) ->
	case get_pos_by_id(Position, Id, 1)  of
		?false ->
			{?ok, Player};
		{?ok, CampIdx} ->
			camp_mod:remove(Player, CampId, CampIdx)
	end;
remove_partner_by_id(Player, _Id, _Camp) ->
	{?ok, Player}.

%% 删除所有阵法中武将Id的位置
remove_partner_all_camp(Player, Id) ->
	CampList = (Player#player.camp)#camp_data.camp,
	remove_partner_all_camp(Player, Id, CampList).
remove_partner_all_camp(Player, _Id, []) -> {?ok, Player};
remove_partner_all_camp(Player, Id, [Camp|CampList]) ->
	{?ok, Player2} = remove_partner_by_id(Player, Id, Camp),
	remove_partner_all_camp(Player2, Id, CampList).
	
get_pos_by_id(Position, 0, Idx) when Idx =< 9 -> 
	PosInfo = element(Idx, Position),
	if is_record(PosInfo, camp_pos) andalso PosInfo#camp_pos.type =:= ?CONST_SYS_PLAYER ->
		   {?ok, Idx};
	   ?true ->
		   get_pos_by_id(Position, 0, Idx + 1)
	end;
get_pos_by_id(Position, PartnerId, Idx) when Idx =< 9 ->
	PosInfo = element(Idx, Position),
	if is_record(PosInfo, camp_pos) andalso PartnerId =:= PosInfo#camp_pos.id ->
		   {?ok, Idx};
	   ?true ->
		   get_pos_by_id(Position, PartnerId, Idx + 1)
	end;
get_pos_by_id(_Position, _Id, _Idx) -> ?false.

%% 阵型升级
%% {?error, ErrorCode}/{?ok, Player2}
upgrade(Player, CampId) ->
    camp_mod:upgrade(Player, CampId).
    
exchange_pos(Player, CampId, IdxFrom, IdxTo) ->
    camp_mod:exchange_pos(Player, CampId, IdxFrom, IdxTo).

set_pos(Player, CampId, CampIdx, Type, Id, UseType) ->
    camp_mod:set_pos(Player, CampId, CampIdx, Type, Id, UseType).

start_camp(Player, CampId) ->
    camp_mod:start_camp(Player, CampId).

remove(Player, CampId, CampIdx) ->
    camp_mod:remove(Player, CampId, CampIdx).

get_pos(Player, CampId) ->
    camp_mod:get_pos(Player, CampId).

%% 顺序找空位
get_empty(Position, Idx) ->
    camp_mod:get_empty(Position, Idx).

%% 反序找空位
get_empty_desc(Position, Idx) ->
	camp_mod:get_empty_desc(Position, Idx).

default_camp() ->
    RecCamp = data_camp:get_camp({?CONST_CAMP_DEFAULT, ?CONST_TEAM_MIN_CAMP_LV}),
    #camp{camp_id = RecCamp#rec_camp.camp_id, lv = ?CONST_TEAM_MIN_CAMP_LV, position = RecCamp#rec_camp.position}.

%% 判断当前阵法是否为空
curcamp_have_empty(Player) ->
	CurCamp 		= get_curent_camp(Player),
	Position 		= CurCamp#camp.position,
	PositionList	= misc:to_list(Position),
	case lists:member(1, PositionList) of
		?true ->
			?true;
		?false ->
			?false
	end.

%% 阵法等级
get_max_lv(Player) ->
    CampData = Player#player.camp,
    CampList = CampData#camp_data.camp,
    camp_mod:get_max_lv(CampList, 0).

%%---------------------------------------协议-----------------------------------------------

%% 当前使用阵型
msg_camp_sc_use(CampId) ->
	misc_packet:pack(?MSG_ID_CAMP_SC_USE, ?MSG_FORMAT_CAMP_SC_USE, [CampId]).
%% 阵型信息
msg_camp_sc_info([#camp{camp_id = CampId, lv = Lv}|CampList], AccPacket) ->
	Packet	= misc_packet:pack(?MSG_ID_CAMP_SC_INFO, ?MSG_FORMAT_CAMP_SC_INFO, [CampId,Lv]),
	msg_camp_sc_info(CampList, <<AccPacket/binary, Packet/binary>>);
msg_camp_sc_info([], AccPacket) -> AccPacket.

%% 新学习的阵法
%%[CampId]
msg_sc_new(CampId) ->
    misc_packet:pack(?MSG_ID_CAMP_SC_NEW, ?MSG_FORMAT_CAMP_SC_NEW, [CampId]).

%% 更新阵型站位信息
msg_camp_sc_pos_update(CampId,CampIdx,Type,Id,IsSet) ->
	misc_packet:pack(?MSG_ID_CAMP_SC_POS_UPDATE, ?MSG_FORMAT_CAMP_SC_POS_UPDATE, [CampId,CampIdx,Type,Id,IsSet]).
%% 移除阵型站位信息
msg_camp_sc_pos_remove(CampId,CampIdx,IsOff) ->
	misc_packet:pack(?MSG_ID_CAMP_SC_POS_REMOVE, ?MSG_FORMAT_CAMP_SC_POS_REMOVE, [CampId,CampIdx,IsOff]).

%% 查看阵法是否存在空位置
msg_camp_sc_pos_null(Flag) ->
	misc_packet:pack(?MSG_ID_CAMP_SC_POS_NULL, ?MSG_FORMAT_CAMP_SC_POS_NULL, [Flag]).
