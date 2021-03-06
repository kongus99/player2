module Login.Login exposing (..)

import Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form as Form
import Bootstrap.Modal as Modal
import Html exposing (Html, div, text)
import Login.Form as Form exposing (resolveError)
import Login.User exposing (User(..), edit, getData, invalidate, userCreation, userLoggedIn, userVerification)
import RemoteData exposing (WebData)
import Task


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
    | Created (WebData String)
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
            Task.perform AlertMsg (Task.succeed m)
    in
    case msg of
        Submit ->
            ( model
            , case model.user of
                Creation u ->
                    Form.post "/api/user" u (Form.expectString Created)

                LoggingIn fields ->
                    Form.post "/api/authenticate" fields (Form.expectString Authenticated)

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

        Created response ->
            case response of
                RemoteData.Failure err ->
                    ( model, resolveError [ ( 403, "Could not create user." ) ] err |> Alert.Danger |> showFeedback )

                RemoteData.Success _ ->
                    ( { model | user = userVerification }, Alert.Success "User created." |> showFeedback )

                _ ->
                    ( model, Cmd.none )

        Authenticated response ->
            case response of
                RemoteData.Failure err ->
                    ( model
                    , resolveError [ ( 403, "Incorrect login/password." ) ] err |> Alert.Danger |> showFeedback
                    )

                RemoteData.Success _ ->
                    ( model
                    , Cmd.batch
                        [ Alert.Success "Logged in." |> showFeedback
                        , Alert.Danger "Cannot retrieve user data." |> UserFetched |> getData
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        UserFetched failMessage response ->
            case response of
                RemoteData.Success s ->
                    userLoggedIn s
                        |> Maybe.map (\user -> ( { init | user = user }, Cmd.none ))
                        |> Maybe.withDefault ( model, showFeedback failMessage )

                _ ->
                    ( model, showFeedback failMessage )

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
                |> Form.footer Submit "Submit" form
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
