%%
%% 请注意以下两点：
%%   1.所有数据的检测以fields的字段为准，
%%     也就是说，如果出现fields和values长度不一样，或者出现错位，
%%     则以fields为判定基础
%%   2.value不允许有空，所以，在生成检测的时候，会提示。
%%     如果检测不能通过，则会打印出第几行，第几列出现在什么问题。
%% p.s. enjoy the game && have fun.
%%
-module(xlsx_tools).
-export([start/1]).
-include_lib("xmerl/include/xmerl.hrl").
-define(MOD,            "MOD").     % 模块归属
-define(YRL_NAME,       "YRL_NAME").    % 模块归属
-define(RECORD_NAME,    "RECORD_NAME").     % 模块归属
-define(REM,            "NULL").    % 注释
-define(FIELDS,         "FIELDS").  % 字段
-define(NOTE,           "NOTE").    % 字段注释
-define(ERL,            "ERL").     % 有效?
-define(KEY,            "KEY").     % 索引?
-define(VALUE,          "VALUE").   % 值
-define(YES,            "yes"). 
-define(NO,             "no").

-define(LIST_TAIL, "\_x000D\_").
-define(LIST_TAIL_2, "x000D\_\n").
-define(LIST_TAIL_3, "\_x000D\_\n").

%% 在这定义生成的文件的安放路径
-define(FNAME(Path, YrlName),   lists:concat(["../yrl/", Path, "/", YrlName, ".yrl"])).
%% 在这定义生成的文件的安放路径
-define(FNAME_2(YrlName),       lists:concat([YrlName, ".hrl"])).
%% %% 在这定义生成的文件的安放路径
%% -define(FNAME_3(YrlName),       lists:concat(["../include/", YrlName, ".hrl"])).
%% console输出
-define(PRINT_LINE(Format, Args), io:format("[~w|~w]:" ++ Format ++ "~n", [?MODULE, ?LINE] ++ Args)). % ok). %
-define(WRITE(Path, FileName, Format, Args), 
    file:write_file(?FNAME(Path, FileName), io_lib:format(Format, Args), [append,raw])).
%% -define(WRITE_HRL(FileName, Format, Args), 
%%     file:write_file(?FNAME_2(FileName), io_lib:format(Format, Args), [append, raw])).
%% 文件输出，并生成文件
-define(WRITE_INIT(Path, FileName), file:write_file(?FNAME(Path, FileName), io_lib:format("", []))).

%%---------------------------------records----------------------------------------------
%% xlsx 属性结构
-record(cmd, {
              cmd = "",
              rows = [] % row list
              }).

-record(row, {
              num = 0,
              cols = [] % col list
              }).

-record(col, {
              num   = 0,
              nick  = "",
              value = "",
              type  = 0
              }).

%% xlsx共享串分析结构
-record(xlsx_share_string, {id, str}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc    入口
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 参数由shell中读取
%% xlsxfilename = xlsx源文件名
%% maxline = 最大扫描行数
start(FileRootName) ->
    try
        get_shared_string(FileRootName),
        List        = get_worksheet_data(FileRootName),
        erase(),
        write_erl_file(List)
    catch
          Type: Why->
            ?PRINT_LINE( "[~s]error type:~p, why: ~p, Strace:~p~n ", 
                         [FileRootName, Type, Why, erlang:get_stacktrace()])
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
    {XmlDoc, _Result} = xmerl_scan:file(FileRootName++"/xl/worksheets/sheet1.xml", [{encoding, 'utf-8'}]),
    RowList           = xmerl_xpath:string("/worksheet/sheetData/row", XmlDoc),
    List = read_row(RowList, []),
    List.

read_row([Row|Tail], RowCmd) ->
    % 第几行
    AttrList = yrl_tools:read_attrs(Row),
    Pos      = yrl_tools:read_attr(AttrList, 'r'),
    % 当前行各列的值
    ContentList = yrl_tools:read_content(Row), % [#xmlElement{}]
    ColList     = yrl_tools:read_element(ContentList, 'c', []),
    NewRow      = read_col(ColList, #row{num=Pos}),
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
read_col([Col|Tail], Row = #row{cols=OldColList}) ->
    try
        Content  = yrl_tools:read_content(Col), % [#xmlElement{}],v
        VList    = yrl_tools:read_content(Content),
        TextList = yrl_tools:read_text(VList, []),
        
        AttrList = yrl_tools:read_attrs(Col),
        Type     = yrl_tools:read_attr_t(AttrList),
        Text     = yrl_tools:get_real_value(TextList, Type, []),
        
        {Pos, Nick} = yrl_tools:get_col_pos(AttrList, {0, ""}),
        Col2        = record_col(Pos, Nick, Text, Type),
        ColList     = [Col2|OldColList],
        Row2        = set_row_col(Row, ColList),
        read_col(Tail, Row2)
    catch
        _:_ ->
            ?PRINT_LINE("stack=~s", [erlang:get_stacktrace()]),
            read_col(Tail, Row) % 有可能没值，那就直接无视
    end;
read_col([], Row) ->
    ColList  = Row#row.cols,
    ColList2 = lists:reverse(ColList),
    Row2     = set_row_col(Row, ColList2),
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
write_erl_file([#cmd{cmd = ?VALUE, rows = Rows}|_Tail]) ->
    try
        get_yes_list(Rows, [])
    catch
        throw:Msg ->
            ?PRINT_LINE(Msg, []),
            error;
        Type:Why ->
            ?PRINT_LINE("that's an error. but I don't know why, ouch. ~nHowever it was -> ~p:~p=~p~n -------~n that's all i know.", 
                        [Type, Why, erlang:get_stacktrace()]),
            error
    end;
write_erl_file([_|Tail]) ->
    write_erl_file(Tail);
write_erl_file([]) ->
    ok.

get_yes_list([#row{cols = Cols}|Tail], OldList) ->
    List = get_yes_row(Cols, OldList),
    get_yes_list(Tail, List);
get_yes_list([], List) ->
    List.

get_yes_row([#col{num = 2, value = Value}, #col{num = 3, value = "yes"}], OldList) ->
    Value2 = rm_space(Value, ""),
    [Value2|OldList];
get_yes_row(_, OldList) -> OldList.
    
rm_space([16#20|Tail], OldList) ->
    rm_space(Tail, OldList);
rm_space([Value|Tail], OldList) ->
    rm_space(Tail, [Value|OldList]);
rm_space([], OldList) -> 
    lists:reverse(OldList).
    
