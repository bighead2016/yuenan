-module(apple).

-include("const.common.hrl").
-include("record.data.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").

-define(LOG(Format, Args),  %% console输出
        io:format("[~w]:" ++ Format ++ "~n", [?LINE] ++ Args)).
-define(K(Pid, NetId),
        file:write_file("idx", io_lib:format("{~p,~p}.~n", [Pid, NetId]), [append])).
-define(F(NetId, Format, Args), 
        file:write_file(lists:concat(["L_", NetId, ".log"]), io_lib:format(Format++"~n", []++Args), [append])).
-define(D(UserId, Data), 
        file:write_file(lists:concat(["L_", UserId, ".dbg"]), Data, [append])).
-define(E(NetId, Time, Data), 
        file:write_file(lists:concat(["L_", NetId, ".err"]), io_lib:format("~p|"++Data++"~n", [Time]), [append])).
-define(TYPE_EOF,   0).
-define(TYPE_SEND,  1).
-define(TYPE_RECV,  2).
-define(TYPE_DATE,  3).
-define(TYPE_OTHER, 4).
-define(IDX,        idx).
-record(line_battle, {bout, type, list}).

-export([
         read_debug/0
        ]).

%%-------------------------------debug--------------------------------------
read_debug() ->
    {ok,[[FileName]]} = init:get_argument(battle_file),
    {ok,[[Type]]} = init:get_argument(ttt),
    Fd = read_file(FileName),
    analyse_file(Fd, Type),
    erlang:halt().

%%---------------------------------------------------------------------------
analyse_file(0, _) -> ok;
analyse_file(Fd, Type) ->
    Line = file:read_line(Fd),
    Info = analyse_line(Line, Type),
    case Info of 
        'eof' ->
            catch file:close(Fd),
            ok;
        _ ->
            analyse_file(Fd, Type)
    end.

analyse_line({ok, "\n"}, _Type) ->
    [];
analyse_line({ok, Line}, Type) ->
    Result    = re:split(Line, "[\|]", [{return, list}]),
    LexedLine = analyse_lex(Result, Type),
    write_line(LexedLine),
    Line;
analyse_line(Line, _Type) ->
    Line.

analyse_lex([_, Bout, Type, List], _) ->
    Bout2 = misc:to_integer(Bout),
    Type2 = misc:to_integer(Type),
    List2 = misc:string_to_term(List),
    record_line(Bout2, Type2, List2);
analyse_lex(X, _Type) ->
    io:format("[~p]~n", [X]),
    record_line(0, 0, []).
%% 
record_line(Bout, Type, List) ->
    #line_battle{bout = Bout, type = Type, list = List}.

write_line(#line_battle{bout = 0, list = []}) -> ok;
write_line(#line_battle{bout = Bout, type = 2, list = List}) ->
    io:format("----------------------第[~p]回合 开始-------------------------------~n", [Bout]),
    write_line_2(List),
    ok;
write_line(#line_battle{type = 1, list = List}) ->
%%     io:format("第[~p]回合->[~p]~n", [Bout, List]),
    write_line_cmd(List),
    ok.

write_line_2([{1, Idx, Hurt, Hp, Hpmax, Anger, DList}|Tail]) ->
    io:format("左[~p]减少[~p]血，现在[~p/~p]，怒气[~p]~n删除buff[~p]~n~n", [Idx, Hurt, Hp, Hpmax, Anger, DList]),
    write_line_2(Tail);
write_line_2([{2, Idx, Hurt, Hp, Hpmax, Anger, DList}|Tail]) ->
    io:format("右[~p]减少[~p]血，现在[~p/~p]，怒气[~p]~n删除buff[~p]~n~n", [Idx, Hurt, Hp, Hpmax, Anger, DList]),
    write_line_2(Tail);
write_line_2([]) ->
    ok.
%% 
%% write_line_buff([]) ->
%%     io:format("]~n~n", []);
%% write_line_buff([{BuffId}]) when is_integer(BuffId) ->
%%     Buff = get_buff(BuffId),
%%     io:format("{~ts[~ts]}]~n~n", [binary_to_list(unicode:characters_to_binary(Buff#rec_buff.name)), 
%%                           binary_to_list(unicode:characters_to_binary(Buff#rec_buff.desc))]);
%% write_line_buff([{BuffId}|Tail]) when is_integer(BuffId) ->
%%     Buff = get_buff(BuffId),
%%     io:format("{~ts[~ts]},", [binary_to_list(unicode:characters_to_binary(Buff#rec_buff.name)), 
%%                           binary_to_list(unicode:characters_to_binary(Buff#rec_buff.desc))]),
%%     write_line_buff(Tail).

write_line_buff_2([]) ->
    io:format("]~n", []);
write_line_buff_2([{_, Id, BuffType, V, Bout}]) ->
    Buff = get_buff(BuffType),
    io:format("{~p:~ts[~ts:~p]还剩[~p]回合}]~n", [Id,
                                  binary_to_list(unicode:characters_to_binary(Buff#rec_buff.name)), 
                                  binary_to_list(unicode:characters_to_binary(Buff#rec_buff.desc)),
                                  V, Bout
                                  ]);
write_line_buff_2([{_, Id, BuffType, V, Bout}|Tail]) ->
    Buff = get_buff(BuffType),
    io:format("{~p:~ts[~ts:~p]还剩[~p]回合}", [Id,
                                  binary_to_list(unicode:characters_to_binary(Buff#rec_buff.name)), 
                                  binary_to_list(unicode:characters_to_binary(Buff#rec_buff.desc)),
                                  V, Bout
                                  ]),
    write_line_buff_2(Tail).

write_line_cmd([{SkillId, SkillLv, CmdList}|Tail]) ->
    Skill = get_skill(SkillId),
    io:format("使用[~p]级技能[~ts]~n", [SkillLv, binary_to_list(unicode:characters_to_binary(Skill#skill.name))]),
    write_line_cmdlist(CmdList),
    write_line_cmd(Tail);
write_line_cmd([]) ->
    ok.

write_line_cmdlist([{Times, 1, Idx, IsCrit, IsDisplay, Hurt, Hp, HpMax, Anger, AttrList, BuffList}|Tail]) ->
    Crit = get_crit(IsCrit),
    Displayer = get_display(IsDisplay),
    io:format("[~p]左[~p][~ts|~ts],伤害[~p]血，现在[~p/~p]，怒气[~p], attr[~w], buff[", 
              [Times, Idx, binary_to_list(unicode:characters_to_binary(Crit)), 
                           binary_to_list(unicode:characters_to_binary(Displayer)), Hurt,
                           Hp, HpMax, Anger, AttrList]),
    write_line_buff_2(BuffList),
    io:format("-------------------~n"),
    write_line_cmdlist(Tail);
write_line_cmdlist([{Times, 2, Idx, IsCrit, IsDisplay, Hurt, Hp, HpMax, Anger, AttrList, BuffList}|Tail]) ->
    Crit = get_crit(IsCrit),
    Displayer = get_display(IsDisplay),
    io:format("[~p]右[~p][~ts|~ts],伤害[~p]血，现在[~p/~p]，怒气[~p], attr[~w], buff[", 
              [Times, Idx, binary_to_list(unicode:characters_to_binary(Crit)), 
                           binary_to_list(unicode:characters_to_binary(Displayer)), Hurt,
                           Hp, HpMax, Anger, AttrList]),
    write_line_buff_2(BuffList),
    io:format("-------------------~n"),
    write_line_cmdlist(Tail);
write_line_cmdlist([]) ->
    ok.

get_crit(0) -> <<"战斗暴击标示--默认无效">>;
get_crit(1) -> <<"战斗暴击标示--暴击">>;
get_crit(2) -> <<"战斗暴击标示--非暴击">>.

get_display(1)-><<"战斗表现--正常攻击">>;
get_display(2)-><<"战斗表现--正常受击(敌方)">>;
get_display(3)-><<"战斗表现--正常受击(己方)">>;
get_display(4)-><<"战斗表现--格挡">>;
get_display(5)-><<"战斗表现--闪避">>;
get_display(11)-><<"战斗表现--反击攻击">>;
get_display(12)-><<"战斗表现--反击受击">>;
get_display(21)-><<"战斗表现--BUFF影响(前)">>;
get_display(22)-><<"战斗表现--BUFF影响(中)">>;
get_display(23)-><<"战斗表现--BUFF影响(后)">>;
get_display(31)-><<"战斗表现--普通攻击">>;
get_display(32)-><<"战斗表现--普通受击">>;
get_display(41)-><<"战斗表现--天赋技能攻击(前)">>;
get_display(42)-><<"战斗表现--天赋技能防守(前)">>;
get_display(43)-><<"战斗表现--天赋技能攻击(后)">>;
get_display(44)-><<"战斗表现--天赋技能防守(后)">>.
    
get_skill(1) -> #skill{name = <<"陷阵普攻">>}; 
get_skill(2) -> #skill{name = <<"飞军普攻">>};
get_skill(3) -> #skill{name = <<"天机普攻">>};
get_skill(SkillId) ->
    case data_skill:get_skill({SkillId, 1}) of
        null ->
            case data_skill:get_default_skill({SkillId, 1}) of
                null ->
                    #skill{name = <<"?">>};
                Skill ->
                    Skill
            end;
        Skill ->
            Skill
    end.

get_buff(BuffId) ->
    case data_buff:get_base_buff(BuffId) of
        null ->
            #rec_buff{name = <<"?">>, buff_type = BuffId, desc = <<"?">>};
        Buff ->
            Buff
    end.
    
        
%% 读取文件句柄
read_file(FileName) ->
    case filelib:is_file(FileName) of
        true ->
            case file:open(FileName, [read]) of
                {ok, Fd} ->
                    Fd;
                {error, Reason} ->
                    ?LOG("reason=~p", [Reason]),
                    0
            end;
        false ->
            ?LOG("reason=not a file.", []),
            0
    end.

