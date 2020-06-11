port module Main exposing (..)

import Browser
import Color exposing (Color)
import Color.Convert
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Json.Encode as Encode
import TypedSvg as Svg
import TypedSvg.Core exposing (Svg)
import TypedSvg.Attributes as Attributes exposing (y)
import TypedSvg.Types exposing (px, Paint(..))


port generateModel : { style : String, width : Float, height : Float } -> Cmd msg


port receiveModel : (Encode.Value -> msg) -> Sub msg


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { filters : List Filter
    , background : Color
    , style : Style
    , width : Float
    , height : Float
    }


decodeModel : Decoder Model
decodeModel =
    Field.require "filters" (Decode.list decodeFilter) <|
        \filters ->
            Field.require "background" decodeColor <|
                \background ->
                    Field.require "style" decodeStyle <|
                        \style ->
                            Field.require "width" Decode.float <|
                                \width ->
                                    Field.require "height" Decode.float <|
                                        \height ->
                                            Decode.succeed
                                                { filters = filters
                                                , background = background
                                                , style = style
                                                , width = width
                                                , height = height
                                                }


type alias Filter =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    , color : Color
    }


decodeFilter : Decoder Filter
decodeFilter =
    Field.require "x" Decode.float <|
        \x ->
            Field.require "y" Decode.float <|
                \y ->
                    Field.require "width" Decode.float <|
                        \width ->
                            Field.require "height" Decode.float <|
                                \height ->
                                    Field.require "color" decodeColor <|
                                        \color ->
                                            Decode.succeed
                                                { x = x
                                                , y = y
                                                , width = width
                                                , height = height
                                                , color = color
                                                }


decodeColor : Decoder Color
decodeColor =
    Decode.string
        |> Decode.andThen
            (\str ->
                case Color.Convert.hexToColor str of
                    Ok color ->
                        Decode.succeed color

                    Err err ->
                        Decode.fail err
            )


type Style
    = DefaultStyle
    | PastelStyle
    | SoftStyle
    | HardStyle
    | LightStyle
    | PaleStyle


encodeStyle : Style -> String
encodeStyle style =
    case style of
        DefaultStyle ->
            "default"

        PastelStyle ->
            "pastel"

        SoftStyle ->
            "soft"

        HardStyle ->
            "hard"

        LightStyle ->
            "light"

        PaleStyle ->
            "pale"


decodeStyle : Decoder Style
decodeStyle =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "pastel" ->
                        Decode.succeed PastelStyle

                    "soft" ->
                        Decode.succeed SoftStyle

                    "hard" ->
                        Decode.succeed HardStyle

                    "light" ->
                        Decode.succeed LightStyle

                    "pale" ->
                        Decode.succeed PaleStyle

                    "default" ->
                        Decode.succeed DefaultStyle

                    _ ->
                        Decode.fail "Invalid Style"
            )


init : () -> ( Model, Cmd Msg )
init _ =
    let
        model =
            { filters = []
            , style = DefaultStyle
            , background = Color.black
            , width = 600
            , height = 600
            }
    in
    ( model
    , generateModel
        { style =
            encodeStyle model.style
        , width =
            model.width
        , height =
            model.height
        }
    )


type Msg
    = ReceiveModel Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveModel modelValue ->
            ( Result.withDefault model <|
                Decode.decodeValue decodeModel modelValue
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    receiveModel ReceiveModel


view : Model -> Html Msg
view model =
    Svg.svg
        [ Attributes.width (px model.width)
        , Attributes.height (px model.height)
        , Attributes.viewBox 0 0 model.width model.height
        ]
        <| List.map viewFilter model.filters


viewFilter : Filter -> Svg Msg
viewFilter { x, y, width, height, color } =
    Svg.ellipse
        [ Attributes.cx <| px x
        , Attributes.cy <| px y
        , Attributes.rx <| px (width / 2)
        , Attributes.ry <| px (height / 2)
        , Attributes.fill <| Paint color
        ]
        []

