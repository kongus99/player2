module Video.Options exposing (..)

import Bootstrap.Navbar as Navbar
import Html exposing (text)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Json.Encode as Encode


type Option
    = Autoplay
    | Loop
    | Playlist


type alias Options =
    List Option


init =
    [ Loop ]


toString option =
    case option of
        Autoplay ->
            "Autoplay"

        Loop ->
            "Loop"

        Playlist ->
            "Playlist"


active option options =
    List.any (\o -> o == option) options


toggle option options =
    if active option options then
        List.filter (\o -> not <| o == option) options

    else
        option :: options


encode options =
    Encode.object
        [ ( "play", Encode.bool <| active Autoplay options )
        , ( "loop", Encode.bool <| (not (active Playlist options) && active Loop options) )
        ]


encodeWithUrl : String -> Options -> Encode.Value
encodeWithUrl url options =
    Encode.object
        [ ( "url", Encode.string url )
        , ( "options", encode options )
        ]


itemLink msg option options =
    if active option options then
        Navbar.itemLinkActive [ href "#", onClick <| msg option ] [ text (toString option) ]

    else
        Navbar.itemLink [ href "#", onClick <| msg option ] [ text (toString option) ]
