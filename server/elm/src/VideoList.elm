port module VideoList exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.ListGroup as ListGroup
import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, int, list, nullable, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import Video exposing (Video)
import Video.Add as Add


port sendUrl : String -> Cmd msg


videoUrl =
    "http://localhost:8080/video"


type alias Model =
    { add : Add.Model
    , videos : WebData (List Video)
    }


view : Model -> Html Msg
view model =
    div []
        [ ButtonGroup.buttonGroup []
            [ ButtonGroup.button [ Button.primary, Button.onClick Fetch ] [ text "Refresh" ]
            , ButtonGroup.button [ Button.primary, Button.onClick (Add Add.Open) ] [ text "Add" ]
            ]
        , Html.map (\m -> Add m) (Add.view model.add)
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
            viewVideos videos

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


viewVideos : List Video -> Html Msg
viewVideos videos =
    let
        singleVideo video =
            ListGroup.button [ ListGroup.attrs [ onClick (Play video) ] ]
                [ Grid.container []
                    [ Grid.row [ Row.centerMd ]
                        [ Grid.col [ Col.mdAuto ] [ text video.title ]
                        , Grid.colBreak []
                        , Grid.col [ Col.mdAuto ] [ Html.a [] [ text video.videoUrl ] ]
                        , Grid.colBreak []
                        ]
                    ]
                ]
    in
    div []
        [ h3 [] [ text "Video list" ]
        , ListGroup.custom (List.map singleVideo videos)
        ]


type Msg
    = Fetch
    | Add Add.Msg
    | Play Video
    | Fetched (WebData (List Video))
    | Created (WebData (Maybe Video))


getVideos : Cmd Msg
getVideos =
    Http.get
        { url = videoUrl
        , expect =
            list videoDecoder
                |> Http.expectJson (RemoteData.fromResult >> Fetched)
        }


postVideo : Video -> Cmd Msg
postVideo video =
    Http.post
        { url = videoUrl
        , body =
            Video.encode video
                |> Http.jsonBody
        , expect = nullable videoDecoder |> Http.expectJson (RemoteData.fromResult >> Created)
        }


videoDecoder : Decoder Video
videoDecoder =
    Decode.succeed Video
        |> required "id" int
        |> required "title" string
        |> required "videoUrl" string


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fetch ->
            ( { model | videos = RemoteData.Loading }, getVideos )

        Play video ->
            ( model, sendUrl video.videoUrl )

        Add m ->
            let
                ( addModel, newVideo ) =
                    Add.update m model.add
            in
            ( { model | add = addModel }, newVideo |> Maybe.map postVideo |> Maybe.withDefault Cmd.none )

        Fetched response ->
            ( { model | videos = response }, Cmd.none )

        Created _ ->
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
      }
    , getVideos
    )
