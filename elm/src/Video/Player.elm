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
import RemoteData exposing (WebData)
import Video.Album as Album exposing (Album, Track, TrackTime, ending, isCurrentlyPlaying)
import Video.Options as Options exposing (Options)
import Video.Video exposing (Video, VideoData)


port videoTime : (( Float, Float ) -> msg) -> Sub msg


port changeTrack : Encode.Value -> Cmd msg


port sendUrlWithOptions : Encode.Value -> Cmd msg


subscriptions : Sub Msg
subscriptions =
    videoTime (\( now, length ) -> UpdateProgress { now = floor now, length = ceiling length })


type alias Selection =
    { video : VideoData
    , album : Maybe Album
    , trackTime : Maybe TrackTime
    }


type alias Model =
    Maybe Selection


type Msg
    = SelectVideo (Maybe VideoData) Options
    | UpdateProgress TrackTime
    | ToggleTrack Int
    | AlbumFetched (WebData (Maybe Album))
    | VideoStarted Int


init : Model
init =
    Nothing


getVideo : Model -> Maybe VideoData
getVideo =
    Maybe.map .video


encodeStart : Int -> Encode.Value
encodeStart start =
    Encode.int start


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( SelectVideo video options, _ ) ->
            video
                |> Maybe.map
                    (\v ->
                        ( Just (Selection v Nothing Nothing)
                        , [ Options.encodeWithUrl v options
                                |> sendUrlWithOptions
                          , Album.get v.id AlbumFetched
                          ]
                            |> Cmd.batch
                        )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        ( UpdateProgress trackTime, Just selection ) ->
            let
                cmd =
                    selection.album
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
            ( Just <| { selection | trackTime = Just trackTime }, cmd )

        ( ToggleTrack start, Just selection ) ->
            ( Just <| { selection | album = selection.album |> Maybe.map (Album.toggle start) }, Cmd.none )

        ( VideoStarted end, Just selection ) ->
            ( Just <| { selection | trackTime = Just <| TrackTime 0 end }, Cmd.none )

        ( AlbumFetched response, Just selection ) ->
            let
                album =
                    case response of
                        RemoteData.Success v ->
                            v

                        _ ->
                            Nothing
            in
            ( Just <| { selection | album = album }, Cmd.none )

        ( _, Nothing ) ->
            ( model, Cmd.none )


isActive : Model -> Int -> Bool
isActive player id =
    player |> Maybe.map (\m -> m.video.id == id) |> Maybe.withDefault False


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
        playerCard { trackTime, video, album } =
            let
                concat ( start, { title } ) =
                    ( start, " : " ++ title )

                ( trackStart, trackTitle ) =
                    Maybe.map2 (\p -> Album.playing p) trackTime album
                        |> Maybe.andThen identity
                        |> Maybe.map concat
                        |> Maybe.withDefault ( 0, "" )

                tracks =
                    Maybe.map2 (trackBars trackStart) trackTime album |> Maybe.withDefault []
            in
            Card.config [ Card.attrs [ style "width" "100%" ] ]
                |> Card.block []
                    [ Block.titleH4 [] [ text <| video.title ++ trackTitle ]
                    , Block.custom <| Progress.progressMulti <| tracks
                    ]
                |> Card.view
    in
    Maybe.map playerCard model |> Maybe.withDefault (div [] [])
