port module Video.List exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Utilities.Flex as Flex
import Bootstrap.Utilities.Size as Size
import Bootstrap.Utilities.Spacing as Spacing
import Extra exposing (resolveFetch)
import Html exposing (..)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Login.Login as Login
import RemoteData exposing (RemoteData(..), WebData)
import TextFilter exposing (TextFilter)
import Url
import Video.Edit as Edit exposing (Msg(..))
import Video.Options as Options exposing (Option(..), Options)
import Video.Player as Player exposing (Msg(..))
import Video.Video as Video exposing (Video, VideoData)


port videoStatus : (( String, Float ) -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch [ videoStatus (\( s, f ) -> VideoStatus ( s, ceiling f )), Player.subscriptions |> Sub.map PlayerUpdate ]


type alias Model =
    { edit : Edit.Model
    , originalVideos : List VideoData
    , filteredVideos : List VideoData
    , player : Player.Model
    }


view : Login.Model -> Model -> Html Msg
view login model =
    div []
        [ Edit.view Edit model.edit
        , Player.view model.player |> Html.map PlayerUpdate
        , ListGroup.custom (List.map (singleVideo model.player login) model.filteredVideos)
        ]


singleVideo : Player.Model -> Login.Model -> VideoData -> ListGroup.CustomItem Msg
singleVideo player login video =
    let
        defaultAttributes =
            [ ListGroup.attrs [ href "#", Flex.col, Flex.alignItemsStart, onClick (Select (Just video)) ] ]

        attributes =
            if Player.isActive player video.id then
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
            , Login.restrictHtml
                (ButtonGroup.buttonGroup []
                    [ Edit.editButton video Edit
                    , ButtonGroup.button [ Button.danger, Button.small, Button.onClick (Delete video) ] [ text "X" ]
                    ]
                )
                login
            ]
        ]


type Msg
    = VideoStatus ( String, Int )
    | PlayerUpdate Player.Msg
    | Select (Maybe VideoData)
    | Edit Edit.Msg
    | Delete VideoData
    | Fetch
    | Fetched (WebData (List VideoData))


update : TextFilter -> Options -> Msg -> Model -> ( Model, Cmd Msg )
update filter options msg model =
    let
        nextVideo : (VideoData -> List VideoData -> Maybe VideoData) -> Maybe VideoData
        nextVideo next =
            model.player |> Player.getVideo |> Maybe.andThen (\c -> next c model.filteredVideos)
    in
    case msg of
        Fetch ->
            ( { model | originalVideos = [], filteredVideos = [] }, Video.getAll Fetched )

        Select video ->
            update filter options (PlayerUpdate (SelectVideo video options)) model

        Edit m ->
            let
                ( newModel, cmd ) =
                    Edit.update m model.edit
            in
            ( { model | edit = newModel }, Cmd.map Edit cmd )

        Delete video ->
            ( model, Video.delete Fetch video )

        Fetched response ->
            ( { model | originalVideos = resolveFetch response [] } |> filterList filter, Cmd.none )

        VideoStatus ( status, time ) ->
            if status == "ended" then
                case ( Options.active Playlist options, Options.active Loop options ) of
                    ( True, True ) ->
                        update filter options (Select <| nextVideo Extra.cyclicNext) model

                    ( True, False ) ->
                        update filter options (Select <| nextVideo Extra.next) model

                    _ ->
                        ( model, Cmd.none )

            else
                let
                    ( player, cmd ) =
                        Player.update (VideoStarted time) model.player
                in
                ( { model | player = player }, Cmd.map PlayerUpdate cmd )

        PlayerUpdate m ->
            let
                ( player, cmd ) =
                    Player.update m model.player
            in
            ( { model | player = player }, Cmd.map PlayerUpdate cmd )


filterList filter model =
    { model
        | filteredVideos =
            model.originalVideos |> List.filter (\v -> TextFilter.apply filter v.title)
    }


init : ( Model, Cmd Msg )
init =
    ( { originalVideos = []
      , filteredVideos = []
      , edit = Edit.init
      , player = Player.init
      }
    , Video.getAll Fetched
    )
