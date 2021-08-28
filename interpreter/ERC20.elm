
module ERC20.ERC20 exposing (..)


import Concept.Contract as ContractModule
    exposing
        ( Basic(..)
        , Contract
        , FunctionIO(..)
        , Interface(..)
        , InterfaceIO(..)
        , Signature
        , deploy
        )
import Concept.Core exposing (Address, Global, Requirements, throw, zeroAddress)
import Concept.DefaultValues as Default
import Concept.Mapping as Mapping exposing (Mapping(..))


main : Program () Model Msg
main =
    deploy <|
        Contract ( constructor, ITuple3 ( IString, IString, IInt ) )
            update


type alias Model =
    { balances : Mapping Address Int
    , allowances : Mapping Address (Mapping Address Int)
    , totalSupply : Int
    , name : String
    , symbol : String
    , decimals : Int
    }


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
    , decimals = 18
    }


type Msg
    = BalanceOf Address
    | Transfer Address Int
    | GetAllowance Address Address
    | Approve Address Int
    | TransferFrom Address Address Int
    | GetName
    | GetSymbol
    | GetDecimals
    | GetTotalSupply


update : Msg -> Global -> Model -> ( Requirements, Model, FunctionIO )
update msg global model =
    case msg of
        BalanceOf address ->
            let
                balance =
                    Mapping.get address model.balances
            in
            ( []
            , model
            , Single <| RInt balance
            )

        Transfer address amount ->
            let
                senderBalance =
                    Mapping.get global.msg.sender model.balances

                updatedBalances =
                    Mapping.insert global.msg.sender (senderBalance - amount) model.balances

                recipientBalance =
                    Mapping.get address updatedBalances
            in
            ( [ ( global.msg.sender /= zeroAddress, "ERC20: transfer from the zero address" )
              , ( address /= zeroAddress, "ERC20: transfer to the zero address" )
              , ( senderBalance >= amount, "ERC20: transfer amount exceeds balance" )
              , ( amount > 0, "ERC20: amount should be positive" )
              ]
            , { model
                | balances =
                    Mapping.insert address
                        (recipientBalance + amount)
                        updatedBalances
              }
            , Single <| RBool True
            )

        GetAllowance owner spender ->
            let
                allowancesMapping =
                    Mapping.get owner model.allowances

                allowedBalance =
                    Mapping.get spender allowancesMapping
            in
            ( [], model, Single (RInt allowedBalance) )

        Approve spender amount ->
            let
                allowancesMapping =
                    Mapping.get global.msg.sender model.allowances

                allowances =
                    Mapping.insert global.msg.sender
                        (Mapping.insert spender amount allowancesMapping)
                        model.allowances
            in
            ( [ ( global.msg.sender /= zeroAddress, "ERC20: approve from the zero address" )
              , ( spender /= zeroAddress, "ERC20: approve to the zero address" )
              ]
            , { model | allowances = allowances }
            , Single <|
                RBool True
            )

        TransferFrom sender recipient amount ->
            let
                senderBalance =
                    Mapping.get sender model.balances

                updatedBalance =
                    Mapping.insert sender (senderBalance - amount) model.balances

                recipientBalance =
                    Mapping.get recipient updatedBalance

                allowancesMapping =
                    Mapping.get sender model.allowances

                allowedBalance =
                    Mapping.get global.msg.sender allowancesMapping

                allowances =
                    Mapping.insert sender
                        (Mapping.insert global.msg.sender (allowedBalance - amount) allowancesMapping)
                        model.allowances
            in
            ( [ ( sender /= zeroAddress, "ERC20: transfer from the zero address" )
              , ( recipient /= zeroAddress, "ERC20: transfer to the zero address" )
              , ( senderBalance >= amount, "ERC20: transfer amount exceeds balance" )
              , ( allowedBalance >= amount, "ERC20: transfer amount exceeds allowance" )
              , ( amount > 0, "ERC20: amount should be positive" )
              ]
            , { model
                | allowances = allowances
                , balances =
                    Mapping.insert recipient
                        (recipientBalance + amount)
                        updatedBalance
              }
            , Single <|
                RBool True
            )

        GetName ->
            ( [], model, Single <| RString model.name )

        GetSymbol ->
            ( [], model, Single <| RString model.symbol )

        GetDecimals ->
            ( [], model, Single <| RInt model.decimals )

        GetTotalSupply ->
            ( [], model, Single <| RInt model.totalSupply )
