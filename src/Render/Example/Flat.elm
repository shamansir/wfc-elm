module Render.Example.Flat exposing (..)


import Dict

import Html exposing (..)
import Html.Attributes exposing (..)

import WFC.Vec2 exposing (..)
import WFC.Plane exposing (..)
import WFC.Plane.Flat exposing (..)
import WFC.Plane.Flat as Plane exposing (allViews)
import WFC.Plane.Impl.Tracing exposing (..)
import WFC.Solver exposing (..)
import WFC.Solver.Flat as WFC
import WFC.Solver.History exposing (..)
import WFC.Matches as Matches exposing (..)

import Render.Core as Render exposing (..)
import Render.Grid as Render exposing (..)
import Render.Flat as Render exposing (..)
import Render.Example exposing (Renderer)


type alias Options fmt a =
    { fmtToGrid : Vec2 -> fmt -> List (List a)
    , subPlanes : List (Vec2, Vec2)
    , periodicSubPlanes : List (Vec2, Vec2)
    }


subPlanesCoords : List (Vec2, Vec2)
subPlanesCoords =
    [ ( (0, 0), (2, 2) )
    , ( (0, 0), (3, 3) )
    , ( (1, 1), (2, 2) )
    , ( (1, 1), (3, 3) )
    , ( (0, 1), (3, 3) )
    , ( (0, 1), (2, 3) )
    , ( (3, 3), (1, 1) )
    , ( (3, 3), (4, 4) )
    ]


periodicSubPlanesCoords : List (Vec2, Vec2)
periodicSubPlanesCoords =
    subPlanesCoords ++
        [ ( (2, 3), (4, 4) )
        , ( (-2, -2), (4, 4) )
        ]


makeFlat
    :  Options fmt a
    -> Spec Vec2 a msg
    -> Renderer Vec2 fmt a msg
makeFlat opts spec =
    let
        source size fmt =
            opts.fmtToGrid size fmt
                |> Render.grid spec.a
        withCoords = Render.withCoords spec.v spec.a
        subPlanes plane =
            opts.subPlanes
                |> List.map
                    (\(origin, size) ->
                        ( spec.vToString origin ++ " " ++ spec.vToString size
                        , subAt origin (N size) plane
                        )
                    )
                |> List.map (Tuple.mapSecond <| Maybe.withDefault plane)
                |> Render.labeledList spec.default withCoords
        periodicSubPlanes plane =
            opts.periodicSubPlanes
                |> List.map
                    (\(origin, size) ->
                        ( spec.vToString origin ++ " " ++ spec.vToString size
                        , periodicSubAt origin (N size) plane
                        )
                    )
                |> Render.labeledList spec.default withCoords
        allViews plane =
            Plane.allViews plane
                |> Render.indexedList spec.default withCoords
        allSubPlanes method size =
            Render.indexedList spec.default withCoords
                << findAllSubsAlt method size
        materialized =
            listBy (\(v, maybeA) -> withCoords v <| Maybe.withDefault spec.default <| maybeA)
                << materializeFlatten
        patterns method n plane =
                let
                    uniquePatterns = WFC.findUniquePatterns method n plane
                in
                    Render.listBy identity
                        <| Dict.values
                        <| Dict.map
                            (Render.pattern spec.default withCoords uniquePatterns)
                            uniquePatterns
        rotationsAndFlips p =
            [ ( "Original", p )
            , ( "North", rotateTo North p )
            , ( "West", rotateTo West p )
            , ( "South", rotateTo South p )
            , ( "East", rotateTo East p )
            , ( "Horz", flipBy Horizontal p )
            , ( "Vert", flipBy Vertical p )
            , ( "rotate once", rotate p )
            , ( "rotate twice", rotate <| rotate p )
            , ( "rotate triple times", rotate <| rotate <| rotate p )
            , ( "flip", flip p )
            , ( "flip rotated", flip <| rotate p )
            , ( "rotate flipped", rotate <| flip p )
            ]
            |> Render.labeledList spec.default withCoords
    in
        { source = source
        , tracing = Render.tracing spec.contradiction spec.a spec.v
        , tracingTiny = Render.tracingTiny spec.default spec.scaled spec.v
        , subPlanes = subPlanes
        , periodicSubPlanes = periodicSubPlanes
        , allViews = allViews
        , rotationsAndFlips = Render.rotationsAndFlips spec.default withCoords
        , allSubPlanes = allSubPlanes
        , materialized = materialized
        , patterns = patterns
        , step = Render.step spec.v
        , history = Render.history <| Render.step spec.v
        }
