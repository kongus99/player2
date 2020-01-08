module Video exposing (Video, delete, get, post, put)

import Http
import Json.Decode as Decode exposing (Decoder, int, list, nullable)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)


type alias Video =
    { id : Int
    , title : String
    , videoUrl : String
    }


url =
    "http://localhost:8080/video"


get : (WebData (List Video) -> msg) -> Cmd msg
get msg =
    Http.get
        { url = url
        , expect = list decode |> Http.expectJson (RemoteData.fromResult >> msg)
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


delete : (WebData (Maybe Int) -> c) -> Video -> Cmd c
delete msg video =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = url ++ "/" ++ String.fromInt video.id
        , body = Http.emptyBody
        , expect = Http.expectJson (RemoteData.fromResult >> msg) (nullable int)
        , timeout = Nothing
        , tracker = Nothing
        }


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
        [ ( "id", Encode.int video.id )
        , ( "title", Encode.string video.title )
        , ( "videoUrl", Encode.string video.videoUrl )
        ]


decode : Decoder Video
decode =
    Decode.succeed Video
        |> required "id" Decode.int
        |> required "title" Decode.string
        |> required "videoUrl" Decode.string
