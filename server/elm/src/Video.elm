module Video exposing (..)

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
