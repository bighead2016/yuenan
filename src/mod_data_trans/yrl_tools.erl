%%% @author np
%%% @doc @todo Add description to yrl_tools.


-module(yrl_tools).

-include_lib("xmerl/include/xmerl.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([read_element/3, read_content/1, read_attrs/1, read_attr_t/1, get_real_value/3,
         get_col_pos/2, read_attr/2, read_text/2, get_col_pos_x/2]).

read_element([XmlElement = #xmlElement{name = Type}|Tail], Type, List) ->
    List2 = [XmlElement|List],
    read_element(Tail, Type, List2);
read_element([_|Tail], Type, List) ->
    read_element(Tail, Type, List);
read_element([], _, List) ->
    List.

read_attrs(XmlElement) ->
    XmlElement#xmlElement.attributes.

read_attr_t([#xmlAttribute{name = 't', value = Value}|_Tail]) ->
    Value;
read_attr_t([_|Tail]) ->
    read_attr_t(Tail);
read_attr_t([]) ->
    0.

read_attr([#xmlAttribute{name = Type, value = Value}|_Tail], Type) ->
    Value;
read_attr([_|Tail], Type) ->
    read_attr(Tail, Type);
read_attr([], _Type) ->
    0.

read_content([XmlElement]) ->
    XmlElement#xmlElement.content;
read_content(XmlElement) when is_record(XmlElement, xmlElement) ->
    XmlElement#xmlElement.content;
read_content(_) -> 
    [].

read_text([#xmlText{value = Text}|Tail], List) ->
    List2 = [Text|List],
    read_text(Tail, List2);
read_text([], List) ->
    List;
read_text([_|Tail], List) ->
    read_text(Tail, List).

get_real_value([Text|Tail], "s", List) when is_binary(Text) ->
    Text2 = get(erlang:list_to_integer(erlang:binary_to_list(Text)) + 1),
    List2 = [Text2|List],
    get_real_value(Tail, "s", List2);
get_real_value([Text|Tail], "s", List) ->
    Text2 = get(erlang:list_to_integer(Text) + 1),
    List2 = [Text2|List],
    get_real_value(Tail, "s", List2);
get_real_value([Text|Tail], "d" = Type, List) ->
    List2 = [erlang:binary_to_list(Text)|List],
    get_real_value(Tail, Type, List2);
get_real_value([Text|Tail], Type, List) ->
    List2 = [Text|List],
    get_real_value(Tail, Type, List2);
get_real_value([], _, [Text]) ->
    Text;
get_real_value([], _, List) ->
    List.
    
get_col_pos([Attr = #xmlAttribute{name = 'r', value = [H|T]}|_Tail], {0, Nick}) when $A =< H andalso H =< $Z ->
    PosDelta = H - $A + 1,
    NewPos = get_num(PosDelta),
    NewNick = Nick ++ [H],
    get_col_pos([Attr#xmlAttribute{name = 'r', value = T}], {NewPos, NewNick});
get_col_pos([Attr = #xmlAttribute{name = 'r', value = [H|T]}|_Tail], {Pos, Nick}) when $A =< H andalso H =< $Z ->
    PosDelta = H - $A + 1,
    NewPos = PosDelta * 10 + Pos,
    NewPos2 = get_num(NewPos),
    NewNick = Nick ++ [H],
    get_col_pos([Attr#xmlAttribute{name = 'r', value = T}], {NewPos2, NewNick});
get_col_pos([_Attr = #xmlAttribute{name = 'r', value = _T}], {Pos, Nick}) ->
    {Pos, Nick};
get_col_pos([_Attr|Tail], Result) ->
    get_col_pos(Tail, Result).

get_col_pos_x([H|T], {0, Nick}) when $A =< H andalso H =< $Z ->
    PosDelta = H - $A + 1,
    NewPos = get_num(PosDelta),
    NewNick = Nick ++ [H],
    get_col_pos_x(T, {NewPos, NewNick});
get_col_pos_x([H|T], {Pos, Nick}) when $A =< H andalso H =< $Z ->
    PosDelta = H - $A + 1,
    NewPos = PosDelta * 10 + Pos,
    NewPos2 = get_num(NewPos),
    NewNick = Nick ++ [H],
    get_col_pos_x(T, {NewPos2, NewNick});
get_col_pos_x([], {Pos, Nick}) ->
    {Pos, Nick};
get_col_pos_x([_Attr|Tail], Result) ->
    get_col_pos_x(Tail, Result).

get_num(Value) when is_number(Value) -> Value;
get_num(Value) when is_list(Value)   -> erlang:list_to_integer(Value).

%% ====================================================================
%% Internal functions
%% ====================================================================


