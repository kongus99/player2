port module Video.Page exposing (..)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Navbar as Navbar
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, href)
import Json.Encode as Encode
import TextFilter exposing (TextFilter)
import Video.Alert as Alert
import Video.Edit as Edit exposing (resetSubmitted)
import Video.List as List exposing (Msg(..))
import Video.Login as Login
import Video.Options as Options exposing (Option(..), Options)
import Video.Video as Video


port sendOptions : Encode.Value -> Cmd msg


type alias Model =
    { add : Edit.Model
    , login : Login.Model
    , list : List.Model
    , navbar : Navbar.State
    , options : Options
    , filter : TextFilter
    }


type Msg
    = Toggle Option
    | Filter String
    | Add Edit.Msg
    | LoginMsg Login.Msg
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
      , login = Login.init
      , list = list
      , navbar = navbar
      , options = Options.init
      , filter = TextFilter.empty
      }
    , Cmd.batch
        [ Cmd.map ListMsg listCmd
        , Cmd.map LoginMsg
            (Login.fetchUser <|
                Alert.Warning "Please log in to unlock more features."
            )
        , navbarCmd
        ]
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

        LoginMsg m ->
            let
                ( newModel, cmd ) =
                    Login.update m model.login
            in
            ( { model | login = newModel }, Cmd.map LoginMsg cmd )


view model =
    Grid.containerFluid []
        [ Grid.row [ Row.centerLg ]
            [ Grid.col [] [ navbarView model ]
            ]
        , Grid.row [ Row.centerLg, Row.attrs [ class "jumbotron jumbotron-fluid" ] ]
            [ Grid.col [] [ model.list |> List.view model.login |> Html.map ListMsg ]
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
            , Navbar.customItem <| Login.modal LoginMsg model.login
            , Navbar.customItem <| Login.loginButton LoginMsg model.login
            , Navbar.customItem <| Edit.modal Add model.add
            , Navbar.customItem <| Login.restrictHtml (Edit.addButton Add) model.login
            ]
        |> Navbar.view model.navbar
