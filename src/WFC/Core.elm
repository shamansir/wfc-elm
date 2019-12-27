module WFC.Core exposing
    ( WFC, Instance(..)
    , text, TextWFC
    , run
    )


import Random


import WFC.Vec2 exposing (..)
import WFC.Plane.Text as TextPlane exposing (make, toString)
import WFC.Solver exposing (..)


type WFC v fmt a =
    WFC ( (Step a, fmt) -> (Step a, fmt) )


type Instance
    = Text TextWFC


type alias TextWFC = WFC Vec2 String Char


text : TextOptions -> TextWFC
text options =
    WFC <|
        \(step, input) ->
            let
                -- plane : TextPlane
                plane = input |> TextPlane.make options.inputSize
                -- patterns : List ( Occured, TextPlane )
                patterns
                    = findUniquePatterns
                        options.patternSearch
                        options.patternSize
                        plane
                -- solver : TextSolver
                solver = Solver options plane patterns
            in
                solver
                    |> solve step
                    |> Tuple.mapSecond TextPlane.toString


-- load : Instance -> WFC pos size fmt item
-- load instance =
--     case instance of
--         Text wfc -> wfc


run : Random.Seed -> fmt -> WFC v fmt a -> fmt
run seed input (WFC wfc) = Tuple.second <| wfc ( Step 0 seed, input )
