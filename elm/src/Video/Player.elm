port module Video.Player exposing (..)

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Progress as Progress
import Bootstrap.Utilities.Spacing as Spacing
import Dict exposing (Dict)
import Extra
import Html exposing (text)
import Html.Attributes exposing (href, style)
import Html.Events exposing (onClick)
import Set exposing (Set)
import Video.Video exposing (Video)


port videoTime : (( Float, Float ) -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    videoTime (\( start, end ) -> UpdateProgress <| Just { start = start, end = end })


type alias Duration =
    { start : Float, end : Float }


type alias Track =
    { title : String
    , end : Float
    }


type alias Model =
    { video : Video
    , progress : Maybe Duration
    , selected : Set Float
    , allTracks : Dict Float Track
    }


type Msg
    = UpdateProgress (Maybe Duration)
    | ToggleTrack Float
    | VideoStarted Float


init : Video -> Model
init video =
    { video = video
    , progress = Nothing
    , selected = Set.empty
    , allTracks = Dict.empty
    }


update msg model =
    case msg of
        UpdateProgress progress ->
            { model | progress = progress }

        ToggleTrack start ->
            let
                selected =
                    if Set.member start model.selected then
                        Set.remove start model.selected

                    else
                        Set.insert start model.selected
            in
            { model | selected = selected }

        VideoStarted end ->
            let
                allTracks =
                    mock <| Duration 0 end

                selected =
                    allTracks |> Dict.keys |> Set.fromList
            in
            { model | progress = Just (Duration 0 end), allTracks = allTracks, selected = selected }


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
tracks { progress, selected, allTracks } =
    let
        bar index ( start, track ) =
            progress
                |> Maybe.map
                    (\p ->
                        let
                            length =
                                (track.end - start) / p.end * 100.0

                            color =
                                if selected |> Set.member start then
                                    Progress.success

                                else
                                    Progress.info

                            spacing =
                                if index == 0 then
                                    Spacing.ml0

                                else
                                    Spacing.ml1

                            attrs =
                                onClick (ToggleTrack start) :: spacing :: Extra.bottomTooltip track.title |> Progress.attrs
                        in
                        if p.start >= start && p.start < track.end then
                            [ color, Progress.value length, Progress.animated, attrs ]

                        else
                            [ color, Progress.value length, attrs ]
                    )
                |> Maybe.withDefault []
    in
    allTracks |> Dict.toList |> List.indexedMap bar


view : Model -> Html.Html Msg
view model =
    Card.config [ Card.attrs [ style "width" "100%" ] ]
        |> Card.block []
            [ Block.link [ href "#" ] [ text model.video.title ]
            , Block.custom <| Progress.progressMulti <| tracks model
            ]
        |> Card.view
