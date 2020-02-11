port module Video.Page exposing (..)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Navbar as Navbar
import Html exposing (Html, text)
import Html.Attributes exposing (href)
import Json.Encode as Encode
import Video.List as List
import Video.Options as Options exposing (Option(..), Options)


port sendOptions : Encode.Value -> Cmd msg


type alias Model =
    { list : List.Model, navbar : Navbar.State, options : Options }


type Msg
    = Toggle Option
    | ListMsg List.Msg
    | NavbarMsg Navbar.State


init _ =
    let
        ( list, listCmd ) =
            List.init

        ( navbar, navbarCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { list = list, navbar = navbar, options = Options.init }
    , Cmd.batch [ Cmd.map ListMsg listCmd, navbarCmd ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ List.subscriptions model.list |> Sub.map ListMsg
        , Navbar.subscriptions model.navbar NavbarMsg
        ]


update msg model =
    case msg of
        ListMsg m ->
            let
                ( list, listCmd ) =
                    List.update model.options m model.list
            in
            ( { model | list = list }, Cmd.map ListMsg listCmd )

        NavbarMsg state ->
            ( { model | navbar = state }, Cmd.none )

        Toggle option ->
            let
                options =
                    Options.toggle option model.options

                cmd =
                    case option of
                        Loop ->
                            Options.encode options |> sendOptions

                        _ ->
                            Cmd.none
            in
            ( { model | options = options }, cmd )


view model =
    Grid.containerFluid []
        [ Grid.row [ Row.centerLg ]
            [ Grid.col [] [ navbarView model ]
            ]
        , Grid.row [ Row.centerLg ]
            [ Grid.col [] [ List.view model.list |> Html.map ListMsg ]
            ]
        ]


navbarView model =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.primary
        |> Navbar.fixTop
        |> Navbar.brand [ href "/" ] [ text "Video list" ]
        |> Navbar.items
            [ Options.itemLink Toggle Autoplay model.options
            , Options.itemLink Toggle Loop model.options
            , Options.itemLink Toggle Playlist model.options
            ]
        |> Navbar.view model.navbar
