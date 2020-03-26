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
import Video.Login as Login
import Video.Options as Options exposing (Option(..), Options)
import Video.Video as Video exposing (Video)


port sendUrlWithOptions : Encode.Value -> Cmd msg


port videoEnded : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    videoEnded VideoEnded


type alias Model =
    { edit : Edit.Model
    , originalVideos : List Video
    , filteredVideos : List Video
    , selected : Maybe Video
    }


view : Login.Model -> Model -> Html Msg
view login model =
    div []
        [ Edit.modal Edit model.edit
        , ListGroup.custom (List.map (singleVideo model.selected login) model.filteredVideos)
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


singleVideo : Maybe Video -> Login.Model -> Video -> ListGroup.CustomItem Msg
singleVideo selected login video =
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
                , attribute "title" (video.videoId |> Video.toUrl |> Maybe.map Url.toString |> Maybe.withDefault "Incorrect url")
                ]
                [ text video.title ]
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
    = VideoEnded String
    | Select (Maybe Video)
    | Edit Edit.Msg
    | Delete Video
    | Fetch
    | Fetched (WebData (List Video))


update filter options msg model =
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

        VideoEnded _ ->
            case ( Options.active Playlist options, Options.active Loop options ) of
                ( True, True ) ->
                    update filter options (Select <| nextVideo Extra.cyclicNext model) model

                ( True, False ) ->
                    update filter options (Select <| nextVideo Extra.next model) model

                _ ->
                    ( model, Cmd.none )


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
      , selected = Nothing
      }
    , Video.get Fetched
    )
