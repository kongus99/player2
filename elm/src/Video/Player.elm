port module Video.Player exposing (..)

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Progress as Progress
import Dict exposing (Dict)
import Extra
import Html exposing (text)
import Html.Attributes exposing (href, style)
import Html.Events exposing (onClick)
import Video.Options as Options exposing (Options)
import Video.Video exposing (Video)


port videoTime : (( Float, Float ) -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    videoTime (\( start, end ) -> UpdateProgress { start = start, end = end })


type alias Duration =
    { start : Float, end : Float }


type alias Track =
    { title : String
    , end : Float
    }


type alias Model =
    { video : Video
    , progress : Duration
    , selected : Dict Float Track
    , unselected : Dict Float Track
    }


type Msg
    = UpdateProgress Duration
    | ToggleTrack Float
    | VideoStarted Float


init : Video -> Model
init video =
    { video = video
    , progress = Duration 0 0
    , selected = Dict.empty
    , unselected = Dict.empty
    }


update msg model =
    case msg of
        UpdateProgress progress ->
            { model | progress = progress }

        ToggleTrack start ->
            model

        VideoStarted end ->
            { model | progress = Duration 0 end, selected = mock <| Duration 0 end }


mock : Duration -> Dict Float Track
mock progress =
    let
        starts =
            [ 0, progress.end / 4, progress.end / 2, 3 * progress.end / 4 ]

        ends =
            starts |> List.tail |> Maybe.withDefault [] |> List.reverse |> (::) progress.end |> List.reverse
    in
    List.map2 (\s -> \e -> ( s, Track (String.fromFloat s) e )) starts ends |> Dict.fromList


tracks : Model -> List (List (Progress.Option Msg))
tracks { progress, selected } =
    let
        bar index ( start, track ) =
            if progress.end > 0 then
                let
                    length =
                        (track.end - start) / progress.end * 100.0

                    color =
                        if modBy 2 index == 0 then
                            Progress.success

                        else
                            Progress.danger
                in
                if progress.start >= start && progress.start < track.end then
                    [ color, Progress.value length, Progress.animated, onClick (ToggleTrack start) :: Extra.bottomTooltip track.title |> Progress.attrs ]

                else
                    [ color, Progress.value length, onClick (ToggleTrack start) :: Extra.bottomTooltip track.title |> Progress.attrs ]

            else
                []
    in
    selected |> Dict.toList |> List.indexedMap bar


view : Model -> Html.Html Msg
view model =
    Card.config [ Card.attrs [ style "width" "100%" ] ]
        |> Card.block []
            [ Block.link [ href "#" ] [ text model.video.title ]
            , Block.custom <| Progress.progressMulti <| tracks model
            ]
        |> Card.view
