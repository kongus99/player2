port module Video.Player exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Progress as Progress
import Bootstrap.Utilities.Flex as Flex
import Bootstrap.Utilities.Size as Size
import Bootstrap.Utilities.Spacing as Spacing
import Dict exposing (Dict)
import Extra
import Html exposing (Html, div, h5, text)
import Html.Attributes exposing (href, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Login.Login as Login
import RemoteData exposing (WebData)
import Url
import Video.Album as Album exposing (Album, Track, TrackData, TrackTime, ending, isCurrentlyPlaying, tracksData)
import Video.Edit as Edit exposing (Msg(..))
import Video.Options as Options exposing (Options)
import Video.Video as Video exposing (Video, VideoData)


port videoStatus : (( String, Float ) -> msg) -> Sub msg


port videoTime : (( Float, Float ) -> msg) -> Sub msg


port changeTrack : Encode.Value -> Cmd msg


port sendUrlWithOptions : Encode.Value -> Cmd msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ videoStatus (\( s, f ) -> VideoStatus ( s, ceiling f ))
        , videoTime (\( now, length ) -> UpdateProgress { now = floor now, length = ceiling length })
        ]


type Status
    = Playing (Maybe TrackData) TrackTime
    | Paused (Maybe TrackData) TrackTime
    | Ended


type alias Player =
    { description : String
    , id : Maybe Int
    , album : Album
    , status : Status
    }


type alias Model =
    { player : Player
    , include : Bool
    , playlist : List VideoData
    , options : Options
    , edit : Edit.Model
    }


defaultDescription =
    "Please select video to play"


init : Options -> List VideoData -> Model
init options filtered =
    { player = Player defaultDescription Nothing Album.init Ended
    , include = False
    , playlist = filtered
    , edit = Edit.init
    , options = options
    }


type Msg
    = VideoStatus ( String, Int )
    | UpdateProgress TrackTime
    | Select VideoData
    | Delete Int
    | Edit Edit.Msg
    | ToggleAll Bool
    | ToggleTrack Int
    | AlbumFetched (WebData (Maybe Album))


encodeStart : Int -> Encode.Value
encodeStart start =
    Encode.int start


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateStatus s m =
            let
                oldPlayer =
                    m.player
            in
            { m | player = { oldPlayer | status = s } }

        updateAlbum f m =
            let
                oldPlayer =
                    m.player
            in
            { m | player = { oldPlayer | album = f oldPlayer.album } }
    in
    case msg of
        VideoStatus ( status, time ) ->
            case status of
                "ended" ->
                    ( updateStatus Ended model, Cmd.none )

                _ ->
                    ( updateStatus (Playing Nothing (TrackTime 0 time)) model, Cmd.none )

        UpdateProgress trackTime ->
            let
                trackData =
                    Album.playing trackTime model.player.album

                cmd =
                    trackData
                        |> Maybe.map
                            (\playing ->
                                if isCurrentlyPlaying trackTime playing then
                                    Cmd.none

                                else
                                    changeTrack <| encodeStart playing.start
                            )
                        |> Maybe.withDefault Cmd.none
            in
            ( updateStatus (Playing trackData trackTime) model, cmd )

        Select v ->
            ( { model | player = Player v.title (Just v.id) Album.init Ended }
            , [ Options.encodeWithUrl v model.options |> sendUrlWithOptions, Album.get v.id AlbumFetched ] |> Cmd.batch
            )

        Delete _ ->
            ( model, Cmd.none )

        Edit m ->
            let
                refresh =
                    case m of
                        Close ->
                            model.player.id
                                |> Maybe.map (\id -> Album.get id AlbumFetched)
                                |> Maybe.withDefault Cmd.none

                        _ ->
                            Cmd.none

                ( newModel, cmd ) =
                    Edit.update m model.edit
            in
            ( { model | edit = newModel }, [ Cmd.map Edit cmd, refresh ] |> Cmd.batch )

        ToggleAll include ->
            ( updateAlbum (Album.toggleAll include) { model | include = not include }, Cmd.none )

        ToggleTrack start ->
            ( updateAlbum (Album.toggle start) model, Cmd.none )

        AlbumFetched response ->
            let
                album =
                    case response of
                        RemoteData.Success v ->
                            v

                        _ ->
                            Nothing
            in
            ( album |> Maybe.map (\a -> updateAlbum (\_ -> a) model) |> Maybe.withDefault model, Cmd.none )


currentTrackData status =
    case status of
        Ended ->
            Nothing

        Playing td _ ->
            td

        Paused td _ ->
            td


trackBars : Player -> List (Maybe (Block.Item Msg))
trackBars { album, status } =
    let
        trackTime : Maybe TrackTime
        trackTime =
            case status of
                Ended ->
                    Nothing

                Playing _ tt ->
                    Just tt

                Paused _ tt ->
                    Just tt

        progress length =
            Progress.progress [ Progress.success, Progress.value length, Progress.animated ]

        videoProgress time =
            toFloat time.now / toFloat time.length * 100.0 |> progress

        trackProgress track time =
            (toFloat time.now - toFloat track.start) / (toFloat track.end - toFloat track.start) * 100.0 |> progress

        trackEntry : TrackTime -> TrackData -> ListGroup.CustomItem Msg
        trackEntry time track =
            let
                color =
                    if isCurrentlyPlaying time track then
                        ListGroup.success

                    else if track.isActive then
                        ListGroup.info

                    else
                        ListGroup.danger

                attrs =
                    onClick (ToggleTrack track.start) :: Extra.bottomTooltip track.title |> ListGroup.attrs
            in
            ListGroup.anchor [ color, attrs ] [ text track.title ]
    in
    [ trackTime |> Maybe.map (videoProgress >> Block.custom)
    , Maybe.map2 (\tt -> \td -> trackProgress td tt |> Block.custom) trackTime (currentTrackData status)
    , trackTime |> Maybe.map (\tt -> tracksData album tt |> List.map (trackEntry tt) |> ListGroup.custom |> Block.custom)
    ]


playerCard : Login.Model -> Model -> Html.Html Msg
playerCard login { player, include, playlist } =
    let
        description =
            player.id
                |> Maybe.andThen (\id -> playlist |> List.filter (\v -> v.id == id) |> List.head)
                |> Maybe.map .title
                |> Maybe.map
                    (\prefix ->
                        player.status
                            |> currentTrackData
                            |> Maybe.map (\td -> prefix ++ " : " ++ td.title)
                            |> Maybe.withDefault prefix
                    )
                |> Maybe.withDefault defaultDescription

        extraBlocks : List (Maybe (Block.Item Msg))
        extraBlocks =
            trackBars player

        --, Block.custom <|
        --    ButtonGroup.buttonGroup []
        --        (ButtonGroup.button [ Button.info, Button.small, Button.onClick <| ToggleAll include ] [ text "Toggle" ]
        --            :: Login.restrict []
        --                [ Edit.editButton player.id Edit
        --
        --                --, ButtonGroup.button [ Button.danger, Button.small, Button.onClick (Delete video) ] [ text "X" ]
        --                ]
        --                login
        --        )
    in
    Card.config [ Card.attrs [ style "width" "100%" ] ]
        |> Card.block [] (Block.titleH4 [] [ text description ] :: (extraBlocks |> List.filterMap identity))
        |> Card.view


view : Login.Model -> Model -> Html Msg
view login model =
    let
        isActive : Int -> Bool
        isActive id =
            model.player.id |> Maybe.map (\pid -> pid == id) |> Maybe.withDefault False

        singleVideo : VideoData -> ListGroup.CustomItem Msg
        singleVideo video =
            let
                defaultAttributes =
                    [ ListGroup.attrs
                        [ href "#", Flex.col, Flex.alignItemsStart, onClick (Select video) ]
                    ]

                attributes =
                    if isActive video.id then
                        ListGroup.active :: defaultAttributes

                    else
                        defaultAttributes

                tooltipText =
                    video.videoId |> Video.toUrl |> Maybe.map Url.toString |> Maybe.withDefault "Incorrect url"
            in
            ListGroup.anchor
                attributes
                [ div [ Flex.block, Flex.justifyBetween, Size.w100 ]
                    [ h5 (Spacing.mb1 :: Extra.bottomTooltip tooltipText) [ text video.title ]
                    ]
                ]
    in
    div []
        [ Edit.view Edit model.edit
        , playerCard login model
        , ListGroup.custom (List.map singleVideo model.playlist)
        ]



--VideoStatus ( status, time ) ->
--    if status == "ended" then
--        case ( Options.active Playlist options, Options.active Loop options ) of
--            ( True, True ) ->
--                update filter options (Select <| nextVideo Extra.cyclicNext) model
--
--            ( True, False ) ->
--                update filter options (Select <| nextVideo Extra.next) model
--
--            _ ->
--                ( model, Cmd.none )
--
--    else
--        let
--            ( player, cmd ) =
--                Player.update (VideoStarted time) model.player
--        in
--        ( { model | player = player }, Cmd.map PlayerUpdate cmd )
--nextVideo : (VideoData -> List VideoData -> Maybe VideoData) -> Maybe VideoData
--nextVideo next =
--    model.player |> Player.getVideo |> Maybe.andThen (\c -> next c model.filteredVideos)
