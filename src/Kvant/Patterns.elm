module Kvant.Patterns exposing (..)

import Dict exposing (Dict)

import Kvant.Vec2 exposing (Vec2)
import Kvant.Vec2 as Vec2
import Kvant.Plane exposing (..)
import Kvant.Occurrence exposing (..)
import Kvant.Occurrence as Occurrence exposing (times, toInt)


type alias PatternId = Int

-- value can be pixel, color, tile, character, whatever, but `Key` is the integer ID of it
type alias Key = Int


type alias Pattern = Plane Key


type alias PatternWithStats =
    { pattern : Pattern
    , frequency : ( Occurrence, Maybe Frequency )
    , matches : Dict Offset (List PatternId)
    --, rotations : Dict Rotation PatternId
    }


type alias UniquePatterns =
    Dict PatternId PatternWithStats


preprocess
    :  Symmetry
    -> Boundary
    -> Size
    -> Plane Key
    -> UniquePatterns
preprocess symmetry boundary ofSize inPlane =
    let
        allSubplanes = subPatterns symmetry boundary ofSize inPlane
        uniquePatterns = evaluateOccurrence allSubplanes
        uniquePatternsDict =
            uniquePatterns
                |> List.indexedMap Tuple.pair
                |> Dict.fromList
        onlyPatternsDict =
            uniquePatternsDict
                |> Dict.map (always Tuple.second)
    in
        uniquePatternsDict
                |> Dict.map (\_ ( frequency, pattern ) ->
                        { frequency = frequency
                        , pattern = pattern
                        , matches =
                            findMatches
                                onlyPatternsDict
                                pattern
                        }
                    )



evaluateOccurrence
    :  List Pattern
    -> List ((Occurrence, Maybe Frequency), Pattern)
evaluateOccurrence subPlanes_ =
    let
        uniquePatterns =
            subPlanes_
                |> List.foldr
                    (\pattern uniqueOthers ->
                        if pattern |> isAmong uniqueOthers
                            then uniqueOthers
                            else pattern :: uniqueOthers
                    )
                    []
        withOccurrence =
             uniquePatterns
                 |> List.map
                     (
                         \subPlane_ ->
                             ( subPlanes_
                                 |> List.filter (equal subPlane_)
                                 |> List.length
                                 |> Occurrence.times
                             , subPlane_
                             )
                     )
                 |> List.sortBy (Tuple.first >> Occurrence.toInt)
        total =
             withOccurrence
                |> List.foldl
                    (\(occurrence, _) sum ->
                         sum + Occurrence.toInt occurrence
                    )
                    0
                 |> toFloat
        _ =
            withOccurrence
                |> List.map (Tuple.mapSecond toList)
    in
        withOccurrence
            |> List.map
                (\(occurrence, v) ->
                    (
                        ( occurrence
                        , occurrence
                            |> Occurrence.toMaybe
                            |> Maybe.map
                                (\occurred ->
                                    Occurrence.frequencyFromFloat <| toFloat occurred / total))
                    , v
                    )
                )


{- limitsFor : Vec2 -> { from: Vec2, to: Vec2 }
limitsFor (w, h) =
    -- TODO: offsets for 1x1
    if (w <= 0) || (h <= 0) then
        { from = (0, 0), to = (0, 0 ) }
    else
        { from =
            ( if w == 1 then 1 else -1 * (w - 1)
            , if h == 1 then 1 else -1 * (h - 1)
            )
        , to =
            ( if w == 1 then 1 else w - 1
            , if h == 1 then 1 else h - 1
            )
        }


shift : Offset Vec2 -> Plane Vec2 a -> Plane Vec2 a
shift (Offset (offX, offY)) plane =
    plane
        |> transform (\(x, y) -> (x - offX, y - offY))


shiftCut : Offset Vec2 -> Plane Vec2 a -> Plane Vec2 a
shiftCut (Offset (offX, offY) as offset) (Plane (width, height) f as plane) =
    plane
        |> shift offset
        |> adjust
            (\((x, y), maybeV) ->
                if
                    (x >= 0) &&
                    (y >= 0) &&
                    (x >= offX) &&
                    (y >= offY) &&
                    (x < width) &&
                    (y < height) then maybeV else Nothing
            )


overlappingCoords : Offset Vec2 -> Plane Vec2 a -> List Vec2
overlappingCoords (Offset (offX, offY)) (Plane (width, height) _ as plane) =
    coordsFlat plane
        |> List.foldr
            (\(x, y) prev ->
                if (x + offX >= 0) &&
                   (y + offY >= 0) &&
                   (x + offX < width) &&
                   (y + offY < height) then (x + offX, y + offY) :: prev else prev
            )
            [] -}


overlappingCoords : Offset -> Size -> List Vec2
overlappingCoords ( offX, offY ) ( width, height ) =
    Vec2.coordsFlat ( width, height )
        |> List.foldr
            (\(x, y) prev ->
                if (x + offX >= 0) &&
                   (y + offY >= 0) &&
                   (x + offX < width) &&
                   (y + offY < height) then (x + offX, y + offY) :: prev else prev
            )
            []


matchesAt : Vec2 -> Dict PatternId Pattern -> Pattern -> List PatternId
matchesAt offset patterns (Plane size _ as pattern) =
    let
        oCoords = overlappingCoords offset size
    in patterns
        |> Dict.foldr
            (\idx otherPattern matches -> -- ensure plane is the same size as the source
                if otherPattern
                    |> shift offset
                    |> equalAt oCoords pattern
                    then idx :: matches
                    else matches
            )
            []


offsetsFor : Size -> List Offset
offsetsFor ( width, height ) =
    Vec2.rectFlat
        { from = ( -1 * (width - 1),  -1 * (height - 1) )
        , to = ( width - 1, height - 1 )
        }


findMatches : Dict PatternId Pattern -> Pattern -> Dict Offset (List PatternId)
findMatches patterns (Plane size _ as pattern) =
    offsetsFor size
        |> List.map (\offset -> ( offset, pattern |> matchesAt offset patterns ))
        |> Dict.fromList


isAmong : List Pattern -> Pattern -> Bool
isAmong planes subject =
    planes
        |> List.foldl
                (\other wasBefore ->
                    wasBefore || equal subject other
                )
           False


subPatterns
    :  Symmetry
    -> Boundary
    -> Size
    -> Pattern
    -> List Pattern
subPatterns symmetry method ofSize pattern =
    pattern
    |> coords
    |>  (List.map <|
        case method of
            Periodic ->
                \coord -> periodicSubPlaneAt coord ofSize pattern
            Bounded ->
                \coord -> subPlaneAt coord ofSize pattern
        )
    |> List.filter filledWithValues
    |> List.concatMap (views symmetry)
