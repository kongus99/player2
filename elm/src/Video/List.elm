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
import Video.Edit as Edit exposing (Msg(..), resetSubmitted)
import Video.Options as Options exposing (Option(..), Options)
import Video.Player as Player exposing (Msg(..))
import Video.Video as Video exposing (Video)


port sendUrlWithOptions : Encode.Value -> Cmd msg


port videoStatus : (( String, Float ) -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch [ videoStatus VideoStatus, Player.subscriptions |> Sub.map PlayerUpdate ]


type alias Model =
    { edit : Edit.Model
    , originalVideos : List Video
    , filteredVideos : List Video
    , player : Maybe Player.Model
    }


view : Login.Model -> Model -> Html Msg
view login model =
    div []
        [ Edit.modal Edit model.edit
        , model.player |> Maybe.map Player.view |> Maybe.withDefault (div [] []) |> Html.map PlayerUpdate
        , ListGroup.custom (List.map (singleVideo model.player login) model.filteredVideos)
        ]


singleVideo : Maybe Player.Model -> Login.Model -> Video -> ListGroup.CustomItem Msg
singleVideo player login video =
    let
        defaultAttributes =
            [ ListGroup.attrs [ href "#", Flex.col, Flex.alignItemsStart, onClick (Select (Just video)) ] ]

        isActive =
            player |> Maybe.map (\p -> p.video.id == video.id) |> Maybe.withDefault False

        attributes =
            if isActive then
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
    = VideoStatus ( String, Float )
    | PlayerUpdate Player.Msg
    | Select (Maybe Video)
    | Edit Edit.Msg
    | Delete Video
    | Fetch
    | Fetched (WebData (List Video))


update : TextFilter -> Options -> Msg -> Model -> ( Model, Cmd Msg )
update filter options msg model =
    let
        nextVideo next m =
            m.player |> Maybe.andThen (\s -> next s.video <| m.filteredVideos)
    in
    case msg of
        Fetch ->
            ( { model | originalVideos = [], filteredVideos = [] }, Video.get Fetched )

        Select video ->
            ( { model | player = Maybe.map Player.init video }
            , video
                |> Maybe.map (\v -> Options.encodeWithUrl v options |> sendUrlWithOptions)
                |> Maybe.withDefault Cmd.none
            )

        Edit m ->
            let
                ( newModel, cmd ) =
                    Edit.update m model.edit
            in
            if newModel.submitted then
                ( { model | edit = newModel |> resetSubmitted }, Video.get Fetched )

            else
                ( { model | edit = newModel }, Cmd.map Edit cmd )

        Delete video ->
            ( model, Video.delete Fetch video )

        Fetched response ->
            ( { model | originalVideos = resolveFetch response [] } |> filterList filter, Cmd.none )

        VideoStatus ( status, time ) ->
            if status == "ended" then
                case ( Options.active Playlist options, Options.active Loop options ) of
                    ( True, True ) ->
                        update filter options (Select <| nextVideo Extra.cyclicNext model) model

                    ( True, False ) ->
                        update filter options (Select <| nextVideo Extra.next model) model

                    _ ->
                        ( model, Cmd.none )

            else
                ( { model | player = Maybe.map (Player.update <| VideoStarted time) model.player }, Cmd.none )

        PlayerUpdate m ->
            ( { model | player = Maybe.map (\p -> Player.update m p) model.player }, Cmd.none )


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
      , player = Nothing
      }
    , Video.get Fetched
    )
