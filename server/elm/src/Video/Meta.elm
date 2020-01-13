module Video.Meta exposing (..)

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import RemoteData exposing (WebData)
import Url exposing (Url)
import Video exposing (Video)


type alias Meta =
    { title : String
    }


url videoUrl =
    "http://localhost:8080/meta?url=" ++ Url.toString videoUrl


get : Url -> (WebData Meta -> msg) -> Cmd msg
get videoUrl msg =
    Http.get
        { url = url videoUrl
        , expect =
            decode
                |> Http.expectJson (RemoteData.fromResult >> msg)
        }


decode : Decoder Meta
decode =
    Decode.succeed Meta
        |> required "title" Decode.string
