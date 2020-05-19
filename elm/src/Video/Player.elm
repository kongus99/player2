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
import Json.Encode as Encode
import Video.Album as Album exposing (Album, Track)
import Video.Video exposing (Video)


port videoTime : (( Float, Float ) -> msg) -> Sub msg


port changeTrack : Encode.Value -> Cmd msg


subscriptions : Sub Msg
subscriptions =
    videoTime (\( start, end ) -> UpdateProgress <| Just { start = start, end = end })


type alias Duration =
    { start : Float, end : Float }


type alias Model =
    { progress : Maybe Duration
    , album : Album
    }


type Msg
    = UpdateProgress (Maybe Duration)
    | ToggleTrack Float
    | VideoStarted Float


init : Video -> Model
init video =
    { progress = Nothing
    , album = Album.init video
    }


encodeStart : Float -> Encode.Value
encodeStart start =
    Encode.float start


update : Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update msg mm =
    mm
        |> Maybe.map
            (\model ->
                case msg of
                    UpdateProgress p ->
                        p
                            |> Maybe.map
                                (\progress ->
                                    let
                                        isCorrectTrack ( start, { end } ) =
                                            progress.start >= start && progress.start < end

                                        cmd =
                                            Album.playing progress.start model.album
                                                |> Maybe.map
                                                    (\playing ->
                                                        if isCorrectTrack playing then
                                                            Cmd.none

                                                        else
                                                            changeTrack <| encodeStart (Tuple.first playing)
                                                    )
                                                |> Maybe.withDefault Cmd.none
                                    in
                                    ( Just { model | progress = p }, cmd )
                                )
                            |> Maybe.withDefault ( mm, Cmd.none )

                    ToggleTrack start ->
                        ( Just { model | album = Album.toggle start model.album }, Cmd.none )

                    VideoStarted end ->
                        ( Just { model | progress = Just (Duration 0 end), album = Album.mock model.album end }, Cmd.none )
            )
        |> Maybe.withDefault ( mm, Cmd.none )


trackBars : Model -> List (List (Progress.Option Msg))
trackBars m =
    let
        playing =
            m.progress
                |> Maybe.andThen (\p -> Album.playing p.start m.album)
                |> Maybe.map Tuple.first

        isPlaying start =
            playing |> Maybe.map (\p -> p == start) |> Maybe.withDefault False

        bar index ( start, { title, end } ) =
            m.progress
                |> Maybe.map
                    (\p ->
                        let
                            length =
                                (end - start) / p.end * 100.0

                            color =
                                if Album.active start m.album then
                                    Progress.success

                                else
                                    Progress.info

                            spacing =
                                if index == 0 then
                                    Spacing.ml0

                                else
                                    Spacing.ml1

                            attrs =
                                onClick (ToggleTrack start) :: spacing :: Extra.bottomTooltip title |> Progress.attrs
                        in
                        if isPlaying start then
                            [ color, Progress.value length, Progress.animated, attrs ]

                        else
                            [ color, Progress.value length, attrs ]
                    )
                |> Maybe.withDefault []
    in
    m.album.tracks |> Dict.toList |> List.indexedMap bar


view : Model -> Html.Html Msg
view model =
    Card.config [ Card.attrs [ style "width" "100%" ] ]
        |> Card.block []
            [ Block.link [ href "#" ] [ text model.album.video.title ]
            , Block.custom <| Progress.progressMulti <| trackBars model
            ]
        |> Card.view
