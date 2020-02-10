port module Video.List exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup exposing (ButtonItem)
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Utilities.Flex as Flex
import Bootstrap.Utilities.Size as Size
import Bootstrap.Utilities.Spacing as Spacing
import Extra
import Html exposing (..)
import Html.Attributes exposing (attribute, href)
import Html.Events exposing (onClick)
import Http
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import TextFilter exposing (TextFilter)
import Url
import Video.Edit as Edit exposing (Msg(..), resetSubmitted)
import Video.Options as Options exposing (Options)
import Video.Video as Video exposing (Video)


port sendUrlWithOptions : Encode.Value -> Cmd msg


port sendOptions : Encode.Value -> Cmd msg


port videoEnded : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    videoEnded VideoEnded


type alias Model =
    { add : Edit.Model
    , edit : Edit.Model
    , originalVideos : List Video
    , filteredVideos : List Video
    , selected : Maybe Video
    , filter : TextFilter
    , options : Options
    }


view : Model -> Html Msg
view model =
    div []
        [ ButtonGroup.toolbar []
            [ ButtonGroup.buttonGroupItem [] [ Edit.addButton Add ]
            , ButtonGroup.checkboxButtonGroupItem [ ButtonGroup.attrs [ Spacing.ml1 ] ]
                [ ButtonGroup.checkboxButton model.options.play [ Button.info, Button.onClick Autoplay ] [ text "Autoplay" ]
                , ButtonGroup.checkboxButton model.options.loop [ Button.info, Button.onClick Loop ] [ text "Loop" ]
                , ButtonGroup.checkboxButton model.options.playlist [ Button.info, Button.onClick Playlist ] [ text "Playlist" ]
                ]
            ]
        , TextFilter.input Filter model.filter
        , Edit.modal Add model.add
        , Edit.modal Edit model.edit
        , viewVideos model
        ]


resolveFetch : WebData a -> a -> a
resolveFetch response default =
    let
        resolveError : Http.Error -> String
        resolveError httpError =
            case httpError of
                Http.BadUrl message ->
                    message

                Http.Timeout ->
                    "Server is taking too long to respond. Please try again later."

                Http.NetworkError ->
                    "Unable to reach server."

                Http.BadStatus statusCode ->
                    "Request failed with status code: " ++ String.fromInt statusCode

                Http.BadBody message ->
                    message
    in
    case response of
        RemoteData.NotAsked ->
            default

        RemoteData.Loading ->
            default

        RemoteData.Success videos ->
            videos

        RemoteData.Failure httpError ->
            --let
            --    _ =
            --        Debug.log "Received error" (resolveError httpError)
            --in
            default


singleVideo : Maybe Video -> Video -> ListGroup.CustomItem Msg
singleVideo selected video =
    let
        defaultAttributes =
            [ ListGroup.attrs [ href "#", Flex.col, Flex.alignItemsStart, onClick (Select (Just video)) ] ]

        isActive =
            selected |> Maybe.map (\s -> s.id == video.id) |> Maybe.withDefault False

        attributes =
            if isActive then
                ListGroup.active :: defaultAttributes

            else
                defaultAttributes
    in
    ListGroup.anchor
        attributes
        [ div [ Flex.block, Flex.justifyBetween, Size.w100 ]
            [ h5
                [ Spacing.mb1
                , attribute "data-toggle" "tooltip"
                , attribute "data-placement" "bottom"
                , attribute "title" (Url.toString video.videoUrl)
                ]
                [ text video.title ]
            , ButtonGroup.buttonGroup []
                [ Edit.editButton video Edit
                , ButtonGroup.button [ Button.danger, Button.small, Button.onClick (Delete video) ] [ text "X" ]
                ]
            ]
        ]


viewVideos : Model -> Html Msg
viewVideos model =
    div []
        [ h3 [] [ text "Video list" ]
        , ListGroup.custom (List.map (singleVideo model.selected) model.filteredVideos)
        ]


type Msg
    = Autoplay
    | Loop
    | Playlist
    | VideoEnded String
    | Filter String
    | Select (Maybe Video)
    | Add Edit.Msg
    | Edit Edit.Msg
    | Delete Video
    | Fetch
    | Fetched (WebData (List Video))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        nextVideo next m =
            m.selected |> Maybe.andThen (\s -> next s <| m.filteredVideos)
    in
    case msg of
        Fetch ->
            ( { model | originalVideos = [], filteredVideos = [] }, Video.get Fetched )

        Select video ->
            ( { model | selected = video }
            , video
                |> Maybe.map (\v -> Options.encodeWithUrl (Url.toString v.videoUrl) model.options |> sendUrlWithOptions)
                |> Maybe.withDefault Cmd.none
            )

        Add m ->
            let
                ( newModel, cmd ) =
                    Edit.update m model.add
            in
            if newModel.submitted then
                ( { model | add = newModel |> resetSubmitted }, Video.get Fetched )

            else
                ( { model | add = newModel }, Cmd.map Add cmd )

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
            let
                videos =
                    resolveFetch response []

                filtered =
                    videos |> List.filter (\v -> TextFilter.apply model.filter v.title)
            in
            ( { model | originalVideos = videos, filteredVideos = filtered }, Cmd.none )

        Autoplay ->
            ( { model | options = Options.togglePlay model.options }, Cmd.none )

        Loop ->
            let
                newOptions =
                    Options.toggleLoop model.options
            in
            ( { model | options = newOptions }, Options.encode newOptions |> sendOptions )

        VideoEnded _ ->
            case ( model.options.playlist, model.options.loop ) of
                ( True, True ) ->
                    update (Select <| nextVideo Extra.cyclicNext model) model

                ( True, False ) ->
                    update (Select <| nextVideo Extra.next model) model

                _ ->
                    ( model, Cmd.none )

        Playlist ->
            ( { model | options = Options.togglePlaylist model.options }, Cmd.none )

        Filter string ->
            let
                filter =
                    TextFilter.parse string
            in
            ( { model
                | filter = filter
                , filteredVideos =
                    model.originalVideos |> List.filter (\v -> TextFilter.apply filter v.title)
              }
            , Cmd.none
            )


init : ( Model, Cmd Msg )
init =
    ( { originalVideos = []
      , filteredVideos = []
      , add = Edit.init
      , edit = Edit.init
      , selected = Nothing
      , filter = TextFilter.empty
      , options = Options.init
      }
    , Video.get Fetched
    )
