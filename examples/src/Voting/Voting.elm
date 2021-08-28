module Voting.Voting exposing (..)

import Concept.Contract as ContractModule exposing (Basic(..), Contract, FunctionIO(..), Interface(..), InterfaceIO(..), Signature, deploy)
import Concept.Core exposing (Address, Global, Requirements, throw, zeroAddress)
import Concept.Mapping as Mapping exposing (Mapping(..))


main : Program () Model Msg
main =
    deploy <|
        Contract ( constructor, ITuple2 ( IString, IString ) )
            update



-- Contract types


type alias Voter =
    { weight : Int
    , voted : Bool
    , delegate : Maybe Address
    , vote : Maybe Int
    }


type alias Proposal =
    { name : String
    , voteCount : Int
    }


type alias Model =
    { chairperson : Address
    , voters : Mapping Address Voter
    , proposals : List Proposal
    }


constructor : Global -> FunctionIO -> Model
constructor global proposals =
    let
        ( p1, p2 ) =
            case proposals of
                Tuple2 ( RString s1, RString s2 ) ->
                    ( s1, s2 )

                _ ->
                    throw "Invalid parameters"
    in
    { chairperson = global.msg.sender
    , voters =
        Mapping.singleton global.msg.sender (Voter 1 False Nothing Nothing) (Voter 1 False Nothing Nothing)
    , proposals = List.map (\proposal -> Proposal proposal 0) [ p1, p2 ]
    }


type Msg
    = GiveRightToVote Address
    | DelegateVote Address
    | SendVote Int
    | GetWinningProposal
    | GetWinningProposalName


update : Msg -> Global -> Model -> ( Requirements, Model, FunctionIO )
update msg global model =
    case msg of
        GiveRightToVote address ->
            let
                voters =
                    Mapping.insert address (Voter 1 False Nothing Nothing) model.voters

                hasVoted =
                    .voted (Mapping.get address model.voters)
            in
            ( [ ( global.msg.sender == model.chairperson, "Only chairperson can give right to vote." )
              , ( not hasVoted, "The voter already voted." )
              ]
            , { model | voters = voters }
            , None
            )

        DelegateVote address ->
            let
                delegateAddress =
                    findDelegate global.msg.sender model.voters address

                ( hasVoted, voter ) =
                    let
                        v =
                            Mapping.get global.msg.sender model.voters
                    in
                    let
                        updatedVoter =
                            { v | voted = True, delegate = Just delegateAddress }
                    in
                    ( v.voted, updatedVoter )

                delegate =
                    let
                        d =
                            Mapping.get delegateAddress model.voters
                    in
                    let
                        weight =
                            if not d.voted then
                                d.weight + voter.weight

                            else
                                d.weight
                    in
                    { d | weight = weight }

                -- Voter weight True (Just address) Nothing
                -- Voter 1 False Nothing Nothing
                proposals =
                    if delegate.voted then
                        List.indexedMap
                            (\i ->
                                \proposal ->
                                    if Maybe.withDefault -1 delegate.vote == i then
                                        { proposal | voteCount = proposal.voteCount + voter.weight }

                                    else
                                        proposal
                            )
                            model.proposals

                    else
                        model.proposals

                -- List.indexedMap
                --     (\i ->
                --         \proposal ->
                --             if delegate.voted && Maybe.withDefault -1 delegate.vote == i then
                --                 { proposal | voteCount = proposal.voteCount + sender.weight }
                --             else
                --                 proposal
                --     )
                --     model.proposals
            in
            ( [ ( address /= global.msg.sender, "Self-delegation is disallowed." )
              , ( not hasVoted, "You already voted." )
              , ( delegateAddress /= zeroAddress, "Zero address can't be a voter." )
              ]
            , { model
                | voters =
                    Mapping.insert delegateAddress
                        delegate
                        (Mapping.insert global.msg.sender voter model.voters)
                , proposals = proposals
              }
            , None
            )

        SendVote vote ->
            let
                ( hasVoted, voter ) =
                    let
                        v =
                            Mapping.get global.msg.sender model.voters

                        updatedVoter =
                            { v | voted = True, vote = Just vote }
                    in
                    ( v.voted, updatedVoter )

                proposals =
                    List.indexedMap
                        (\i ->
                            \proposal ->
                                if vote == i then
                                    { proposal | voteCount = proposal.voteCount + voter.weight }

                                else
                                    proposal
                        )
                        model.proposals
            in
            ( [ ( voter.weight /= 0, "Has no right to vote." )
              , ( not hasVoted, "You already voted." )
              ]
            , { model
                | voters = Mapping.insert global.msg.sender voter model.voters
                , proposals = proposals
              }
            , None
            )

        GetWinningProposal ->
            let
                ( proposalIndex, _ ) =
                    Maybe.withDefault ( -1, 0 ) (List.head (List.reverse (List.sortBy Tuple.second (List.indexedMap (\i p -> ( i, p.voteCount )) model.proposals))))
            in
            ( [], model, Single (RInt proposalIndex) )

        GetWinningProposalName ->
            let
                proposal =
                    Maybe.withDefault (Proposal "" 0) (List.head (List.reverse (List.sortBy .voteCount model.proposals)))
            in
            ( [], model, Single (RString proposal.name) )


findDelegate : Address -> Mapping Address Voter -> Address -> Address
findDelegate sender voters to =
    let
        _ =
            if to == sender then
                throw "Found loop in delegation."

            else
                Nothing

        delegate =
            let
                d =
                    Mapping.get to voters
            in
            -- how to handle maybes?
            case d.delegate of
                Just address ->
                    findDelegate sender voters address

                Nothing ->
                    to
    in
    delegate


signatures : List ( String, Signature )
signatures =
    [ ( "giveRightToVote", Signature (ISingle IAddress) INone )
    , ( "delegateVote", Signature (ISingle IAddress) INone )
    , ( "sendVote", Signature (ISingle IInt) INone )
    , ( "getWinningProposal", Signature INone (ISingle IInt) )
    , ( "getWinningProposalName", Signature INone (ISingle IString) )
    ]


encodeMsg : ( String, FunctionIO ) -> Msg
encodeMsg toEncode =
    case toEncode of
        ( "giveRightToVote", Single (RAddress address) ) ->
            GiveRightToVote address

        ( "delegateVote", Single (RAddress address) ) ->
            DelegateVote address

        ( "sendVote", Single (RInt vote) ) ->
            SendVote vote

        ( "getWinningProposal", None ) ->
            GetWinningProposal

        ( "getWinningProposalName", None ) ->
            GetWinningProposalName

        _ ->
            throw "Invalid Call"
