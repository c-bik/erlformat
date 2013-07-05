-module(erlformat).

-export([string/1]).

string(String) when is_binary(String) -> string(binary_to_list(String));
string(String) when is_list(String) ->
    Str = case lists:reverse(String) of
        [$.|_] -> String;
        _ -> String++"."
    end,
    case erl_scan:string(Str) of
        {ok, Tokens, _} ->
            case erl_parse:parse_term(Tokens) of
                {error, TermParseErr} ->
                    case erl_parse:parse_exprs(Tokens) of
                        {ok, Exprs} -> io:format(user, "~s~n", [lists:flatten(format_exprs(Exprs))]);
                        {error, ExprParseErr} -> {error, {ExprParseErr, TermParseErr}}
                    end;
                {ok, Term} -> format_term(Term)
            end;
        {error, TermParseErr, _} ->
            {error, TermParseErr}
    end.

format_term(_Term) -> "unsupported".

format_exprs([]) -> [];
format_exprs([F|Rest]) -> [format_exprs(F) | format_exprs(Rest)];

format_exprs({'fun',_,{clauses,Clauses}}) ->
    ClauseCount = length(Clauses),
    [
        io_lib:format("fun", []),
        if ClauseCount > 1 -> io_lib:format("~n", []); true -> [] end,
        [format_exprs({fun_clause, C}) || C <- Clauses],
        io_lib:format("~nend.", [])
    ];

format_exprs({fun_clause, {clause,1,V,G,B}}) ->
    io_lib:format("(~p) ~p ->~n~p", [V,G,B]);

format_exprs(Unsupported) -> io_lib:format("Work in progress ~p", [Unsupported]).

