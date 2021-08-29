module Deployer exposing (..)

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
    [ ( "BalanceOf" , Signature (ISingle IAddress) (ISingle IInt) )
    , ( "Transfer" , Signature (ITuple2 (IAddress, IInt)) (ISingle IBool) )
    , ( "GetAllowance" , Signature (ITuple2 (IAddress, IAddress)) (ISingle IInt) )
    , ( "Approve" , Signature (ITuple2 (IAddress, IInt)) (ISingle IBool) )
    , ( "TransferFrom" , Signature (ITuple3 (IAddress, IAddress, IInt)) (ISingle IBool) )
    , ( "GetName" , Signature INone (ISingle IString) )
    , ( "GetSymbol" , Signature INone (ISingle IString) )
    , ( "GetDecimals" , Signature INone (ISingle IInt) )
    , ( "GetTotalSupply" , Signature INone (ISingle IInt) )
    ]


encodeMsg : ( String, FunctionIO ) -> ERC20.ERC20.Msg
encodeMsg toEncode =
    case toEncode of
    ( "BalanceOf", Single (RAddress a) ) ->
        BalanceOf a

    ( "Transfer", Tuple2 ( RAddress a, RInt b ) ) ->
        Transfer a b

    ( "GetAllowance", Tuple2 ( RAddress a, RAddress b ) ) ->
        GetAllowance a b

    ( "Approve", Tuple2 ( RAddress a, RInt b ) ) ->
        Approve a b

    ( "TransferFrom", Tuple3 ( RAddress a, RAddress b, RInt c ) ) ->
        TransferFrom a b c

    ( "GetName", None ) ->
        GetName

    ( "GetSymbol", None ) ->
        GetSymbol

    ( "GetDecimals", None ) ->
        GetDecimals

    ( "GetTotalSupply", None ) ->
        GetTotalSupply

    _ ->
        throw "Invalid Call"
