module Video.Meta exposing (..)

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import RemoteData exposing (WebData)
import Url exposing (Url)


type alias Meta =
    { title : String
    }


url videoId =
    "/api/meta?vid=" ++ videoId


get : String -> (WebData Meta -> msg) -> Cmd msg
get videoId msg =
    Http.get
        { url = url videoId
        , expect =
            decode
                |> Http.expectJson (RemoteData.fromResult >> msg)
        }


decode : Decoder Meta
decode =
    Decode.succeed Meta
        |> required "title" Decode.string
