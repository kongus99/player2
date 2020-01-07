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
import Json.Decode as Decode exposing (Decoder, int, list, nullable)
import RemoteData exposing (RemoteData(..), WebData)
import Video exposing (Video)
import Video.Add as Add


port sendUrl : String -> Cmd msg


videoUrl =
    "http://localhost:8080/video"


type alias Model =
    { add : Add.Model
    , videos : WebData (List Video)
    , selected : Maybe Video
    }


view : Model -> Html Msg
view model =
    div []
        [ ButtonGroup.buttonGroup []
            [ ButtonGroup.button [ Button.primary, Button.onClick Fetch ] [ text "Refresh" ]
            , Add.button Add
            ]
        , Add.modal Add model.add
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
            , Button.button [ Button.danger, Button.small, Button.onClick (Delete video) ] [ text "x" ]
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
    | Add Add.Msg
    | Select Video
    | Delete Video
    | Fetched (WebData (List Video))
    | NeedsUpdate (WebData (Maybe Int))


getVideos : Cmd Msg
getVideos =
    Http.get
        { url = videoUrl
        , expect =
            list Video.decode
                |> Http.expectJson (RemoteData.fromResult >> Fetched)
        }


postVideo : Video -> Cmd Msg
postVideo video =
    Http.post
        { url = videoUrl
        , body =
            Video.encode video
                |> Http.jsonBody
        , expect = Http.expectJson (RemoteData.fromResult >> NeedsUpdate) (nullable int)
        }


deleteVideo video =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = videoUrl ++ "/" ++ String.fromInt video.id
        , body = Http.emptyBody
        , expect = Http.expectJson (RemoteData.fromResult >> NeedsUpdate) (nullable int)
        , timeout = Nothing
        , tracker = Nothing
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fetch ->
            ( { model | videos = RemoteData.Loading }, getVideos )

        Select video ->
            ( { model | selected = Just video }, sendUrl video.videoUrl )

        Add m ->
            let
                ( addModel, newVideo ) =
                    Add.update m model.add
            in
            ( { model | add = addModel }, newVideo |> Maybe.map postVideo |> Maybe.withDefault Cmd.none )

        Delete video ->
            ( model, deleteVideo video )

        Fetched response ->
            ( { model | videos = response }, Cmd.none )

        NeedsUpdate _ ->
            ( model, getVideos )


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
      , add = Add.init
      , selected = Nothing
      }
    , getVideos
    )
