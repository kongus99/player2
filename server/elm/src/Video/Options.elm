module Video.Options exposing (..)

import Json.Encode as Encode


type alias Options =
    { play : Bool
    , loop : Bool
    , playlist : Bool
    }


init =
    { play = False, loop = True, playlist = False }


togglePlay : Options -> Options
togglePlay options =
    { options | play = not options.play }


toggleLoop : Options -> Options
toggleLoop options =
    { options | loop = not options.loop }


togglePlaylist : Options -> Options
togglePlaylist options =
    { options | playlist = not options.playlist }


encode options =
    Encode.object
        [ ( "play", Encode.bool options.play )
        , ( "loop", Encode.bool (not options.playlist && options.loop) )
        ]


encodeWithUrl : String -> Options -> Encode.Value
encodeWithUrl url options =
    Encode.object
        [ ( "url", Encode.string url )
        , ( "options", encode options )
        ]
