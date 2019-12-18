module Main exposing (main)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Browser
import Signup exposing (User)


main =
    Browser.sandbox
        { init = Signup.initialModel
        , view = view
        , update = Signup.update
        }


view model =
    Grid.container []
        [ Grid.row [ Row.topXs ] []
        , Grid.row [ Row.centerMd ]
            [ Grid.col [] [ Signup.view model ]
            ]
        , Grid.row [ Row.bottomXs ] []
        ]
