port module VideoList exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup exposing (ButtonItem)
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Utilities.Flex as Flex
import Bootstrap.Utilities.Size as Size
import Bootstrap.Utilities.Spacing as Spacing
import Extra
import Html exposing (..)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Http
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import Url
import Video exposing (Video)
import Video.Edit as Edit exposing (Msg(..), resetSubmitted)
import Video.Options as Options exposing (Options)


port sendUrlWithOptions : Encode.Value -> Cmd msg


port sendOptions : Encode.Value -> Cmd msg


port videoEnded : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    videoEnded VideoEnded


type alias Model =
    { add : Edit.Model
    , edit : Edit.Model
    , videos : WebData (List Video)
    , selected : Maybe Video
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
        , Edit.modal Add model.add
        , Edit.modal Edit model.edit
        , viewVideosOrError model
        ]


viewVideosOrError : Model -> Html Msg
viewVideosOrError model =
    case model.videos of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            h3 [] [ text "Loading..." ]

        RemoteData.Success videos ->
            viewVideos model.selected videos

        RemoteData.Failure httpError ->
            viewError (buildErrorMessage httpError)


getVideos model =
    case model.videos of
        RemoteData.Success videos ->
            videos

        _ ->
            []


viewError : String -> Html Msg
viewError errorMessage =
    let
        errorHeading =
            "Couldn't fetch videos at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]


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
            [ h5 [ Spacing.mb1 ] [ text video.title ]
            , ButtonGroup.buttonGroup []
                [ Edit.editButton video Edit
                , ButtonGroup.button [ Button.danger, Button.small, Button.onClick (Delete video) ] [ text "X" ]
                ]
            ]
        , p [ Spacing.mb1 ] [ text <| Url.toString video.videoUrl ]
        ]


viewVideos : Maybe Video -> List Video -> Html Msg
viewVideos selected videos =
    div []
        [ h3 [] [ text "Video list" ]
        , ListGroup.custom (List.map (singleVideo selected) videos)
        ]


type Msg
    = Fetch
    | Autoplay
    | Loop
    | Playlist
    | VideoEnded String
    | Add Edit.Msg
    | Select (Maybe Video)
    | Edit Edit.Msg
    | Delete Video
    | Fetched (WebData (List Video))
    | NeedsUpdate (WebData (Maybe Int))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        nextVideo next m =
            m.selected |> Maybe.andThen (\s -> next s <| getVideos m)
    in
    case msg of
        Fetch ->
            ( { model | videos = RemoteData.Loading }, Video.get Fetched )

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
            ( model, Video.delete NeedsUpdate video )

        Fetched response ->
            ( { model | videos = response }, Cmd.none )

        NeedsUpdate _ ->
            ( model, Video.get Fetched )

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


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
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


init : () -> ( Model, Cmd Msg )
init _ =
    ( { videos = RemoteData.NotAsked
      , add = Edit.init
      , edit = Edit.init
      , selected = Nothing
      , options = Options.init
      }
    , Video.get Fetched
    )
