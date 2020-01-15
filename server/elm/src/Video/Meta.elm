module Video.Meta exposing (..)

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import RemoteData exposing (WebData)
import Url exposing (Url)


type alias Meta =
    { title : String
    }


url metaUrl =
    "/api/meta?url=" ++ Url.toString metaUrl


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
