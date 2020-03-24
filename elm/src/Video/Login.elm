module Video.Login exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Modal as Modal
import Html exposing (Html, div, text)
import Http
import Json.Decode exposing (string)
import Regex
import RemoteData exposing (WebData)
import Video.Validation as Validation exposing (Validation(..), forSubmit)


type alias Model =
    { name : String
    , password : String
    , visible : Modal.Visibility
    }


validUsername : String -> Bool
validUsername username =
    let
        regexp =
            Regex.fromString "^[a-z0-9_-]{3,15}$" |> Maybe.withDefault Regex.never
    in
    Regex.find regexp username |> List.isEmpty |> not


get : Model -> (WebData String -> msg) -> Cmd msg
get model msg =
    Http.get
        { url = "/api/authenticate?username=" ++ model.name ++ "&password=" ++ model.password
        , expect =
            string |> Http.expectJson (RemoteData.fromResult >> msg)
        }


type Msg
    = Submit
    | Open
    | Close
    | Response (WebData String)
    | EditPassword String
    | EditName String


init =
    { name = "", password = "", visible = Modal.hidden }


validateUsername username =
    if (String.trim username |> String.length) < 3 then
        Indeterminate

    else if validUsername username then
        Valid ""

    else
        Invalid ("Incorrect username " ++ username)


update msg model =
    case msg of
        Submit ->
            ( model, get model Response )

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
            ( { model | visible = Modal.hidden }, Cmd.none )

        Response data ->
            ( model, Cmd.none )


loginButton : (Msg -> a) -> Html a
loginButton mapper =
    Button.button [ Button.success, Button.onClick (mapper Open) ] [ text "LOG IN" ]


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
            |> Modal.h2 [] [ text "Log in" ]
            |> Modal.body []
                [ Form.form []
                    [ Form.group []
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
            |> Modal.footer [] [ forSubmit Submit "Log in" [ validation ] ]
            |> Modal.view model.visible
            |> Html.map mapper
        ]
