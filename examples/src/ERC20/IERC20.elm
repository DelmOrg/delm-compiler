module ERC20.IERC20 exposing (..)

import Concept.Contract as ContractModule exposing (Basic(..), ContractCore, FunctionIO(..), Interface(..), InterfaceIO(..), Signature, interpret)
import Concept.Core exposing (throw)
import ERC20.ERC20 exposing (..)


main : Program () (ContractModule.Model Model) ContractModule.Msg
main =
    interpret <|
        ContractCore ( ERC20.ERC20.constructor, ITuple3 ( IString, IString, IInt ) )
            ERC20.ERC20.update
            signatures
            encodeMsg


signatures : List ( String, Signature )
signatures =
    [ ( "balanceOf", Signature (ISingle IAddress) (ISingle IInt) )
    , ( "transfer", Signature (ITuple2 ( IAddress, IInt )) (ISingle IBool) )
    , ( "allowance", Signature (ITuple2 ( IAddress, IAddress )) (ISingle IBool) )
    , ( "approve", Signature (ITuple2 ( IAddress, IInt )) (ISingle IBool) )
    , ( "transferFrom", Signature (ITuple3 ( IAddress, IAddress, IInt )) (ISingle IBool) )
    , ( "name", Signature INone (ISingle IString) )
    , ( "symbol", Signature INone (ISingle IString) )
    , ( "decimals", Signature INone (ISingle IInt) )
    , ( "totalSupply", Signature INone (ISingle IInt) )
    ]


encodeMsg : ( String, FunctionIO ) -> ERC20.ERC20.Msg
encodeMsg toEncode =
    case toEncode of
        ( "balanceOf", Single (RAddress address) ) ->
            BalanceOf address

        ( "transfer", Tuple2 ( RAddress address, RInt amount ) ) ->
            Transfer address amount

        ( "allowance", Tuple2 ( RAddress owner, RAddress spender ) ) ->
            GetAllowance owner spender

        ( "approve", Tuple2 ( RAddress owner, RInt amount ) ) ->
            Approve owner amount

        ( "transferFrom", Tuple3 ( RAddress sender, RAddress recipient, RInt amount ) ) ->
            TransferFrom sender recipient amount

        ( "name", None ) ->
            GetName

        ( "symbol", None ) ->
            GetSymbol

        ( "decimals", None ) ->
            GetDecimals

        ( "totalSupply", None ) ->
            GetTotalSupply

        _ ->
            throw "Invalid Call"
