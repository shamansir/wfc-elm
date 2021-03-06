module Kvant.Json.Adjacency exposing (..)


import Dict exposing (Dict)

import Json.Encode as E
import Json.Decode as D

import Kvant.Plane as Plane
import Kvant.Adjacency exposing (Adjacency)
import Kvant.Matches as Matches exposing (Matches)


-- TODO: merge in one `Adjacency Int Int`
-- so that for Patterns and Tiles the principle would be the same

encode : Adjacency Int Int -> E.Value
encode = encodeWith E.int E.int


encodeWith : (i -> E.Value) -> (a -> E.Value) -> Adjacency i a -> E.Value
encodeWith keyEncode itemEncode =
    Dict.toList
        >> E.list (encodeItem keyEncode itemEncode)


decode : D.Decoder (Adjacency Int Int)
decode =
    decodeWith D.int D.int


decodeWith : D.Decoder comparable -> D.Decoder a -> D.Decoder (Adjacency comparable a)
decodeWith decodeKey decodeItem =
    D.list (decodeItems decodeKey decodeItem)
        |> D.map Dict.fromList


decodeItems
    :  D.Decoder i
    -> D.Decoder a
    -> D.Decoder
        ( i
        ,
            { subject : a
            , weight : Float
            , matches : Dict Plane.Offset (Matches i)
            }
        )
decodeItems decodeKey decodeItem =
    D.map2
        Tuple.pair
        (D.field "id" decodeKey)
        <| D.map3
            (\s w m -> { subject = s, weight = w, matches = m })
            (D.field "subject" decodeItem)
            (D.field "weight" D.float)
            (D.field "matches" <| decodeMatches decodeKey)


decodeMatches : D.Decoder i -> D.Decoder (Dict Plane.Offset (Matches i))
decodeMatches decodeKey =
    D.list
        (D.map3
            (\x y matches -> ( (x, y), Matches.fromList matches ))
            (D.field "x" D.int)
            (D.field "y" D.int)
            (D.field "matches" <| D.list decodeKey)
        )
        |> D.map Dict.fromList


encodeItem
    :  ( i -> E.Value )
    -> ( a -> E.Value )
    ->  ( i
        ,
            { subject : a
            , weight : Float
            , matches : Dict Plane.Offset (Matches i)
            }
        )
    -> E.Value
encodeItem keyEncode itemEncode ( itemId, stats ) =
    E.object
        [ ( "id", keyEncode itemId )
        , ( "subject", stats.subject |> itemEncode )
        , ( "weight", stats.weight |> E.float )
        ,
            ( "matches"
            , stats.matches
                |> Dict.toList
                |> E.list
                    (\((x, y), matches) ->
                        E.object
                            [ ( "x", E.int x )
                            , ( "y", E.int y )
                            , ( "matches", matches |> Matches.toList |> E.list keyEncode )
                            ]
                    )
            )
        ]

