module Example.Instance.Image.RenderHtml exposing (..)


import Html exposing (..)
import Html.Attributes exposing (..)

import Color exposing (Color)
import Color as Color exposing (..)
import Image exposing (Image)

import Example.Render as Render exposing (..)
import Example.Render.Spec exposing (HtmlSpec)
import Example.Render.Html.Grid as Render exposing (..)
import Example.Render.Html.Flat as Render exposing (..)

import Kvant.Vec2 exposing (..)
import Kvant.Matches as Matches exposing (..)
import Kvant.Plane exposing (Cell)
import Kvant.Plane.Impl.Tracing exposing (..)

import Example.Instance.Image.Plane exposing (merge, transparent)


pixel : Color -> Html msg
pixel c =
    span
        [ style "display" "inline-block"
        , style "width" "9px"
        , style "height" "9px"
        , style "background-color" <| Color.toCssString c
        ]
        [ ]


scaled : Float -> Color -> Html msg
scaled scale c =
    span
        [ style "transform" ("scale(" ++ String.fromFloat scale ++ ")")
        ]
        [ pixel c
        ]


spec : HtmlSpec Vec2 Color msg
spec =
    { default = transparent
    , contradiction = Color.purple
    , a = pixel
    , v = Render.coord
    , scaled = scaled
    , merge = merge
    , vToString = Render.coordText
    }