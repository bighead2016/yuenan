%%% @author np
%%% @doc @todo Add description to t_mod.


-module(t_mod).

%%=s=======================================define & records======================================


% sys
-define(REG_NAME,             ?MODULE). % 注册名
-define(F(AccId),             lists:concat([p, 10006, ".log"])). % 文件名
-define(FILE_OPTIONS,         [append, raw]). % 文件打开选项
-define(DO(Cmd),              gen_fsm:send_event(?REG_NAME, Cmd)). % 状态转换
-define(EVENT(Msg),           gen_fsm:send_all_state_event(?REG_NAME, Msg)).
-define(LOG(Format, Data),              % 日志
            io:format("[~p]:" ++ Format ++ " ~n", [?LINE] ++ Data)). 
-define(LOG(Format),                    % 日志
            io:format("[~p]:" ++ Format ++ " ~n", [?LINE])). 
-define(FOG(StateData, Format, Data),
            file:write(StateData#state.fd, io_lib:format(Format++ " ~n", Data))).

% 状态
-define(ON,                   on).
-define(OFF,                  off).
-define(LOGIN,                login).
-define(DOING,                doing).

-define(TRUE,  1).
-define(FALSE, 0).
-record(schedule, {
                    in  = [],
                    out = []
                  }).
-record(task,     {
                    id    = 0,
                    state = 0
                  }).

%% ====================================================================
%% API functions
%% ====================================================================
-export([handle/3]).
%%------------------------------------------------------------------------

handle(Schedule, Cmd, BinData) ->
    OutList  = Schedule#schedule.out,
    PacketId = t_packet:get_id(Cmd, BinData),
    NewOutList = 
        case lists:keytake(PacketId, #task.id, OutList) of
            {value, _, OutList2} ->
                Task = #task{id = PacketId, state = ?TRUE},
                [Task|OutList2];
            false when unknown =/= PacketId ->
                [#task{id = PacketId, state = ?TRUE}|OutList];
            false ->
                OutList
        end,
    NextPacketId = t_packet:next(PacketId),
    Packet = t_packet:get_packet(NextPacketId),
    Schedule2 = Schedule#schedule{out = NewOutList},
    ?LOG("l=~w", [NewOutList]),
    {Packet, Schedule2}.

%% %%------------------------------------------------------------------
%% flag(List, Flag) ->
%%     lists:member(, List)
%%     

%% ====================================================================
%% Internal functions
%% ====================================================================

