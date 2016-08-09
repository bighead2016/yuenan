-module(xlsx2erl).
%% -export([start/3]).
%% -include_lib("xmerl/include/xmerl.hrl").
%% -define(REM, "NULL"). % 注释
%% -define(FIELDS, "FIELDS"). % 字段
%% -define(NOTE, "NOTE"). % 字段注释
%% -define(ERL, "ERL"). % 有效?
%% -define(KEY, "KEY"). % 索引?
%% -define(VALUE, "VALUE"). % 值
%% -define(YES, "yes"). 
%% -define(NO, "no").
%% 
%% -define(FNAME(RecordName),  %% 在这定义生成的文件的安放路径
%% 		lists:concat(["../../src/data/rec_", RecordName, ".erl"])).
%% -define(PRINT_LINE(Format, Args),  %% console输出
%% 		io:format("[~w|~w]:" ++ Format ++ "~n", [?MODULE, ?LINE] ++ Args)).
%% -define(WRITE(FileName, Format, Args), %% 文件输出，如果没有该文件，将不会生成
%% 	file:write_file(?FNAME(FileName), io_lib:format(Format, Args), [append])).
%% -define(WRITE_INIT(FileName), %% 文件输出，并生成文件
%% 	file:write_file(?FNAME(FileName), io_lib:format("", []))).
%% 
%% %%---------------------------------records----------------------------------------------
%% %% xlsx 属性结构
%% -record(xlsx_att, { 
%% 				   row=0, % 行号 
%% 				   col="", % 列号
%% 				   type=0, % 1,2
%% 				   content="" % 内容
%% 				   }).
%% %% xlsx共享串分析结构
%% -record(xlsx_share_string, {id, str}).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc    入口
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 参数由shell中读取
%% %% xlsxfilename = xlsx源文件名
%% %% maxline = 最大扫描行数
%% start(PidParent, FileRootName, MaxLine) ->
%% 	try
%% 		RecordName = get_name(FileRootName),
%% 		List = get_worksheet_data(FileRootName),
%% 		_ShareList = get_shared_string(FileRootName),
%% 		List2 = get_real_data(List),
%% 		erase(),
%% 		write_erl_file(List2, RecordName, MaxLine),
%%         erase(),
%%         PidParent ! {ok, self()}
%% 	catch
%% 		  Type: Why->
%%             ?PRINT_LINE( "mod:~p, line: ~p, error type:~p, why: ~p, Strace:~p~n ", 
%% 						 [ ?MODULE, ?LINE, Type, Why, erlang:get_stacktrace()])
%%      end.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc    获取记录名
%% %%          规则是取xlsx文件的第一个worksheet的名字
%% %%          sheet的name是目标值，但是那个xml的结构有点麻烦，
%% %%          所以要转n个弯才到
%% %%          #xmlElement{#xmlAttribute{name}...}
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_name(FileRootName) ->
%% %% 	c:cd("xl"),
%% 	SharedStringsXml = xmerl_scan:file(FileRootName++"/xl/workbook.xml", [{encoding, 'utf-8'}]),
%% 	{Doc, _} = SharedStringsXml,
%% 	XmlElementList = xmerl_xpath:string("sheets/sheet", Doc),
%% 	XmlAttrList = get_name_2(XmlElementList, []),
%% 	NameList = get_name_3(XmlAttrList, []),
%% 	[_, _, Name] = hd(NameList),
%% %% 	c:cd(".."),
%% 	Name.
%% 
%% get_name_2([], ResultList) ->
%% 	ResultList;
%% get_name_2([#xmlElement{attributes=Value}|Tail], ResultList) ->
%% 	NewResultList = [Value|ResultList],
%% 	get_name_2(Tail, NewResultList).
%% 
%% get_name_3([], ResultList) ->
%% 	ResultList;
%% get_name_3([XmlAttrList|Tail], ResultList) ->
%% 	Name = get_name_4(XmlAttrList, []),
%% 	NewResultList = [Name|ResultList],
%% 	get_name_3(Tail, NewResultList).
%% 
%% get_name_4([], ResultList) ->
%% 	ResultList;
%% get_name_4([#xmlAttribute{name="name", value=Value}|Tail], ResultList) ->
%% 	NewResultList = [Value|ResultList],
%% 	get_name_4(Tail, NewResultList);
%% get_name_4([#xmlAttribute{value=Value}|Tail], ResultList) ->
%% 	NewResultList = [Value|ResultList],
%% 	get_name_4(Tail, NewResultList).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   获取worksheet的数据
%% %% @return [#xlsx_att{}, #xlsx_att{}, ...]
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_worksheet_data(FileRootName) ->
%% %% 	c:cd("xl/worksheets"),
%% 	SharedStringsXml = xmerl_scan:file(FileRootName++"/xl/worksheets/sheet1.xml", [{encoding, 'utf-8'}]),
%% 	{Doc, _} = SharedStringsXml,
%% 	RealText = xmerl_xpath:string("/worksheet/sheetData/row/c", Doc),
%% 	RealValue = xmerl_xpath:string("/worksheet/sheetData/row/c/v/text()", Doc),
%% 	get_text(RealText, RealValue, []).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   获取xml内容
%% %%         1.row只会是数字，col只会是字母
%% %%         2.col最多2个，row无限长
%% %%         所以只要判定第二个是否字母就行
%% %%         另外有type的是字串，无type的是数字
%% %% 格式：#xlsx_att:Attr=location, AttrT=type, V=value
%% %%
%% %% @return List = [#xlsx_att{}, #xlsx_att{}, ...]
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_text([], [], ResultList) ->
%% %% 	?PRINT_LINE("ResultList=~s", [ResultList]),
%% 	ResultList;
%% get_text([#xmlElement{attributes=[#xmlAttribute{value=Location}]}|Tail], 
%% 		 [#xmlText{value=Value}|VTail], 
%% 		 ResultList) -> % 数字
%% 	[Col1, Col2|Row] = Location,
%% %% 	?PRINT_LINE("Col1=~s, Col2=~s, Row=~w", [Col1, Col2, Row]),
%% 	if
%% 		Row =:= [] -> % Location = ["A", 1] 像这种只有两个元素的
%% 			NewResultList = [#xlsx_att{col=[Col1], row=list_to_integer([Col2]), type=digit, content=Value}|ResultList];
%% 		Col2 >= $0 andalso Col2 =< $9 -> % 有至少三个元素，第2个起是数字row
%% 			NewResultList = [#xlsx_att{col=[Col1], row=list_to_integer([Col2] ++ Row), type=digit, content=Value}|ResultList];
%% 		true -> % 有至少三个元素，第3个起是数字row；row一定要抚平，因为从前面得到的Row是个list，不持平有可能会在几层之内，转不了数字的
%% 			NewResultList = [#xlsx_att{col=[Col1, Col2], row=list_to_integer(lists:flatten(Row)), type=digit, content=Value}|ResultList]
%% 	end,
%% 	get_text(Tail, VTail, NewResultList);
%% get_text([#xmlElement{attributes=[#xmlAttribute{value=Location}, #xmlAttribute{value=_Type}]}|Tail], 
%% 		 [#xmlText{value=Value}|VTail], 
%% 		 ResultList) -> % 字串
%% 	[Col1, Col2|Row] = Location,
%% %% 	?PRINT_LINE("Col1=~s, Col2=~s, Row=~w", [Col1, Col2, Row]),
%% 	if
%% 		Row =:= [] -> % Location = ["A", 1] 像这种只有两个元素的
%% 			NewResultList = [#xlsx_att{col=[Col1], row=list_to_integer([Col2]), type=text, content=Value}|ResultList];
%% 		Col2 >= $0 andalso Col2 =< $9 -> % 有至少三个元素，第2个起是数字row
%% 			NewResultList = [#xlsx_att{col=[Col1], row=list_to_integer([Col2] ++ Row), type=text, content=Value}|ResultList];
%% 		true -> % 有至少三个元素，第3个起是数字row；row一定要抚平，因为从前面得到的Row是个list，不持平有可能会在几层之内，转不了数字的
%% 			NewResultList = [#xlsx_att{col=[Col1, Col2], row=list_to_integer(lists:flatten(Row)), type=text, content=Value}|ResultList]
%% 	end,
%% 	get_text(Tail, VTail, NewResultList);
%% get_text([_='_'|Tail], [_='_'|VTail], ResultList) -> % 这个是多余的，怕出问题才加上的
%% %% 	?PRINT_LINE("1", []),
%% 	get_text(Tail, VTail, ResultList).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   获取共享字串
%% %% @return List = [#xlsx_share_string{}, #xlsx_share_string{}, ...]
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_shared_string(FileRootName) ->
%% 	SharedStringsXml = xmerl_scan:file(FileRootName++"/xl/sharedStrings.xml", [{encoding, 'utf-8'}]),
%% 	{Doc, _} = SharedStringsXml,
%% 	RealText = xmerl_xpath:string("/sst/si/t/text()", Doc),
%% 	get_text(RealText, []).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   获取共享字串数据，同时放入进程字典
%% %%
%% %% @return List = [#xlsx_share_string{}, #xlsx_share_string{}, ...]
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_text([], ResultList) ->
%% 	ResultList;
%% get_text([{xmlText, [{_, _}, {si, Num}, {_,_}], _, _, Text, _}|Tail], ResultList) ->
%% 	NewResultList = [#xlsx_share_string{id=Num, str=Text}|ResultList],
%% 	put(Num, Text), % 放入进程字典，格式{id, str}
%% 	get_text(Tail, NewResultList).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   合并
%% %%         本来只要值是字串的，都会保存到一个共享文件中去
%% %%         经过前面的转化，已经压到进程字典中去了
%% %%         现在只要按字串的索引值取就可以了
%% %%         最后拼接成#xlsx_att结构
%% %% @return [#xlsx_att{}, #xlsx_att{}, ...]
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_real_data(TextList) ->
%% 	F = fun(X, OldX) ->
%% 			if 
%% 				X#xlsx_att.type =:= text -> % 字串
%% 					[X#xlsx_att{content=get(list_to_integer(X#xlsx_att.content)+1)}|OldX];
%% 				true -> % 数字
%% 					[X#xlsx_att{content=list_to_integer(X#xlsx_att.content)}|OldX]
%% 			end
%% 		end,
%% 	lists:foldl(F, [], TextList).
%% 
%% %%------------------------------xlsx解释部分结束，下面用于组织与编写erl文件-----------------------------------------
%% 	
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入模块文件
%% %% @param  RecordName 记录名
%% %% @return ok
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_erl_file(List, RecordName, MaxLine) ->
%% 	?WRITE_INIT(RecordName),
%% 	write_module_head(RecordName), % 模块头
%% 	RevNewList = lists:reverse(List), % 输入的列表是反过来的，所以要先处理一下
%% 	F3 = fun(XlsxAtt) -> % 把表格内容全部压到进程字典，由于之前已经清了一次，所以内存估计是够的
%% 			put({XlsxAtt#xlsx_att.col, XlsxAtt#xlsx_att.row}, XlsxAtt#xlsx_att.content) 
%% 		end,
%% 	lists:foreach(F3, RevNewList),
%% 	detect_cmd({"A", 1}, MaxLine),
%% 	write_line(RecordName, MaxLine),
%% 	ok.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入模块头
%% %% @param  RecordName 记录名
%% %% @return ok
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_module_head(RecordName) ->
%% 	?WRITE(RecordName, "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~n", []),
%% 	?WRITE(RecordName, "%% 自动生成 ~n", []),
%% 	{{Y, M, D}, {H, Mi, S}} = calendar:now_to_local_time(erlang:now()),
%% 	?WRITE(RecordName, "%% Data : ~w.~w.~w ~w:~w:~w ~n", [Y, M, D, H, Mi, S]),
%% 	?WRITE(RecordName, "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~n", []),
%% 	ok.
%%  
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   行命令解释器
%% %%         要另加命令的话，只要在CmdGet下面再加上要解释的命令行就可以了
%% %% @param  Line -> RowNum 默认从1开始
%% %% @return ok
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% detect_cmd(Line, MaxLine) ->
%% 	CmdGet = get(Line),
%% 	{Col, Row} = Line,
%% %% 	?PRINT_LINE("Col=~s, Row=~w", [Col, Row]),
%% 	case CmdGet of 
%% 		undefined ->
%% 			ok;
%% 		?REM -> % 注释
%% 			TitleList = get_field_row_data(Col, Row, []),
%% 			put({?REM, Row}, TitleList),
%% 			RemRowList = get(rem_row_list),
%% 			if
%% 				RemRowList =:= undefined ->
%% 					put(rem_row_list, [Row]);
%% 				true ->
%% 					put(rem_row_list, [Row|RemRowList])
%% 			end;
%% 		?FIELDS -> % 字段
%% 			TitleList = get_field_row_data(Col, Row, []),
%% 			put(?FIELDS, TitleList);
%% 		?NOTE -> % 字段注释
%% 			TitleList = get_field_row_data(Col, Row, []),
%% 			put(?NOTE, TitleList);
%% 		?ERL -> % 取否
%% 			TitleList = get_field_row_data(Col, Row, []),
%% 			put(?ERL, TitleList);
%% 		?KEY -> 
%% 			TitleList = get_field_row_data(Col, Row, []),
%% 			put(?KEY, TitleList);
%% 		?VALUE -> % 值
%% 			TitleList = get_field_row_data(Col, Row, []),
%% 			put({?VALUE, Row}, TitleList),
%% 			NowCount = get(value_count),
%% 			if
%% 				NowCount =:= undefined ->
%% 					put(value_count, 1);
%% 				true ->
%% 					put(value_count, NowCount + 1)
%% 			end,
%% 			ValueRowList = get(value_row_list),
%% 			if
%% 				ValueRowList =:= undefined ->
%% 					put(value_row_list, [Row]);
%% 				true ->
%% 					put(value_row_list, [Row|ValueRowList])
%% 			end;
%% 		Other -> % 其他，暂不处理
%% 			?PRINT_LINE("Col=~s, Row=~w:Other=~w", [Col, Row, Other])
%% 	end,
%% 	if
%% 		Row < MaxLine -> % 限制最大行数，这是怕文件太大了
%% 			detect_cmd({Col, Row + 1}, MaxLine);
%% 		true -> % 老问题，内容是压进去的，所以要反过来(参考"栈")
%% 			List = get(rem_row_list),
%% 			?PRINT_LINE("List=~w", [List]),
%% 			if
%% 				List =:= undefined ->
%% 					skip;
%% 				true ->
%% 					put(rem_row_list, lists:reverse(List))
%% 			end,
%% 			List1 = get(value_row_list),
%% 			?PRINT_LINE("List1=~w", [List1]),
%% 			if
%% 				List1 =:= undefined ->
%% 					skip;
%% 				true ->
%% 					put(value_row_list, lists:reverse(List1))
%% 			end,
%% 			ok
%% 	end.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   获取整行的数据
%% %%         读到col是undefine就算了
%% %% @param  Line -> RowNum 默认从1开始
%% %% @return ok
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_field_row_data(Col, Row, ResultList) ->
%% 	Recent = get({Col, Row}),
%% 	if
%% 		Recent =:= undefined -> 
%% 			ResultList;
%% 		true ->
%% 			NewResultList = [Recent|ResultList],
%% 			NextCol = get_next_tag(Col), % 因为col是由字母结成的，当大于"Z"的时候会有特殊处理
%% 			get_field_row_data(NextCol, Row, NewResultList)
%% 	end. 
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   获取下一个列标记值
%% %%         例如："A" -> "B", "Z" -> "AA"         
%% %% @bug    在"AA"等两个值的列标记匹配不上
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get_next_tag([]) ->
%% 	"A"; % 没有值，返回第一个
%% get_next_tag([T1]) ->
%% 	TT1 = T1 + 1,
%% 	if
%% 		TT1 > $Z -> % Z后是"AA"
%% 			"AA"; 
%% 		true -> %  单个字母非Z，直接+1就行了
%% 			[TT1]
%% 	end;
%% get_next_tag([T1, T2]) ->
%% 	TT2 = T2 + 1,
%% 	TT1 = T1 + 1,
%% 	if
%% 		TT2 > $Z andalso TT1 > $Z -> % 大于"ZZ"就不管了，只好返回"A"
%% 			"A";
%% 		TT2 > $Z andalso TT1 =< $Z -> % "AA" ~ "ZZ" 之间的，分别处理，第2个字母未到"Z"的，只要+1
%% 			[TT1, $A];
%% 		true -> % 第2个字母到"Z"后，要进一
%% 			[T1, TT2]
%% 	end.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入处理器
%% %%         erl文件在此处组织
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_line(RecordName, MaxLine) ->
%% 	{_, EList} = get_list(?ERL),
%% 	{FLen, FList} = get_list(?FIELDS),
%% 	{NLen, NList} = get_list(?NOTE),
%% 	{KLen, KList} = get_list(?KEY),
%% 	
%% 	if
%% 		FLen > 0 andalso NLen > 0 andalso KLen > 0 ->
%% 			ErlList = lists:reverse(lists:delete(?ERL, EList)),
%% 			FieldList = lists:reverse(lists:delete(?FIELDS, FList)),
%% 			NoteList = lists:reverse(lists:delete(?NOTE, NList)),
%% 			KeyList = lists:reverse(lists:delete(?KEY, KList)),
%% 			
%% 			% 写记录头
%% 			write_record(RecordName, FieldList, NoteList, ErlList, MaxLine),
%% 			% 写记录数据
%% 			?PRINT_LINE("[start]write record data ...", []),
%% 			Keys = get_keys_1("yes", KeyList, 1, []),
%% 			write_data(RecordName, FieldList, Keys, ErlList),
%% 			?PRINT_LINE("[end]write record data ...", []);
%% 		true ->
%% 			?PRINT_LINE("[error]write record data ...", []),
%% 			ok
%% 	end,
%% 	ok.
%% 
%% %% 获取最后一个值是有效的列表,为了避免尾元素处理冲突问题
%% get_list(Type) ->
%% 	List = get(Type),
%% 	if
%% 		List =:= undefined ->
%% 			{0, []};
%% 		true ->
%% 			{_NoList, YesList} = lists:splitwith(fun(X) -> X =:= ?NO end, List),
%% 			Len = erlang:length(YesList),
%% 			{Len, YesList}
%% 	end.
%% 
%% %% 索引列表
%% get_keys_1(_X, [], _Nth, ResultList) ->
%% 	lists:reverse(ResultList);
%% get_keys_1(X, RemindList, Nth, ResultList) ->
%% 	[Head|Tail] = RemindList,
%% 	if
%% 		Head =:= X -> % 有效索引
%% 			get_keys_1(X, Tail, Nth + 1, [Nth|ResultList]);
%% 		true -> % 无效索引
%% 			get_keys_1(X, Tail, Nth + 1, ResultList)
%% 	end.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入整个记录
%% %%         包括注释和记录的定义
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_record(RecordName, RecordFieldList, NoteList, ErlList, MaxLine) ->
%% 	?PRINT_LINE("[start]write rem ...", []),
%% 	?WRITE(RecordName, "%%------------------------注释-----------------------------------------~n", []),
%% 	?PRINT_LINE("write rem get(rem_row_list)=~w", [get(rem_row_list)]),
%% 	% 写注释
%% 	write_record_rem_handler(RecordName, get(rem_row_list), MaxLine),
%% 	?PRINT_LINE("[end]write rem ...", []),
%% 	?PRINT_LINE("[start]define record ...", []),
%% 	?WRITE(RecordName, "-record(~s, {~n", [RecordName]),
%% 	% 写记录定义
%% 	write_record_field_handler(RecordName, RecordFieldList, NoteList, ErlList),
%% 	?WRITE(RecordName, "}).~n~n", []),
%% 	?PRINT_LINE("[end]define record ...", []).
%% 	
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入注释部分
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_record_rem_handler(RecordName, [], _MaxLine) -> % 结束
%% 	?WRITE(RecordName, "%%---------------------------------------------------------------------~n~n", []);
%% write_record_rem_handler(RecordName, [Row|Tail], MaxLine) -> 
%% 	Rem = get({?REM, Row}),
%% 	if
%% 		undefined =:= Rem ->
%% 			skip;
%% 		true -> % 写注释
%% 			?WRITE(RecordName, "%% 第~w行： ~ts~n", [Row, binary_to_list(unicode:characters_to_binary(lists:reverse(lists:delete(?REM, Rem))))])
%% 	end,
%% 	if
%% 		Row =< MaxLine ->
%% 			write_record_rem_handler(RecordName, Tail, MaxLine);
%% 		true -> % 到最大行了，也不写。其实这里应该是不可能到达的，因为命令解释的时候就过滤掉了
%% 			?WRITE(RecordName, "%%---------------------------------------------------------------------~n~n", []),
%% 			ok
%% 	end.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入记录定义部分
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_record_field_handler(_RecordName, [], [], []) ->
%% 	ok;
%% write_record_field_handler(RecordName, [Field|[]], [Note|[]], [_Erl|[]]) -> % 尾行必定是有效的，因为前面做了预处理。这事蓄谋已久了啦~
%% 	?WRITE(RecordName, "\t~s % ~ts~n", [Field, binary_to_list(unicode:characters_to_binary(Note))]), % 中文处理
%% 	ok;
%% write_record_field_handler(RecordName, [Field|Tail], [Note|NTail], [Erl|ETail]) ->
%% 	if 
%% 		Erl =:= ?YES ->
%% 			?WRITE(RecordName, "\t~s, % ~ts~n", [Field, binary_to_list(unicode:characters_to_binary(Note))]); % 有效行过滤
%% 		true ->
%% 			skip
%% 	end,
%% 	write_record_field_handler(RecordName, Tail, NTail, ETail).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入数据部分
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_data(RecordName, FieldList, Keys, ErlList) ->
%% 	write_data_1(RecordName, FieldList, Keys, get(value_row_list), ErlList),
%% 	?WRITE(RecordName, "get(_) ->~nnil.~n", []).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入数据的过滤器
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_data_1(_RecordName, _FieldList, _Keys, [], _ErlList) ->
%% 	ok;
%% write_data_1(RecordName, FieldList, Keys, [Num|Tail], ErlList) ->
%% 	case get({?VALUE, Num}) of
%% 		undefined ->
%% 			ok;
%% 		RowValueList ->
%% 			RLen = erlang:length(RowValueList),
%% 			ELen = erlang:length(ErlList),
%% 			RowValueList2 = lists:nthtail(RLen - ELen - 1, RowValueList), % 1=?ERL占的长度。这里目的还是处理有效尾行的问题
%% 			RowValueList3 = lists:reverse(lists:delete(?VALUE, RowValueList2)),
%% 			Key =
%% 				if
%% 					erlang:length(Keys) =< 1 ->
%% 						[NewKeys] = Keys,
%% 						NewKeys;
%% 					true ->
%% 						Keys
%% 				end,
%% 			write_data_head(RecordName, Key, RowValueList3), % 写数据头
%% 			write_data_body(RecordName, FieldList, RowValueList3, ErlList), % 写数据体
%% 			?WRITE(RecordName, "};~n", []), % 数据结构尾
%% 			show_msg(RecordName, Tail), % 进度显示
%% 			write_data_1(RecordName, FieldList, Key, Tail, ErlList)
%% 	end.
%% 
%% %% 进度条显示
%% show_msg(RecordName, Tail) ->
%% 	?PRINT_LINE("\t...record:[rec_~p] is ~p/~p now...\n", [RecordName, erlang:length(Tail), get(value_count)]).
%% 
%% %% 写数据头 - FIXME 进来的是单一key还是多个key的列表，现在没有判定
%% write_data_head(RecordName, Key, RowValueList) when is_integer(Key) ->
%% 	KeyV = lists:nth(Key, RowValueList),
%% 	?WRITE(RecordName, "get(~w) ->~n\t#~s{~n", [KeyV, RecordName]);
%% write_data_head(RecordName, Keys, RowValueList) when is_list(Keys) -> % 暂时先认为列表不能当key吧
%% 	?WRITE(RecordName, "get({", []),
%% 	write_keys(RecordName, Keys, RowValueList),
%% 	?WRITE(RecordName, "}) ->~n\t#~s{~n", [RecordName]);
%% write_data_head(RecordName, Keys, RowValueList) when is_tuple(Keys) -> % XXX 其实，这废了
%% 	?WRITE(RecordName, "get({", []),
%% 	write_keys(RecordName, Keys, RowValueList),
%% 	?WRITE(RecordName, "}) ->~n\t#~s{~n", [RecordName]);
%% write_data_head(RecordName, Key, RowValueList) ->
%% 	KeyV = lists:nth(Key, RowValueList),
%% 	?WRITE(RecordName, "get(~s) ->~n\t#~s{~n", [KeyV, RecordName]).
%% 
%% %% 写索引元组
%% write_keys(_RecordName, [], _RowValueList) ->
%% 	ok;
%% write_keys(RecordName, [Key|[]], RowValueList) when is_integer(Key) ->
%% 	KeyV = lists:nth(Key, RowValueList),
%% 	case is_integer(KeyV) of
%% 		true ->
%% 			?WRITE(RecordName, "~w", [KeyV]);
%% 		false ->
%% 			?WRITE(RecordName, "~s", [KeyV])
%% 	end;
%% write_keys(RecordName, [Key|Tail], RowValueList) when is_integer(Key) ->
%% 	KeyV = lists:nth(Key, RowValueList),
%% 	case is_integer(KeyV) of
%% 		true ->
%% 			?WRITE(RecordName, "~w, ", [KeyV]);
%% 		false ->
%% 			?WRITE(RecordName, "~s, ", [KeyV])
%% 	end,
%% 	write_keys(RecordName, Tail, RowValueList).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   写入数据的处理器
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write_data_body(_RecordName, [], [], []) ->
%% 	ok;
%% write_data_body(RecordName, [Field|[]], [RowValue|[]], [_Erl|[]]) when is_integer(RowValue) ->
%% 	?WRITE(RecordName, "\t\t~s = ~w~n", [Field, RowValue]);											   
%% write_data_body(RecordName, [Field|[]], [RowValue|[]], [_Erl|[]]) when is_list(RowValue) ->
%% 	H = hd(RowValue),
%% 	if
%% 		H > $[ ->
%% 			?WRITE(RecordName, "\t\t~s = \"~ts\",~n", [Field, binary_to_list(unicode:characters_to_binary(RowValue))]);
%% 		true ->
%% 			?WRITE(RecordName, "\t\t~s = ~s,~n", [Field, RowValue])
%% 	end;
%% write_data_body(RecordName, [Field|[]], [RowValue|[]], [_Erl|[]]) when is_tuple(RowValue) ->
%% 	?WRITE(RecordName, "\t\t~s = ~s~n", [Field, RowValue]);
%% write_data_body(RecordName, [Field|[]], [RowValue|[]], [_Erl|[]]) ->
%% 	?WRITE(RecordName, "\t\t~s = \"~ts\"~n", [Field, binary_to_list(unicode:characters_to_binary(RowValue))]);											   
%% write_data_body(RecordName, [Field|FTail], [RowValue|RTail], [Erl|ETail]) when is_integer(RowValue) ->
%% 	if
%% 		Erl =:= ?YES ->
%% 			?WRITE(RecordName, "\t\t~s = ~w,~n", [Field, RowValue]);
%% 		true ->
%% 			skip
%% 	end,
%% 	write_data_body(RecordName, FTail, RTail, ETail);
%% write_data_body(RecordName, [Field|FTail], [RowValue|RTail], [Erl|ETail]) when is_list(RowValue) ->
%% 	H = hd(RowValue),
%% 	if
%% 		Erl =:= ?YES ->
%% 			if
%% 				H > $[ ->
%% 					?WRITE(RecordName, "\t\t~s = \"~ts\",~n", [Field, binary_to_list(unicode:characters_to_binary(RowValue))]);
%% 				true ->
%% 					?WRITE(RecordName, "\t\t~s = ~s,~n", [Field, RowValue])
%% 			end;
%% 		true ->
%% 			skip
%% 	end,
%% 	write_data_body(RecordName, FTail, RTail, ETail);
%% write_data_body(RecordName, [Field|FTail], [RowValue|RTail], [Erl|ETail]) when is_tuple(RowValue) ->
%% 	if
%% 		Erl =:= ?YES ->
%% 			?WRITE(RecordName, "\t\t~s = ~s,~n", [Field, RowValue]);
%% 		true ->
%% 			skip
%% 	end,
%% 	write_data_body(RecordName, FTail, RTail, ETail);
%% write_data_body(RecordName, [Field|FTail], [RowValue|RTail], [Erl|ETail]) ->
%% 	if
%% 		Erl =:= ?YES ->
%% 			?WRITE(RecordName, "\t\t~s = \"~ts\",~n", [Field, binary_to_list(unicode:characters_to_binary(RowValue))]);
%% 		true ->
%% 			skip
%% 	end,
%% 	write_data_body(RecordName, FTail, RTail, ETail).