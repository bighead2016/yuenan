%%
%% 请注意以下两点：
%%   1.所有数据的检测以fields的字段为准，
%%     也就是说，如果出现fields和values长度不一样，或者出现错位，
%%     则以fields为判定基础
%%   2.value不允许有空，所以，在生成检测的时候，会提示。
%%     如果检测不能通过，则会打印出第几行，第几列出现在什么问题。
%% p.s. enjoy the game && have fun.
%%


-module(xlsx2yrl_mochi).
-export([start/2]).
-include_lib("xmerl/include/xmerl.hrl").
-include("const.generator.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc    入口
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 参数由shell中读取
%% xlsxfilename = xlsx源文件名
%% maxline = 最大扫描行数
start(PidParent, [FileRootName, Ver]) ->
    try
        get_shared_string(FileRootName),
        List        = get_worksheet_data(FileRootName),
        erase(),
        put(parent, {PidParent, FileRootName}),
        YrlName = write_erl_file(List, FileRootName, Ver),
        erlang:garbage_collect(),
        PidParent ! {ok, self(), {stop, YrlName}}
    catch
          Type:Why->
              ?P("!err[~p|~p|~p]~n~p", [FileRootName, Type, Why, erlang:get_stacktrace()]),
              send2parent({error, self(), {check, FileRootName, Type, Why, erlang:get_stacktrace()}})
     end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   获取共享字串
%% @return List = [#xlsx_share_string{}, #xlsx_share_string{}, ...]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_shared_string(FileRootName) ->
    SharedStringsXml    = xmerl_scan:file(FileRootName++"/xl/sharedStrings.xml", [{encoding, 'utf-8'}]),
    {Doc, _}            = SharedStringsXml,
    V = read_si(Doc),
    V.
%%     ok.
%%     RealText            = xmerl_xpath:string("/sst/si/t/text()", Doc),
%%     get_text(RealText, []).

read_si(XmlElement) ->
    Si = yrl_tools:read_content(XmlElement),
    X = yrl_tools:read_element(Si, 'si', []),
    read_t(X, []).

read_t([XmlElement|Tail], OldList) ->
    T = yrl_tools:read_content(XmlElement),
    X2 = yrl_tools:read_element(T, 't', []),
    X2List = 
        case X2 of
            [] ->
                X3 = yrl_tools:read_element(T, 'r', []),
                X = read_t(X3, []),
                X;
            _ ->
                read_value(X2, [])
        end,
    read_t(Tail, lists:append([OldList, X2List]));
read_t([], OldList) ->
    OldList.

read_value([XmlElement|Tail], OldList) ->
    Tv = yrl_tools:read_content(XmlElement),
    Value = read_tv(Tv, []),
    read_value(Tail, lists:append([OldList, Value]));
read_value([], OldList) ->
    OldList.

read_tv(#xmlText{value = Value}, OldList) ->
    [Value|OldList];
read_tv([#xmlText{parents = [_, {si, Num}, _], value = Text}|Tail], OldList) ->
    Text2 = 
        case get(Num) of
            undefined ->
                Text;
            PreText ->
                lists:concat([PreText, Text])
        end,
    NewResultList = [#xlsx_share_string{id=Num, str=Text2}|OldList],
    put(Num, Text2), % 放入进程字典，格式{id, str}
    read_tv(Tail, NewResultList);
read_tv([#xmlText{parents = [_, _, {si, Num}, _], value = Text}|Tail], OldList) ->
    Text2 = 
        case get(Num) of
            undefined ->
                Text;
            PreText ->
                lists:concat([Text, PreText])
        end,
    NewResultList = [#xlsx_share_string{id=Num, str=Text2}|OldList],
    put(Num, Text2), % 放入进程字典，格式{id, str}
    read_tv(Tail, NewResultList);
read_tv([], OldList) ->
%%     OldList;
%% read_tv(X, OldList) ->
%%     ?PRINT_LINE("x=~p", [X]),
    OldList.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   获取共享字串数据，同时放入进程字典
%% %%
%% %% @return List = [#xlsx_share_string{}, #xlsx_share_string{}, ...]
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_text([], ResultList) ->
%%     ResultList;
%% get_text([{xmlText, [{_, _}, {si, Num}, {_,_}], _Pos, _, Text, _}|Tail], ResultList) ->
%%     Text2 = 
%%         case get(Num) of
%%             undefined ->
%%                 Text;
%%             PreText ->
%%                 lists:concat([PreText, Text])
%%         end,
%%     NewResultList = [#xlsx_share_string{id=Num, str=Text2}|ResultList],
%%     put(Num, Text2), % 放入进程字典，格式{id, str}
%%     get_text(Tail, NewResultList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   获取worksheet的数据
%% @return [#row_cmd...]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_worksheet_data(FileRootName) ->
    case file:read_file(FileRootName++"/xl/worksheets/sheet1.xml") of
        {ok, Bin} ->
            Parsed = mochiweb_html:parse(Bin),
            List = erlang:element(3, Parsed),
            case lists:keyfind(<<"sheetdata">>, 1, List) of
                {_, _, RowList} ->
                    List2 = read_row(RowList, []),
                    List2;
                _ ->
                    []
            end;
        _ ->
            []
    end.

read_row([{<<"row">>, RList, CList}|Tail], RowCmd) ->
    % 第几行
    {_, PosT}   = lists:keyfind(<<"r">>, 1, RList),
    PosT2       = erlang:binary_to_list(PosT),
    Pos         = erlang:list_to_integer(PosT2), 
    % 当前行各列的值
    NewRow      = read_col(CList, #row{num=Pos}),
    CmdCmd      = get_cmd(NewRow#row.cols, {"", []}),
    RowData     = get_data(CmdCmd, NewRow#row.cols, []),
    case lists:keytake(CmdCmd, #cmd.cmd, RowCmd) of
        false ->
            Num  = NewRow#row.num,
            Row2 = record_row(Num, RowData),
            read_row(Tail, [#cmd{cmd = CmdCmd, rows = [Row2]}|RowCmd]);
        {_Count, CmdList = #cmd{rows = OldRows}, DeletedRowCmd} ->
            Num  = NewRow#row.num,
            Row2 = record_row(Num, RowData),
            read_row(Tail, [CmdList#cmd{rows=[Row2|OldRows]}|DeletedRowCmd])
    end;
read_row([], RowCmd) ->
    RowCmd.

record_row(Num, RowData) ->
    #row{num=Num, cols=RowData}.

get_cmd([#col{num = 1, value = Cmd}|_Tail], _) ->
    Cmd;
get_cmd([_Col|Tail], Cmd) ->
    get_cmd(Tail, Cmd);
get_cmd(_, Cmd) ->
    Cmd.

get_data(?ERL, [#col{value = []} = Col|Tail], RowData) ->
    RowData2 = [Col#col{value = ?NO}|RowData],
    get_data(?ERL, Tail, RowData2);
get_data(Cmd, [#col{value = []}|Tail], RowData) ->
    get_data(Cmd, Tail, RowData);
get_data(Cmd, [#col{num = 1, value = _Cmd}|Tail], RowData) ->
    get_data(Cmd, Tail, RowData);
get_data(Cmd, [Col|Tail], RowData) ->
    RowData2 = [Col|RowData],
    get_data(Cmd, Tail, RowData2);
get_data(_Cmd, _, RowData) ->
    RowData.

%% 读取列
read_col([{<<"c">>, RList, VList}|Tail], Row = #row{cols=OldColList}) ->
    try
        {_, NickT}  = lists:keyfind(<<"r">>, 1, RList),
        {Pos, Nick} = yrl_tools:get_col_pos_x(erlang:binary_to_list(NickT), {0, ""}),
        Type        = 
            case lists:keyfind(<<"t">>, 1, RList) of
                {_, TypeT} ->
                    erlang:binary_to_list(TypeT);
                _ ->
                    "d"
            end,
%%         ?PRINT_LINE("~p|~p", [VList, RList]),
        TextList    = 
            case lists:keyfind(<<"v">>, 1, VList) of
                {_, _, TextListT} ->
                    TextListT;
                _ ->
                    []
            end,
        case TextList of
            [] ->
                read_col(Tail, Row);
            _ ->
                Text        = yrl_tools:get_real_value(TextList, Type, []),
                Col2        = record_col(Pos, Nick, Text, Type),
                ColList     = [Col2|OldColList],
                Row2        = set_row_col(Row, ColList),
                read_col(Tail, Row2)
        end
    catch
        _:_ ->
            ?PRINT_LINE("stack=~s", [erlang:get_stacktrace()]),
            read_col(Tail, Row) % 有可能没值，那就直接无视
    end;
read_col([], Row) ->
    ColList  = Row#row.cols,
%%     ColList2 = lists:reverse(ColList),
    Row2     = set_row_col(Row, ColList),
    Row2.

record_col(Pos, Nick, Text, Type) ->
    #col{num=Pos, nick=Nick, value=Text, type=Type}.

set_row_col(Row, Cols) ->
    Row#row{cols = Cols}.
%%------------------------------xlsx解释部分结束，下面用于组织与编写erl文件-----------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   写入模块文件
%% @param  YrlName 记录名
%% @return ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_erl_file(List, FileRootName, Ver) ->
    try
        {ok, 
         {ModName, YrlName, RecordRow}, 
         {FieldRow, _ErlRow, NoteRow, ValueList}, 
         RemList, 
         List2} = chk_values(List, FileRootName),
        
        YrlModName = "../../yrl/"++Ver++"/",
        YrlModNameX = YrlModName++ModName,
        file:del_dir(YrlModNameX),
        file:make_dir(YrlModNameX),
        file:make_dir(YrlModName),
        YrlFullName = lists:concat(["../../yrl/"++Ver++"/", ModName, "/", YrlName, ".yrl"]),
        file:delete(YrlFullName),
        {ok, Fd} = open_file(YrlFullName),
        write_module_head(Fd), % 模块头
        write_line(Fd, {ModName, YrlName, RecordRow}, 
                        {FieldRow, NoteRow, ValueList}, 
                        RemList, 
                        List2, FileRootName),
        close_file(Fd),
        YrlName
    catch
        throw:Msg ->
            ?PRINT_LINE("!err:["++FileRootName++"]"++Msg, []),
            error;
        Type:Why ->
            ?PRINT_LINE("!err:[~s]that's an error. but I don't know why, ouch. ~nHowever it was -> ~p:~p=~p~n -------~n that's all i know.", 
                        [FileRootName, Type, Why, erlang:get_stacktrace()]),
            error
    end.

%% 检测数据合法性
%% 规则比较严格：
%% 1.判定?ERL的存在性
%% 2.有时需要判定cmd的单一性
%% 3.判定与基准字段数量的出入
chk_values(List, FileRootName) ->
    % ?MOD
    {ModRow, List2} = get_only_1(?MOD, List),
    % ?YRL_NAME
    {YrlRow, List3} = get_only_1(?YRL_NAME, List2),
    % ?RECORD_NAME
    {RecordRow, List4} = get_only_1(?RECORD_NAME, List3),
    % ?ERL
    {ErlRow,   List5} = get_only(?ERL, List4),
    % ?ERL <=> ?FIELDS
    {TFieldRow, List6} = get_only(?FIELDS, List5),
    {ok, FieldRow} = chk_values(?ERL, ErlRow#row.num, ErlRow#row.cols,  ?FIELDS,  TFieldRow#row.num,  TFieldRow#row.cols, []),
    % ?ERL <=> ?NOTE
    {TNoteRow,  List7} = get_only(?NOTE, List6),
    {ok, NoteRow} = chk_values(?ERL, ErlRow#row.num, ErlRow#row.cols, ?NOTE, TNoteRow#row.num, TNoteRow#row.cols, []),
    % ?ERL <=> ?TYPE
    {TTypeRow,  List8} = get_only(?TYPE, List7),
    {ok, TypeRow} = chk_values(?ERL, ErlRow#row.num, ErlRow#row.cols, ?TYPE, TTypeRow#row.num, TTypeRow#row.cols, []),
%%     ?PRINT_LINE("~p|~p|~p", [ErlRow#row.cols, TypeRow, TTypeRow]),
    % ?ERL <=> ?VALUE
    {ValueList, List8_3}   = 
        case get_value(?VALUE, List8, 0) of
            {TValueList,   List8_2} ->
                F = fun(ValueColList, OldValueColList) ->
                            {ok, TValueList2} = chk_values(?ERL, ErlRow#row.num, ErlRow#row.cols, ?VALUE, ValueColList#row.num, ValueColList#row.cols, []),
%%                             ?PRINT_LINE("~p|~p|~p|~p", [TTypeRow#row.num, TypeRow, ValueColList#row.num, ValueColList#row.cols]),
                            chk_values_type(TTypeRow#row.num, TypeRow, ValueColList#row.num, TValueList2, []),
                            [TValueList2|OldValueColList]
                    end,
                TValueList2 = lists:foldl(F, [], TValueList),
                L = lists:reverse(TValueList2),
                {L, List8_2};
            [] ->
                {[], List8}
        end,
    
    % ?NOTE
    {RemList,   List9} = get_value(?REM, List8_3, 0),
    
    send2parent({ok, self(), {check, FileRootName}}),
    {ok, {ModRow, YrlRow, RecordRow}, {FieldRow, ErlRow, NoteRow, ValueList}, RemList, List9}.

%% 读取并验证单一数据
get_only_1(Cmd, List) ->
    case get_value(Cmd, List, 1) of
        {[FieldRow], List2} ->
            {FieldRow, List2};
        {FieldList = [FieldRow|_], _L} when is_record(FieldRow, row) ->
            throw(io_lib:format("\"~s\" is not sigle. multiply \"~s\" line is not supported, please correct them... ~n and they are -> ~p~n check result:not pass.", 
                                [Cmd, Cmd, FieldList]));
        {Field, List2} ->
            List3 = lists:reverse(List2),
            {Field, List3}
    end.

%% 读取并验证单一数据
get_only(Cmd, List) ->
    case get_value(Cmd, List, 0) of
        {[FieldRow], List2} ->
            {FieldRow, List2};
        {FieldList = [FieldRow|_], _L} when is_record(FieldRow, row) ->
            throw(io_lib:format("\"~s\" is not sigle. multiply \"~s\" line is not supported, please correct them... ~n and they are -> ~p~n check result:not pass.", 
                                [Cmd, Cmd, FieldList]));
        {Field, List2} ->
            List3 = lists:reverse(List2),
            {Field, List3}
    end.

chk_values_type(TypeRowNum,  [#col{nick = Nick, value = "integer" = Type}|TypeTail], 
                ValueRowNum, [#col{value = Value}|ValueTail], 
                ResultList) ->
    try
        case is_integer(Value) of
            true ->
                ok;
            false ->
                V2 = erlang:list_to_integer(Value),
                is_integer(V2)
        end
    catch
        _:_ ->
            try
                V3 = erlang:binary_to_integer(Value),
                is_integer(V3)
            catch
                _:_ ->
                    throw(io_lib:format("!err:[~p][~s|~p]value's type is not fit[~s][~p]", [?LINE, Nick, ValueRowNum, Type, Value]))
            end
    end,
    chk_values_type(TypeRowNum, TypeTail, ValueRowNum, ValueTail, ResultList);
chk_values_type(TypeRowNum,  [#col{value = "list"}|TypeTail], 
                ValueRowNum, [#col{value = Value}|ValueTail], 
                ResultList) when is_list(Value) orelse is_integer(Value) ->
    chk_values_type(TypeRowNum, TypeTail, ValueRowNum, ValueTail, ResultList);
chk_values_type(TypeRowNum,  [#col{nick = Nick, value = "real" = Type}|TypeTail], 
                ValueRowNum, [#col{value = Value}|ValueTail], 
                ResultList) ->
    try
        case is_integer(Value) of
            true ->
                ok;
            false ->
                case is_float(Value) of
                    true ->
                        ok;
                    false ->
                        V2 = erlang:list_to_integer(Value),
                        is_integer(V2)
                end
        end
    catch
        _:_ ->
            try
                V3 = erlang:binary_to_integer(Value),
                is_integer(V3)
            catch
                _:_ ->
                    try
                        V4 = erlang:list_to_float(Value),
                        is_float(V4)
                    catch
                        _:_ ->
                            try
                                V5 = erlang:binary_to_float(Value),
                                is_float(V5)
                            catch
                                _:_ ->
                                    throw(io_lib:format("!err:[~p][~s|~p]value's type is not fit[~s][~p]", [?LINE, Nick, ValueRowNum, Type, Value]))
                            end
                    end
            end
    end,
    chk_values_type(TypeRowNum, TypeTail, ValueRowNum, ValueTail, ResultList);
chk_values_type(_TypeRowNum,  [#col{nick = Nick, value = Type}|_TypeTail], 
                ValueRowNum, [#col{value = Value}|_ValueTail], 
                _ResultList) ->
    throw(io_lib:format("!err:[~p][~s|~p]value's type is not fit[~s][~p]", [?LINE, Nick, ValueRowNum, Type, Value]));
chk_values_type(_TypeRowNum,  [], 
                _ValueRowNum, [], 
                _ResultList) ->
    ok;
chk_values_type(_TypeRowNum,  X, 
                _ValueRowNum, Y, 
                _ResultList) ->
    ?PRINT_LINE("[~p|~p]", [X, Y]),
    ok.

%% 传入时，第一个必然是做为基准的列，例如：?ERL
%% a =:= b
chk_values(Str1, FieldRowNum, [#col{num = FieldNum, value=?YES}|FieldTail], 
           Str2, ValueRowNum, [ValueCol = #col{num = FieldNum}|ValueTail], ResultList) 
  ->
    chk_values(Str1, FieldRowNum, FieldTail, Str2, ValueRowNum, ValueTail, [ValueCol|ResultList]);
chk_values(Str1, FieldRowNum, [#col{num = FieldNum, value=?NO}|FieldTail], 
           Str2, ValueRowNum, [_ValueCol = #col{num = FieldNum}|ValueTail], ResultList) 
  ->
    chk_values(Str1, FieldRowNum, FieldTail, Str2, ValueRowNum, ValueTail, ResultList);
%% a < b
chk_values(Str1, _FieldRowNum, [#col{num = FieldNum, nick = FieldNick, value=?YES}|_FieldTail], 
           Str2, ValueRowNum, [#col{num = ValueNum}|_ValueTail], _ResultList) 
  when FieldNum < ValueNum ->
    throw(io_lib:format("!err:~s length =/= ~s length:for \"~s\" column ~s~p is not exist?~n check result:not pass.", 
                        [Str1, Str2, Str2, FieldNick, ValueRowNum]));
chk_values(Str1, FieldRowNum, [#col{num = FieldNum, value=?NO}|FieldTail], 
           Str2, ValueRowNum, ValueAll = [#col{num = ValueNum}|_ValueTail], ResultList) 
  when FieldNum < ValueNum ->
    chk_values(Str1, FieldRowNum, FieldTail, Str2, ValueRowNum, ValueAll, ResultList);
%% a > b
chk_values(Str1, FieldRowNum, [#col{num = FieldNum, value = ?NO}|FieldTail], 
           Str2, ValueRowNum, ValueAll = [#col{num = ValueNum}|_ValueTail], ResultList) 
  when ValueNum < FieldNum ->
    chk_values(Str1, FieldRowNum, FieldTail, Str2, ValueRowNum, ValueAll, ResultList);
chk_values(Str1, _FieldRowNum, [#col{num = FieldNum, value = VF}|_FieldTail], 
           Str2, ValueRowNum, [#col{num = ValueNum, nick = ValueNick, value = VV}|_ValueTail], _ResultList) 
  when ValueNum < FieldNum ->
    throw(io_lib:format("!err:~s length =/= ~s length:for why \"~s\" column ~s~p is exist? [~p,~p~n~p~n~p~n]hack it. -,- ~n check result:not pass.", 
                        [Str1, Str2, Str1, ValueNick, ValueRowNum, FieldNum, ValueNum, VF, VV]));
%% a < b, b =:= []
chk_values(Str1, _FieldRowNum, [#col{nick = FieldNick, value=?YES}|_FieldTail], 
           Str2, ValueRowNum, [], _ResultList) 
  ->
    throw(io_lib:format("!err:~s length =/= ~s length:for \"~s\" column ~s~p is not exist?~n check result:not pass.", 
                        [Str1, Str2, Str2, FieldNick, ValueRowNum]));
chk_values(Str1, FieldRowNum, [#col{value=?NO}|FieldTail], 
           Str2, ValueRowNum, [], ResultList) 
  ->
    chk_values(Str1, FieldRowNum, FieldTail, Str2, ValueRowNum, [], ResultList);
%% a > b, a =:= []
%% chk_values(Str1, FieldRowNum, [], 
%%            Str2, ValueRowNum, [#col{nick = _ValueNick}|_ValueTail], ResultList) % XXX 你妹这是为了懒人做的，这个是应该处理. 
%%   ->
%%     chk_values(Str1, FieldRowNum, [], Str2, ValueRowNum, [], ResultList);
chk_values(Str1, _FieldRowNum, [],  
           Str2, ValueRowNum, [#col{nick = ValueNick}|_ValueTail], _ResultList)   
  ->
    throw(io_lib:format("!err:~s length =/= ~s length:for why \"~s\" column ~s~p is exist? hack it. -,- ~n check result:not pass.", 
                        [Str1, Str2, Str1, ValueNick, ValueRowNum]));
%% a =:= b =:= []
chk_values(_Str1, _FieldRowNum, [], 
           _Str2, _ValueRowNum, [], ResultList) 
  ->
    {ok, lists:reverse(ResultList)}.

%% 检查特殊字符
%% chk_special_char([]) ->
%%     true;
%% chk_special_char([Value|_Tail]) when Value =:= $~ ->
%%     throw(io_lib:format("special character \'~s\' is found at XXX ~n check result:not pass.~n", [$~]));
%% chk_special_char([_Value|Tail]) ->
%%     chk_special_char(Tail);
%% chk_special_char(Value) when Value =:= $~ ->
%%     throw(io_lib:format("special character \'~s\' is found at XXX ~n check result:not pass.~n", [$~]));
chk_special_char(_Value) ->
    true.

%% 读取列表中的某个值
get_value(Key, List, IsOnly) ->
    case lists:keysearch(Key, #cmd.cmd, List) of
        {value, Cmd = #cmd{rows = [#row{cols = [#col{value=Row}]}]}} ->
            NewList = lists:delete(Cmd#cmd.cmd, List),
            chk_special_char(Row),
            {Row, NewList};
        {value, Cmd = #cmd{rows = [#row{cols = Cols}]}} when IsOnly =:= 1 ->
            NewList = lists:delete(Cmd#cmd.cmd, List),
            F = fun(#col{value = []}, X) ->
                        X;
                   (#col{value = Row}, _X) ->
                        chk_special_char(Row),
                        Row
                end,
            Row = lists:foldl(F, 0, Cols),
            {Row, NewList};
        {value, Cmd = #cmd{rows = Rows}} ->
            NewList = lists:delete(Cmd#cmd.cmd, List),
            NewRows = lists:reverse(Rows),
            F = fun(Row) ->
                        #row{cols = Cols} = Row,
                        F2 = fun(Col) ->
                                     #col{value=Value} = Col,
                                     chk_special_char(Value)
                             end,
                        lists:foreach(F2, Cols)
                end,
            lists:foreach(F, NewRows),   
            {NewRows, NewList};
        _X ->
            []
    end.

open_file(FileName) ->
    file:open(FileName, [append, raw]).

write_file(Fd, Format, Data) ->
    file:write(Fd, io_lib:format(Format, Data)).

%% 判定是否包含中文
check_unicode([]) ->
    false;
check_unicode([[Value|_]|_Tail]) when Value > 255 ->
    true;
check_unicode([[_Value|Tail]|Tail2]) ->
    check_unicode([Tail|Tail2]);
check_unicode([_Value|Tail]) ->
    check_unicode(Tail);
check_unicode(_) ->
    false.

%% 处理任务写操作，因为写的时候有可能是中文或者英文
write_any(Fd, Be4, Line, After) ->
    IsUnicode = check_unicode(Line),
    IsUnicode2 = check_unicode([Line]),
    ValueLen = erlang:length(Line),
    TailLen = erlang:length(?LIST_TAIL),
%%     ?PRINT_LINE(">>>>>~p|~p|~p", [ValueLen, Line, IsUnicode]),
    if
        IsUnicode =:= true orelse IsUnicode2 =:= true ->
            write_file(Fd, lists:concat([Be4, "<<\"", binary_to_list(unicode:characters_to_binary(Line)), "\">>", After]), []);
        ValueLen =< TailLen ->
            write_file(Fd, lists:concat([Be4, Line, After]), []);
        true ->
            case lists:nthtail(ValueLen-TailLen, Line) of
                ?LIST_TAIL ->
                    DeletedTailRowValue = lists:sublist(Line, erlang:length(Line)-erlang:length(?LIST_TAIL)),
                    write_file(Fd, lists:concat([Be4, DeletedTailRowValue, After]), []);
                ?LIST_TAIL_2 ->
                    DeletedTailRowValue = lists:sublist(Line, erlang:length(Line)-erlang:length(?LIST_TAIL_3)),
                    write_file(Fd, lists:concat([Be4, DeletedTailRowValue, After]), []);
                _ ->
                    write_file(Fd, lists:concat([Be4, Line, After]), [])
            end
    end.

close_file(Fd) ->
    file:close(Fd).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   写入模块头
%% @param  YrlName 记录名
%% @return ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_module_head(Fd) ->
    write_file(Fd, "~n", []), % 一楼给度娘
    write_file(Fd, "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~n", []),
    write_file(Fd, "%% 自动生成 ~n", []),
%%     {{Y, M, D}, {H, Mi, S}} = calendar:now_to_local_time(erlang:now()),
%%     write_file(Fd, "%% Data : ~w.~w.~w ~w:~w:~w ~n", [Y, M, D, H, Mi, S]),
    write_file(Fd, "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~n", []),
    ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   写入处理器
%%         erl文件在此处组织
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_line(Fd, {_ModName, YrlName, RecordRow}, 
                        {FieldRow, NoteRow, ValueList}, 
                        RemList, 
                        List2, FileRootName) ->
    % 写记录头
    write_record(Fd, {YrlName, RecordRow}, 
                              {FieldRow, NoteRow}, 
                              RemList, 
                              List2, FileRootName),
%%     ?PRINT_LINE("[~s][start]define record ...", [FileRootName]),
    write_note(Fd, NoteRow, RecordRow),
    write_note(Fd, FieldRow, RecordRow),
%%     ?PRINT_LINE("[~s][end]define record ...", [FileRootName]),
    % 写记录数据
%%     ?PRINT_LINE("[~s][start]write record data ...", [FileRootName]),
    send2parent({ok, self(), {FileRootName, {init, erlang:length(ValueList)}}}),
    F = fun(ValueRow) ->
                write_data(Fd, ValueRow, RecordRow),
                send2parent({ok, self(), {FileRootName, {progress, 1}}})
        end,
    lists:foreach(F, ValueList),
%%     ?PRINT_LINE("[~s][end]write record data ...", [FileRootName]),
    ok.

send2parent(Msg) ->
    case get(parent) of
        undefined ->
            ok;
        {PidParent, _FileRootName} ->
            PidParent ! Msg
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   写入整个记录
%%         包括注释和记录的定义
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_record(Fd, {YrlName, RecordName}, 
                 {FieldRow, NoteRow}, 
                          RemList, 
                          _List2, _FileRootName) ->
%%     ?PRINT_LINE("[~s][start]write rem ...", [FileRootName]),
    % 写注释
    write_file(Fd, "%%------------------------注释-----------------------------------------~n", []),
    write_rem(Fd, RemList),
    write_file(Fd, "%%---------------------------------------------------------------------~n", []),
%%     ?PRINT_LINE("[~s][end]write rem ...", [FileRootName]),
    
    % 写record.hrl
    {ok, FdHrl} = open_file(YrlName ++ ".hrl"),
    write_any(FdHrl, "-record(rec_"++RecordName, [], ", {~n"),
    % 写记录定义
    write_record(FdHrl, FieldRow, NoteRow),
    write_any(FdHrl, "}).~n~n", [], ""),
    close_file(FdHrl),
    ok.

write_rem(Fd, [#row{num = Num, cols = [#col{value=Rem}]}|Tail]) ->
    Be4 = io_lib:format("%%\t第~p行:\t", [Num]),
    write_file(Fd, lists:concat([Be4, binary_to_list(unicode:characters_to_binary(Rem)), "~n"]), []),
    write_rem(Fd, Tail);
write_rem(Fd, [#row{num = Num, cols = [#col{value=Rem}|Tail]} = Row]) ->
    Be4 = io_lib:format("%%\t第~p行:\t", [Num]),
    write_file(Fd, lists:concat([Be4, binary_to_list(unicode:characters_to_binary(Rem)), "~n"]), []),
    write_rem(Fd, [Row#row{cols = Tail}]);
write_rem(Fd, [#row{num = Num, cols = []}|Tail]) ->
    Be4 = io_lib:format("%%\t第~p行:\t", [Num]),
    write_file(Fd, lists:concat([Be4, "", "~n"]), []),
    write_rem(Fd, Tail);
write_rem(_Fd, []) ->
    ok;
write_rem(Fd, Rem) ->
    write_file(Fd, lists:concat(["%%\t", binary_to_list(unicode:characters_to_binary(Rem)), "~n"]), []).

%% 写record
write_record(Fd, [#col{value=Field}], [#col{value=Note}]) ->
    write_any(Fd, "\t"++Field, [], " "),
    try
        write_any(Fd, "\t%", [Note], " ~n")
    catch
        _:_ -> ok
    end;
write_record(Fd, [#col{value=Field}|FieldTail], [#col{value=Note}|NoteTail]) ->
    write_any(Fd, "\t"++Field, [], ", "),
    try
        write_any(Fd, "\t%", [Note], ", ~n")
    catch
        _:_ -> ok
    end,
    write_record(Fd, FieldTail, NoteTail);
write_record(_Fd, [], []) ->
    ok.

write_note(Fd, NoteList, RecordName) ->
    write_any(Fd, "%%{rec_", [RecordName], ", "),
    write_note_1(Fd, NoteList),
    write_any(Fd, "}.~n", [], ""),
    ok.
    
write_note_1(Fd, [#col{value = Note}]) ->
    try
        write_any(Fd, "", [Note], "")
    catch
        _:_ -> ok
    end;
write_note_1(Fd, [#col{value = Note}|NoteTail]) ->
    try
        write_any(Fd, "", [Note], ", ")
    catch
        _:_ -> ok
    end,
    write_note_1(Fd, NoteTail);
write_note_1(_Fd, []) ->
    ok.
    
write_data(Fd, ValueList, RecordName) ->
    write_any(Fd, "{rec_", RecordName, ", "),
    write_data_1(Fd, ValueList),
    write_any(Fd, "}.~n", [], ""),
    ok.
    
%% write_data_1(Fd, [#col{value = Value, type = 1}]) ->
%%     write_any(Fd, "<<\"", [Value], "\">>");
write_data_1(Fd, [#col{value = Value}]) ->
    write_any(Fd, "", Value, "");
%% write_data_1(Fd, [#col{value = Value, type = 1}|ValueTail]) ->
%%     write_any(Fd, "<<\"", [Value], "\">>, "),
%%     write_data_1(Fd, ValueTail);
write_data_1(Fd, [#col{value = Value}|ValueTail]) ->
    write_any(Fd, "", Value, ", "),
    write_data_1(Fd, ValueTail);
write_data_1(_Fd, []) ->
    ok.
    