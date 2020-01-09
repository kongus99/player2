module Main exposing (main)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Browser
import VideoList


main =
    Browser.element
        { init = VideoList.init
        , view = view
        , update = VideoList.update
        , subscriptions = \_ -> Sub.none
        }


view model =
    Grid.containerFluid []
        [ Grid.row [ Row.centerLg ]
            [ Grid.col [] [ VideoList.view model ]
            ]
        ]
