
module Concept.Contract exposing (..)

import Array exposing (Array)
import Browser
import Bytes exposing (..)
import Bytes.Encode as BEnc
import Concept.Core exposing (Address, Global, Requirements, throw)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Hex
import Html exposing (Html)
import Keccak.Bytes exposing (ethereum_keccak_256)
import Random
import String exposing (fromFloat, fromInt, toInt)
import Task
import Time


type Basic
    = RAddress Address
    | RString String
    | RInt Int
    | RBool Bool


type FunctionIO
    = None
    | Single Basic
    | Tuple2 ( Basic, Basic )
    | Tuple3 ( Basic, Basic, Basic )


type Interface
    = IAddress
    | IString
    | IInt
    | IBool


type InterfaceIO
    = INone
    | ISingle Interface
    | ITuple2 ( Interface, Interface )
    | ITuple3 ( Interface, Interface, Interface )


type Position
    = P1
    | P2
    | P3


type alias Contract msg model =
    { constructor : ( Global -> FunctionIO -> model, InterfaceIO )
    , update : msg -> Global -> model -> ( Requirements, model, FunctionIO )
    }


type alias ContractCore msg model =
    { constructor : ( Global -> FunctionIO -> model, InterfaceIO )
    , update : msg -> Global -> model -> ( Requirements, model, FunctionIO )
    , signatures : List ( String, Signature )
    , encodeMsg : ( String, FunctionIO ) -> msg
    }


type alias Model model =
    { deploys : Dict String model
    , form : Dict String ( Maybe Basic, Maybe Basic, Maybe Basic )
    , returns : Dict String FunctionIO
    , addresses : Dict Address Float
    , sender : Maybe Address
    , value : Int
    , global : Global
    }


type alias Signature =
    { inputs : InterfaceIO
    , outputs : InterfaceIO
    }


type Msg
    = GenerateGlobal Msg Time.Posix
    | SetGlobal Msg Global
    | GenerateNewAddress
    | GetAddressSeed Int
    | SetDeployer Address
    | SetValue Int
    | DeployIntent Msg
    | Deploy FunctionIO
    | ContractCallIntent Msg
    | ContractCall String FunctionIO
    | SetForm String Position Basic


deploy : Contract msg model -> Program () model msg
deploy _ =
    throw "Please, don't run this directly."


interpret : ContractCore msg model -> Program () (Model model) Msg
interpret contract =
    Browser.element
        { init = init contract
        , view = view contract
        , update = update contract
        , subscriptions = \_ -> Sub.none
        }


init : ContractCore msg model -> () -> ( Model model, Cmd Msg )
init contract _ =
    ( { form = Dict.empty
      , deploys = Dict.empty
      , returns = Dict.empty
      , addresses =
            Dict.empty
      , sender = Nothing
      , value = 0
      , global =
            { msg = { sender = "", data = "", sig = "", value = 0 }
            , block = { coinbase = "", difficulty = 0, gasLimit = 0, number = 0, timestamp = 0 }
            }

      -- { contract
      --     | deploys = Mapping.insert "default" (contract.constructor global [ "test" ]) contract.deploys
      -- }
      }
    , Cmd.batch
        (List.append
            (List.repeat 5 (Random.generate GetAddressSeed anyInt))
            []
        )
    )


generateGlobal : Model model -> Time.Posix -> Random.Generator Global
generateGlobal model timestamp =
    let
        msg =
            { sender = Maybe.withDefault "" model.sender
            , data = ""
            , sig = ""
            , value = model.value
            }
    in
    Random.map2
        (\difficulty number ->
            { msg = msg
            , block =
                { coinbase = "0x" ++ hexify (ethereum_keccak_256 (BEnc.encode (BEnc.unsignedInt32 LE number)))
                , difficulty = difficulty
                , gasLimit = 0
                , number = number
                , timestamp = Time.toMillis Time.utc timestamp
                }
            }
        )
        (Random.int 0 100)
        (Random.int 0 Random.maxInt)


update : ContractCore msg model -> Msg -> Model model -> ( Model model, Cmd Msg )
update contract msg model =
    case msg of
        GenerateGlobal msgIntent timestamp ->
            ( model
            , Cmd.batch
                [ Random.generate (\g -> SetGlobal msgIntent g) (generateGlobal model timestamp)
                ]
            )

        SetGlobal msgIntent g ->
            ( { model | global = g }
            , Cmd.batch
                [ Task.succeed msgIntent
                    |> Task.perform identity
                ]
            )

        GenerateNewAddress ->
            ( model, Cmd.batch [ Random.generate GetAddressSeed anyInt ] )

        GetAddressSeed seed ->
            let
                -- Reference: https://medium.com/@jeancvllr/solidity-tutorial-all-about-addresses-ffcdf7efc4e7
                address =
                    String.right 40 (hexify (ethereum_keccak_256 (BEnc.encode (BEnc.unsignedInt32 LE seed))))

                addresses =
                    Dict.insert ("0x" ++ address) 100.0 model.addresses

                sender =
                    case model.sender of
                        Nothing ->
                            Just ("0x" ++ address)

                        Just a ->
                            Just a
            in
            ( { model | sender = sender, addresses = addresses }, Cmd.none )

        SetDeployer address ->
            ( { model | sender = Just address }, Cmd.none )

        SetValue v ->
            ( { model | value = v }, Cmd.none )

        DeployIntent msgIntent ->
            ( model
            , Cmd.batch
                [ Task.perform (GenerateGlobal msgIntent) Time.now
                ]
            )

        Deploy params ->
            let
                ( constructor, _ ) =
                    contract.constructor

                deploys =
                    Dict.insert "default" (constructor model.global params) model.deploys

                deployerAddress =
                    Maybe.withDefault "" model.sender

                deployerEth =
                    Maybe.withDefault 0 (Dict.get deployerAddress model.addresses)

                _ =
                    if deployerEth - 0.1 < 0 then
                        throw "Not enough funds"

                    else
                        0

                addresses =
                    Dict.insert deployerAddress (deployerEth - 0.1) model.addresses
            in
            ( { model | deploys = deploys, addresses = addresses }, Cmd.none )

        ContractCallIntent msgIntent ->
            ( model
            , Cmd.batch
                [ Task.perform (GenerateGlobal msgIntent) Time.now
                ]
            )

        ContractCall name params ->
            let
                currentDeploy =
                    case Dict.get "default" model.deploys of
                        Just m ->
                            m

                        Nothing ->
                            throw "Contract not deployed."

                ( requirements, updatedModel, returns ) =
                    contract.update (contract.encodeMsg ( name, params )) model.global currentDeploy

                errors =
                    List.filterMap
                        (\( ok, error ) ->
                            if ok then
                                Nothing

                            else
                                Just error
                        )
                        requirements

                _ =
                    if List.length errors == 0 then
                        Nothing

                    else
                        Just (Debug.log "failed" (String.join " " errors))

                deploys =
                    if List.length errors == 0 then
                        Dict.insert "default" updatedModel model.deploys

                    else
                        model.deploys

                newReturns =
                    if List.length errors == 0 then
                        Dict.insert name
                            returns
                            model.returns

                    else
                        model.returns
            in
            ( { model | deploys = deploys, returns = newReturns }, Cmd.none )

        SetForm name position param ->
            let
                ( value1, value2, value3 ) =
                    Maybe.withDefault ( Nothing, Nothing, Nothing ) (Dict.get name model.form)

                fields =
                    case position of
                        P1 ->
                            ( Just param, value2, value3 )

                        P2 ->
                            ( value1, Just param, value3 )

                        P3 ->
                            ( value1, value2, Just param )

                updatedForm =
                    Dict.insert name fields model.form
            in
            ( { model | form = updatedForm }, Cmd.none )


view : ContractCore msg model -> Model model -> Html Msg
view contract model =
    let
        signatures =
            contract.signatures

        ( _, constructorSignature ) =
            contract.constructor
    in
    layout [] <|
        row [ height fill, Element.width fill ]
            [ panel contract model
            ]


panel : ContractCore msg model -> Model model -> Element Msg
panel contract model =
    let
        signatures =
            contract.signatures

        ( _, constructorParams ) =
            contract.constructor

        filled =
            Element.width fill
    in
    column
        [ height fill
        , Element.width <| fill
        -- , Background.color <| Element.rgb255 165 139 244
        , Background.gradient <|
            { angle = pi
            , steps =
                [ Element.rgb255 13 17 38
                , Element.rgb255 22 20 52
                , Element.rgb255 27 21 62
                , Element.rgb255 48 23 72
                ]
            }
        , Font.color <| Element.rgb255 255 255 255
        , spacing 10
        , padding 30
        ]
        -- [ Element.text "running..."
        [ Input.button
            [ Background.color (Element.rgb255 141 221 219)
            , padding 10
            ]
            { onPress = Just GenerateNewAddress
            , label =
                text "New Address"
            }
        , viewAddresses model
        , constructorForm model ( "constructor", Signature constructorParams INone )
        , formParseSend model "constructor"
        , column [ filled, spacing 10 ] (List.map (form model) signatures)
        ]


viewAddresses : Model model -> Element Msg
viewAddresses model =
    let
        sender =
            case model.sender of
                Just a ->
                    a

                Nothing ->
                    ""
    in
    Element.column [ Element.width fill ]
        (List.map
            (\( k, v ) ->
                row [ Element.width fill ]
                    [ Input.button
                        [ if k /= sender then
                            Background.color (Element.rgba255 0 0 0 0)

                          else
                            Background.color (Element.rgb255 226 26 123)
                        ]
                        { onPress =
                            if k /= sender then
                                Just (SetDeployer k)

                            else
                                Nothing
                        , label = text "[ set as sender ]"
                        }
                    , el [ Element.width (fillPortion 6), Font.alignRight ] <|
                        text k
                    , el [ Element.width (fillPortion 4), Font.center ] <|
                        text
                            ("["
                                ++ fromFloat v
                                ++ " eth]"
                            )
                    ]
            )
            (Dict.toList model.addresses)
        )


constructorForm : Model model -> ( String, Signature ) -> Element Msg
constructorForm model nameSignature =
    let
        fields =
            signatureToInput model nameSignature
    in
    column [ Element.width fill ]
        [ Input.text [ Font.color (Element.rgb255 0 0 0) ]
            { label = Input.labelLeft [] <| text "value"
            , placeholder = Nothing
            , text =
                if model.value > 0 then
                    String.fromInt model.value

                else
                    "0"
            , onChange = \s -> SetValue (Maybe.withDefault 0 (toInt s))
            }
        , el [ Element.width fill, padding 50 ] fields
        ]


form : Model model -> ( String, Signature ) -> Element Msg
form model nameSignature =
    let
        ( name, _ ) =
            nameSignature

        fields =
            signatureToInput model nameSignature

        filled =
            Element.width fill
    in
    case Dict.get "default" model.deploys of
        Just _ ->
            column
                [ filled
                , Border.width 1
                , Border.rounded 3
                , Border.color <| rgb255 200 200 200
                , padding 20
                ]
                [ el [ Font.size 24, Font.bold ] <| text name
                , column [ filled ] [ fields, formParseSend model name ]
                ]

        Nothing ->
            text ""


signatureToInput : Model model -> ( String, Signature ) -> Element Msg
signatureToInput model nameSignature =
    let
        ( key, signature ) =
            nameSignature

        singleToInputCurried =
            singleToInput model

        filled =
            Element.width fill
    in
    case signature.inputs of
        ISingle iBasic ->
            el [ filled ] <|
                singleToInputCurried key P1 iBasic

        ITuple2 ( iBasic1, iBasic2 ) ->
            column [ filled ]
                [ singleToInputCurried key P1 iBasic1
                , singleToInputCurried key P2 iBasic2
                ]

        ITuple3 ( iBasic1, iBasic2, iBasic3 ) ->
            column [ filled ]
                [ singleToInputCurried key P1 iBasic1
                , singleToInputCurried key P2 iBasic2
                , singleToInputCurried key P3 iBasic3
                ]

        INone ->
            text ""


singleToInput : Model model -> String -> Position -> Interface -> Element Msg
singleToInput model key position interface =
    let
        ( v1, v2, v3 ) =
            Maybe.withDefault ( Nothing, Nothing, Nothing ) (Dict.get key model.form)

        valueBasic =
            case position of
                P1 ->
                    v1

                P2 ->
                    v2

                P3 ->
                    v3
    in
    case interface of
        IAddress ->
            let
                val =
                    case valueBasic of
                        Just (RAddress v) ->
                            v

                        Nothing ->
                            ""

                        _ ->
                            throw "Strange value for field RAddress."
            in
            Input.text [ Element.width fill, Font.color (Element.rgb255 0 0 0) ]
                { label = Input.labelLeft [ Element.width fill ] <| text "Address"
                , placeholder = Nothing
                , text = val
                , onChange = \s -> SetForm key position (RAddress s)
                }

        IString ->
            let
                val =
                    case valueBasic of
                        Just (RString v) ->
                            v

                        Nothing ->
                            ""

                        _ ->
                            throw "Strange value for field RString."
            in
            Input.text [ Element.width fill, Font.color (Element.rgb255 0 0 0) ]
                { label = Input.labelLeft [ Element.width fill ] <| text "Text"
                , placeholder = Nothing
                , text = val
                , onChange = \s -> SetForm key position (RString s)
                }

        IInt ->
            let
                val =
                    case valueBasic of
                        Just (RInt v) ->
                            fromInt v

                        Nothing ->
                            ""

                        _ ->
                            throw "Strange value for field RInt."
            in
            Input.text [ Element.width fill, Font.color (Element.rgb255 0 0 0) ]
                { label = Input.labelLeft [ Element.width fill ] <| text "Int"
                , placeholder = Nothing
                , text = val
                , onChange = \s -> SetForm key position (RInt (Maybe.withDefault 0 (toInt s)))
                }

        IBool ->
            let
                val =
                    case valueBasic of
                        Just (RBool v) ->
                            v

                        Nothing ->
                            False

                        _ ->
                            throw "Strange value for field RInt."
            in
            Input.checkbox [ Element.width fill ]
                { label = Input.labelLeft [ Element.width fill ] <| text "Bool"
                , checked = val
                , icon = Input.defaultCheckbox
                , onChange = \b -> SetForm key position (RBool b)
                }


formParseSend : Model model -> String -> Element Msg
formParseSend model key =
    let
        formData =
            Maybe.withDefault ( Nothing, Nothing, Nothing ) (Dict.get key model.form)

        isConstructor =
            key == "constructor"

        params =
            case formData of
                ( Nothing, Nothing, Nothing ) ->
                    None

                ( Just basic, Nothing, Nothing ) ->
                    Single basic

                ( Just basic1, Just basic2, Nothing ) ->
                    Tuple2 ( basic1, basic2 )

                ( Just basic1, Just basic2, Just basic3 ) ->
                    Tuple3 ( basic1, basic2, basic3 )

                _ ->
                    throw "Malformed form data."

        parseReturn basic =
            case basic of
                RString s ->
                    s

                RAddress s ->
                    s

                RInt i ->
                    fromInt i

                RBool b ->
                    if b then
                        "True"

                    else
                        "False"

        returns =
            case Dict.get key model.returns of
                Just None ->
                    ""

                Just (Single basic) ->
                    parseReturn basic

                Just (Tuple2 ( basic1, basic2 )) ->
                    parseReturn basic1 ++ "; " ++ parseReturn basic2

                Just (Tuple3 ( basic1, basic2, basic3 )) ->
                    parseReturn basic1 ++ "; " ++ parseReturn basic2 ++ "; " ++ parseReturn basic2

                Nothing ->
                    ""
    in
    if isConstructor then
        Input.button [ alignRight, paddingEach { top = 0, right = 60, left = 0, bottom = 0 } ]
            { onPress = Just (DeployIntent (Deploy params))
            , label = text "Deploy"
            }

    else
        column [ alignRight ]
            [ Input.button [ paddingEach { top = 20, right = 0, left = 0, bottom = 0 } ]
                { onPress = Just (ContractCallIntent (ContractCall key params))
                , label = text "Transact"
                }
            , el [ paddingEach { top = 15, right = 0, left = 10, bottom = 0 } ] <| text returns
            ]


anyInt : Random.Generator Int
anyInt =
    Random.int Random.minInt Random.maxInt


hexify : List Int -> String
hexify l =
    String.concat (List.map (Hex.toString >> String.padLeft 2 '0') l)

