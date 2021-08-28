
main = 10 + 10 // 10


constructor : Global -> FunctionIO -> Model
constructor global params =
    let
        ( name, symbol, totalSupply ) =
            case params of
                Tuple3 ( RString n, RString s, RInt ts ) ->
                    ( n, s, ts )

                _ ->
                    throw ("Found \"2\" Invalid" ++ "parameters")
    in
    { balances = Mapping.insert global.msg.sender totalSupply (Mapping.empty Default.int)
    , allowances = Mapping.empty (Mapping.empty Default.int)
    , totalSupply = totalSupply
    , name = name
    , symbol = symbol
    , decimals = (2.5 ^ -1) * 2
    }
