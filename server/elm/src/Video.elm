module Video exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


type alias Video =
    { id : Int
    , title : String
    , videoUrl : String
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
