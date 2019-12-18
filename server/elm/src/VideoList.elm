port module VideoList exposing (..)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.ListGroup as ListGroup
import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, int, list, string)
import Json.Decode.Pipeline exposing (required)
import RemoteData exposing (RemoteData(..), WebData)


port sendUrl : String -> Cmd msg


videoUrl =
    "http://localhost:8080/video"


type alias Video =
    { id : Int
    , title : String
    , videoUrl : String
    }


type alias Model =
    { videos : WebData (List Video)
    }


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Fetch ]
            [ text "Get data from server" ]
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
    | Play Video
    | Received (WebData (List Video))


getVideos : Cmd Msg
getVideos =
    Http.get
        { url = videoUrl
        , expect =
            list videoDecoder
                |> Http.expectJson (RemoteData.fromResult >> Received)
        }


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

        Received response ->
            ( { model | videos = response }, Cmd.none )


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
      }
    , getVideos
    )
