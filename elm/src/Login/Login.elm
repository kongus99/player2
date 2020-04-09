module Login.Login exposing (..)

import Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form as Form
import Bootstrap.Modal as Modal
import Html exposing (Html, div, h2, text)
import Http
import Login.Form as Form exposing (submit, submitButton)
import Login.User exposing (User(..), edit, getData, invalidate, userCreation, userLoggedIn, userVerification)
import RemoteData exposing (WebData)


type alias Model =
    { user : User
    , alert : Alert.Model Alert.Msg
    , visible : Modal.Visibility
    }


restrict : a -> a -> Model -> a
restrict loggedOut loggedIn model =
    case model.user of
        LoggedIn _ ->
            loggedIn

        _ ->
            loggedOut


restrictHtml : Html msg -> Model -> Html msg
restrictHtml =
    restrict (div [] [])


type Msg
    = Submit
    | Authenticated (WebData String)
    | UserFetched Alert.Msg (WebData String)
    | Edit String String
    | Toggle User
    | Open
    | Close
    | AlertMsg Alert.Msg
    | LogOut
    | LoggedOut (WebData String)


init =
    { user = userVerification, alert = Alert.init, visible = Modal.hidden }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        showFeedback m =
            update (AlertMsg m) model
    in
    case msg of
        Submit ->
            ( model
            , case model.user of
                Creation u ->
                    Cmd.none

                LoggingIn fields ->
                    submit fields Authenticated

                LoggedIn _ ->
                    Cmd.none
            )

        Edit k v ->
            ( { model | user = edit ( k, v ) model.user }, Cmd.none )

        Toggle u ->
            ( { model | user = u }, Cmd.none )

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
                    ( m, Cmd.batch [ c, Alert.Danger "Cannot retrieve user data." |> UserFetched |> getData ] )

                _ ->
                    ( model, Cmd.none )

        UserFetched failMessage response ->
            case response of
                RemoteData.Success s ->
                    userLoggedIn s
                        |> Maybe.map (\user -> { model | user = user } |> update Close)
                        |> Maybe.withDefault (showFeedback failMessage)

                _ ->
                    showFeedback failMessage

        AlertMsg m ->
            ( { model | alert = Alert.update m model.alert }, Cmd.none )

        LogOut ->
            ( model, invalidate LoggedOut )

        LoggedOut response ->
            case response of
                RemoteData.Success _ ->
                    ( { model | user = userVerification }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


loginButton : (Msg -> a) -> Model -> Html a
loginButton mapper =
    restrict
        (Button.button [ Button.success, Button.onClick (mapper Open) ] [ text "LOG IN" ])
        (Button.button [ Button.success, Button.onClick (mapper LogOut) ] [ text "LOG OUT" ])


view : (Msg -> msg) -> Model -> Html msg
view mapper model =
    let
        modal form =
            let
                fields =
                    (Alert.view model.alert |> Html.map AlertMsg) :: (Form.view Edit form |> List.map (Form.group []))
            in
            Modal.config Close
                |> Modal.large
                |> Modal.hideOnBackdropClick True
                |> Modal.header []
                    [ ButtonGroup.radioButtonGroup []
                        [ ButtonGroup.radioButton (model.user == LoggingIn form) [ Button.primary, Button.onClick <| Toggle userVerification ] [ text "Log in" ]
                        , ButtonGroup.radioButton (model.user == Creation form) [ Button.primary, Button.onClick <| Toggle userCreation ] [ text "Create" ]
                        ]
                    ]
                |> Modal.body []
                    [ Form.form [] fields
                    ]
                |> Modal.footer [] [ submitButton Submit "Submit" form ]
                |> Modal.view model.visible
                |> Html.map mapper
    in
    case model.user of
        Creation form ->
            modal form

        LoggingIn form ->
            modal form

        LoggedIn _ ->
            div [] []
