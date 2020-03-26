module Video.Login exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Modal as Modal
import Html exposing (Html, div, h2, text)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import Regex
import RemoteData exposing (WebData)
import Video.Alert as Alert
import Video.Validation as Validation exposing (Validation(..), forSubmit)


type alias User =
    { name : String
    }


type alias Model =
    { name : String
    , password : String
    , user : Maybe User
    , alert : Alert.Model Alert.Msg
    , visible : Modal.Visibility
    }


userDecoder : Decoder User
userDecoder =
    Decode.succeed User
        |> required "name" Decode.string


validUsername : String -> Bool
validUsername username =
    let
        regexp =
            Regex.fromString "^[a-z0-9_-]{3,15}$" |> Maybe.withDefault Regex.never
    in
    Regex.find regexp username |> List.isEmpty |> not


authenticate : Model -> Cmd Msg
authenticate model =
    let
        body =
            [ ( "username", E.string model.name )
            , ( "password", E.string model.password )
            ]
                |> E.object
                |> Http.jsonBody
    in
    Http.post
        { url = "/api/authenticate"
        , body = body
        , expect = Http.expectString (RemoteData.fromResult >> Authenticated)
        }


fetchUser : Cmd Msg
fetchUser =
    Http.get
        { url = "/api/user"
        , expect = Http.expectString (RemoteData.fromResult >> UserFetched)
        }


logout : Cmd Msg
logout =
    Http.post
        { url = "/api/logout"
        , body = Http.emptyBody
        , expect = Http.expectString (RemoteData.fromResult >> LoggedOut)
        }


restrict : a -> a -> Model -> a
restrict loggedOut loggedIn model =
    model.user |> Maybe.map (\_ -> loggedIn) |> Maybe.withDefault loggedOut


restrictHtml : Html msg -> Model -> Html msg
restrictHtml =
    restrict (div [] [])


type Msg
    = Authenticate
    | Authenticated (WebData String)
    | UserFetched (WebData String)
    | Open
    | Close
    | EditPassword String
    | EditName String
    | AlertMsg Alert.Msg
    | LogOut
    | LoggedOut (WebData String)


init =
    { name = "", password = "", user = Nothing, alert = Alert.init, visible = Modal.hidden }


validateUsername username =
    if (String.trim username |> String.length) < 3 then
        Indeterminate

    else if validUsername username then
        Valid ""

    else
        Invalid ("Incorrect username " ++ username)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        showFeedback m =
            update (AlertMsg m) model
    in
    case msg of
        Authenticate ->
            ( model, authenticate model )

        EditPassword password ->
            ( { model | password = password }, Cmd.none )

        EditName name ->
            ( { model | name = name }, Cmd.none )

        Open ->
            let
                openModal =
                    { model | visible = Modal.shown }
            in
            ( openModal, Cmd.none )

        Close ->
            ( { init | user = model.user }, Cmd.none )

        Authenticated response ->
            case response of
                RemoteData.Failure err ->
                    case err of
                        Http.BadStatus status ->
                            if status == 403 then
                                showFeedback <| Alert.Danger "Incorrect login/password."

                            else
                                showFeedback <| Alert.Danger "Server status error."

                        _ ->
                            showFeedback <| Alert.Danger "Server error."

                RemoteData.Success _ ->
                    let
                        ( m, c ) =
                            showFeedback <| Alert.Success "Logged in."
                    in
                    ( m, Cmd.batch [ c, fetchUser ] )

                _ ->
                    ( model, Cmd.none )

        UserFetched response ->
            case response of
                RemoteData.Success s ->
                    { model | user = Decode.decodeString userDecoder s |> Result.toMaybe } |> update Close

                _ ->
                    showFeedback <| Alert.Danger "Cannot retrieve user data."

        AlertMsg m ->
            ( { model | alert = Alert.update m model.alert }, Cmd.none )

        LogOut ->
            ( model, logout )

        LoggedOut response ->
            case response of
                RemoteData.Success s ->
                    ( { model | user = Nothing }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


loginButton : (Msg -> a) -> Model -> Html a
loginButton mapper =
    restrict
        (Button.button [ Button.success, Button.onClick (mapper Open) ] [ text "LOG IN" ])
        (Button.button [ Button.success, Button.onClick (mapper LogOut) ] [ text "LOG OUT" ])


modal : (Msg -> msg) -> Model -> Html msg
modal mapper model =
    let
        validation =
            validateUsername model.name
    in
    div []
        [ Modal.config Close
            |> Modal.large
            |> Modal.hideOnBackdropClick True
            |> Modal.header [] [ h2 [] [ text "Log in" ] ]
            |> Modal.body []
                [ Form.form []
                    [ Alert.view model.alert |> Html.map AlertMsg
                    , Form.group []
                        [ Input.text
                            [ Validation.status validation
                            , Input.placeholder "Username"
                            , Input.value model.name
                            , Input.onInput EditName
                            ]
                        , Validation.feedback validation
                        ]
                    , Form.group []
                        [ Input.password
                            [ Input.placeholder "Password"
                            , Input.value model.password
                            , Input.onInput EditPassword
                            ]
                        ]
                    ]
                ]
            |> Modal.footer [] [ forSubmit Authenticate "Log in" [ validation ] ]
            |> Modal.view model.visible
            |> Html.map mapper
        ]
