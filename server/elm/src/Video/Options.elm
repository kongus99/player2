module Video.Options exposing (..)

import Json.Encode as Encode


type alias Options =
    { play : Bool
    }


init =
    Options False


togglePlay : Options -> Options
togglePlay options =
    { options | play = not options.play }


encode options =
    Encode.object
        [ ( "play", Encode.bool options.play )
        ]


encodeWithUrl : String -> Options -> Encode.Value
encodeWithUrl url options =
    Encode.object
        [ ( "url", Encode.string url )
        , ( "options", encode options )
        ]
