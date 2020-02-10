module Video.Page exposing (..)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Html
import Video.List as List
import Video.Toolbar as Toolbar


type alias Model =
    { list : List.Model, toolbar : Toolbar.Model }


type Msg
    = ListMsg List.Msg
    | ToolbarMsg Toolbar.Msg


init _ =
    let
        ( list, listCmd ) =
            List.init

        ( toolbar, toolbarCmd ) =
            Toolbar.initialState
    in
    ( { list = list, toolbar = toolbar }
    , Cmd.batch
        [ Cmd.map
            ListMsg
            listCmd
        , Cmd.map ToolbarMsg toolbarCmd
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ List.subscriptions model.list |> Sub.map ListMsg
        , Toolbar.subscriptions model.toolbar |> Sub.map ToolbarMsg
        ]


update msg model =
    case msg of
        ListMsg m ->
            let
                ( list, listCmd ) =
                    List.update m model.list
            in
            ( { model | list = list }, Cmd.map ListMsg listCmd )

        ToolbarMsg m ->
            let
                ( toolbar, toolbarCmd ) =
                    Toolbar.update m model.toolbar
            in
            ( { model | toolbar = toolbar }, Cmd.map ToolbarMsg toolbarCmd )


view model =
    Grid.containerFluid []
        [ Grid.row [ Row.centerLg ]
            [ Grid.col [] [ Toolbar.view model.toolbar |> Html.map ToolbarMsg ]
            ]
        , Grid.row [ Row.centerLg ]
            [ Grid.col [] [ List.view model.list |> Html.map ListMsg ]
            ]
        ]
