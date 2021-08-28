module Concept.Mapping exposing (..)

import Dict exposing (Dict)


type Mapping comparable value
    = Mapping (Dict comparable value) value


singleton : comparable -> value -> value -> Mapping comparable value
singleton comparable value default =
    let
        internalDict =
            Dict.singleton comparable value
    in
    Mapping internalDict value


empty : value -> Mapping comparable value
empty default =
    let
        dict =
            Dict.empty
    in
    Mapping dict default


insert : comparable -> value -> Mapping comparable value -> Mapping comparable value
insert comparable value mapping =
    let
        ( dict, default ) =
            case mapping of
                Mapping d v ->
                    ( d, v )

        internalDict =
            Dict.insert comparable value dict
    in
    Mapping internalDict default


remove : comparable -> Mapping comparable value -> Mapping comparable value
remove comparable mapping =
    let
        ( dict, default ) =
            case mapping of
                Mapping d v ->
                    ( d, v )

        internalDict =
            Dict.remove comparable dict
    in
    Mapping internalDict default


get : comparable -> Mapping comparable value -> value
get comparable mapping =
    let
        ( dict, default ) =
            case mapping of
                Mapping d v ->
                    ( d, v )

        value =
            Dict.get comparable dict
    in
    case value of
        Just v ->
            v

        Nothing ->
            default
