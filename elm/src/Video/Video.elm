module Video.Video exposing (Video, delete, get, post, put)

import Http
import Json.Decode as Decode exposing (Decoder, int, list, nullable)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import Url exposing (Url)


type alias Video =
    { id : Maybe Int
    , title : String
    , videoUrl : Url
    }


url =
    "/api/video"


get : (WebData (List Video) -> msg) -> Cmd msg
get msg =
    Http.get
        { url = url
        , expect =
            list decode
                |> Decode.map (List.filterMap identity)
                |> Http.expectJson (RemoteData.fromResult >> msg)
        }


post : (WebData (Maybe Int) -> c) -> Video -> Cmd c
post msg video =
    Http.post
        { url = url
        , body =
            encode video
                |> Http.jsonBody
        , expect = Http.expectJson (RemoteData.fromResult >> msg) (nullable int)
        }


delete : c -> Video -> Cmd c
delete msg video =
    video.id
        |> Maybe.map
            (\id ->
                Http.request
                    { method = "DELETE"
                    , headers = []
                    , url = url ++ "/" ++ String.fromInt id
                    , body = Http.emptyBody
                    , expect = Http.expectJson (RemoteData.fromResult >> (\_ -> msg)) (nullable int)
                    , timeout = Nothing
                    , tracker = Nothing
                    }
            )
        |> Maybe.withDefault Cmd.none


put : (WebData (Maybe Int) -> c) -> Video -> Cmd c
put msg video =
    Http.request
        { method = "PUT"
        , headers = []
        , url = url
        , body =
            encode video
                |> Http.jsonBody
        , expect = Http.expectJson (RemoteData.fromResult >> msg) (nullable int)
        , timeout = Nothing
        , tracker = Nothing
        }


encode : Video -> Encode.Value
encode video =
    Encode.object
        [ ( "id", Encode.int (Maybe.withDefault -1 video.id) )
        , ( "title", Encode.string video.title )
        , ( "videoUrl", Encode.string (Url.toString video.videoUrl) )
        ]


decode : Decoder (Maybe Video)
decode =
    let
        toVideo id name videoUrl =
            videoUrl |> Maybe.map (\u -> Video id name u)
    in
    Decode.succeed toVideo
        |> required "id" (Decode.map Just Decode.int)
        |> required "title" Decode.string
        |> required "videoUrl" (Decode.map Url.fromString Decode.string)
