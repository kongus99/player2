port module VideoList exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup exposing (ButtonItem)
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Utilities.Flex as Flex
import Bootstrap.Utilities.Size as Size
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (..)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Http
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import Video exposing (Video)
import Video.Edit as Edit exposing (Msg(..))
import Video.Options as Options exposing (Options)


port sendUrlWithOptions : Encode.Value -> Cmd msg


port sendOptions : Options -> Cmd msg


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
            [ ListGroup.attrs [ href "#", Flex.col, Flex.alignItemsStart, onClick (Select video) ] ]

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
        , p [ Spacing.mb1 ] [ text video.videoUrl ]
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
    | VideoEnded String
    | Add Edit.Msg
    | Select Video
    | Edit Edit.Msg
    | Delete Video
    | Fetched (WebData (List Video))
    | NeedsUpdate (WebData (Maybe Int))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        sendEdit video method =
            video |> Maybe.map (method NeedsUpdate) |> Maybe.withDefault Cmd.none
    in
    case msg of
        Fetch ->
            ( { model | videos = RemoteData.Loading }, Video.get Fetched )

        Select video ->
            ( { model | selected = Just video }, Options.encodeWithUrl video.videoUrl model.options |> sendUrlWithOptions )

        Add m ->
            let
                ( newModel, video ) =
                    Edit.update m model.add
            in
            ( { model | add = newModel }, sendEdit video Video.post )

        Edit m ->
            let
                ( newModel, video ) =
                    Edit.update m model.edit
            in
            ( { model | edit = newModel }, sendEdit video Video.put )

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
            ( { model | options = newOptions }, sendOptions newOptions )

        VideoEnded string ->
            let
                x =
                    Debug.log "e" string
            in
            ( model, Cmd.none )


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
