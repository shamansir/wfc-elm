module Render.Example.Text exposing (..)

import Render.Example exposing (TextExample, Status(..))
import Render.Example as Example exposing (make)


import WFC.Vec2 exposing (..)
import WFC.Plane exposing (Cell, N(..))
import WFC.Plane.Flat exposing (Boundary(..), Symmetry(..))
import WFC.Core as WFC exposing (..)
import WFC.Solver exposing (Approach(..))
import WFC.Solver as WFC exposing (Step(..), Options)
import WFC.Plane.Impl.Text as TextPlane exposing (make)


options : WFC.Options Vec2 Char
options =
    { approach =
        Overlapping
            { searchBoundary = Bounded -- Periodic
            , patternSize = N ( 2, 2 )
            , symmetry = FlipAndRotate
            }
    , outputSize = ( 10, 10 )
    , outputBoundary = Bounded
    -- , advanceRule = WFC.MaximumAttempts 50
    , advanceRule = WFC.AdvanceManually
    }


quick : String -> Vec2 -> TextExample
quick src size =
    let
        boundedSrc
            = (size, src)
    in
        Example.make
            (WFC.text options boundedSrc)
            (WFC.textTracing options boundedSrc)
            options
            boundedSrc
            (TextPlane.make size src)