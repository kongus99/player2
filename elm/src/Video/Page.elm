port module Video.Page exposing (..)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Navbar as Navbar
import Html exposing (Html, text)
import Html.Attributes exposing (class, href)
import Json.Encode as Encode
import TextFilter exposing (TextFilter)
import Video.Edit as Edit exposing (resetSubmitted)
import Video.List as List exposing (Msg(..))
import Video.Options as Options exposing (Option(..), Options)
import Video.Video as Video


port sendOptions : Encode.Value -> Cmd msg


type alias Model =
    { add : Edit.Model
    , list : List.Model
    , navbar : Navbar.State
    , options : Options
    , filter : TextFilter
    }


type Msg
    = Toggle Option
    | Filter String
    | Add Edit.Msg
    | ListMsg List.Msg
    | NavbarMsg Navbar.State


init _ =
    let
        ( list, listCmd ) =
            List.init

        ( navbar, navbarCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { add = Edit.init
      , list = list
      , navbar = navbar
      , options = Options.init
      , filter = TextFilter.empty
      }
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
                    List.update model.filter model.options m model.list
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

        Filter string ->
            let
                filter =
                    TextFilter.parse string
            in
            ( { model
                | filter = filter
                , list = List.filterList filter model.list
              }
            , Cmd.none
            )

        Add m ->
            let
                ( newModel, cmd ) =
                    Edit.update m model.add
            in
            if newModel.submitted then
                ( { model | add = newModel |> resetSubmitted }, Video.get (ListMsg << Fetched) )

            else
                ( { model | add = newModel }, Cmd.map Add cmd )


view model =
    Grid.containerFluid []
        [ Grid.row [ Row.centerLg ]
            [ Grid.col [] [ navbarView model ]
            ]
        , Grid.row [ Row.centerLg, Row.attrs [ class "jumbotron jumbotron-fluid" ] ]
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
        |> Navbar.customItems
            [ TextFilter.navbar Filter model.filter
            , Navbar.customItem <| Edit.modal Add model.add
            , Navbar.customItem <| Edit.addButton Add
            ]
        |> Navbar.view model.navbar