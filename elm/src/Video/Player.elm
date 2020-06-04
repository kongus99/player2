port module Video.Player exposing (..)

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Progress as Progress
import Bootstrap.Utilities.Spacing as Spacing
import Dict exposing (Dict)
import Extra
import Html exposing (div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Video.Album as Album exposing (Album, Track, TrackTime, ending, isCurrentlyPlaying)
import Video.Video exposing (Video, VideoData)


port videoTime : (( Float, Float ) -> msg) -> Sub msg


port changeTrack : Encode.Value -> Cmd msg


subscriptions : Sub Msg
subscriptions =
    videoTime (\( now, length ) -> UpdateProgress { now = floor now, length = ceiling length })


type Model
    = Unselected
    | Selected VideoData
    | Playing TrackTime VideoData


type Msg
    = UpdateProgress TrackTime
    | ToggleTrack Int
    | VideoStarted Int


init : Model
init =
    Unselected


select : Maybe VideoData -> Model
select =
    Maybe.map Selected >> Maybe.withDefault Unselected


getVideo : Model -> Maybe VideoData
getVideo model =
    case model of
        Unselected ->
            Nothing

        Selected v ->
            Just v

        Playing _ v ->
            Just v


encodeStart : Int -> Encode.Value
encodeStart start =
    Encode.int start


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case ( model, msg ) of
        ( Playing _ video, UpdateProgress trackTime ) ->
            let
                cmd =
                    video.album
                        |> Maybe.andThen (Album.playing trackTime)
                        |> Maybe.map
                            (\playing ->
                                if isCurrentlyPlaying trackTime playing then
                                    Cmd.none

                                else
                                    changeTrack <| encodeStart (Tuple.first playing)
                            )
                        |> Maybe.withDefault Cmd.none
            in
            ( Playing trackTime video, cmd )

        ( Playing trackTime video, ToggleTrack start ) ->
            ( Playing trackTime { video | album = video.album |> Maybe.map (Album.toggle start) }, Cmd.none )

        ( Selected video, ToggleTrack start ) ->
            ( Selected { video | album = video.album |> Maybe.map (Album.toggle start) }, Cmd.none )

        ( Selected video, VideoStarted end ) ->
            ( Playing (TrackTime 0 end) { video | album = Nothing }, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


isActive : Model -> Int -> Bool
isActive player id =
    case player of
        Unselected ->
            False

        Selected video ->
            video.id == id

        Playing _ video ->
            video.id == id


trackBars : Int -> TrackTime -> Album -> List (List (Progress.Option Msg))
trackBars playingStart trackTime album =
    let
        bar index ( start, track ) =
            let
                length =
                    (toFloat (ending trackTime track) - toFloat start) / toFloat trackTime.length * 100.0

                color =
                    if Album.active start album then
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
            if playingStart == start then
                [ color, Progress.value length, Progress.animated, attrs ]

            else
                [ color, Progress.value length, attrs ]
    in
    album.tracks |> Dict.toList |> List.indexedMap bar


view : Model -> Html.Html Msg
view model =
    let
        playerCard trackTime video =
            let
                concat ( start, { title } ) =
                    ( start, " : " ++ title )

                ( trackStart, trackTitle ) =
                    Maybe.map2 (\p -> Album.playing p) trackTime video.album
                        |> Maybe.andThen identity
                        |> Maybe.map concat
                        |> Maybe.withDefault ( 0, "" )

                tracks =
                    Maybe.map2 (trackBars trackStart) trackTime video.album |> Maybe.withDefault []
            in
            Card.config [ Card.attrs [ style "width" "100%" ] ]
                |> Card.block []
                    [ Block.titleH4 [] [ text <| video.title ++ trackTitle ]
                    , Block.custom <| Progress.progressMulti <| tracks
                    ]
                |> Card.view
    in
    case model of
        Unselected ->
            div [] []

        Selected video ->
            playerCard Nothing video

        Playing trackTime video ->
            playerCard (Just trackTime) video
