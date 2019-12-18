module Signup exposing (User, initialModel, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (class, for, type_)
import Html.Events exposing (onClick)


type alias User =
    { name : String
    , email : String
    , password : String
    , loggedIn : Bool
    }


initialModel : User
initialModel =
    { name = ""
    , email = ""
    , password = ""
    , loggedIn = False
    }


type Msg
    = SaveName String
    | SaveEmail String
    | SavePassword String
    | Signup


update : Msg -> User -> User
update message user =
    case message of
        SaveName name ->
            { user | name = name }

        SaveEmail email ->
            { user | email = email }

        SavePassword password ->
            { user | password = password }

        Signup ->
            { user | loggedIn = True }


view : User -> Html Msg
view user =
    Form.form []
        [ h1 [ class "text-center" ] [ text "Sign up" ]
        , Form.group []
            [ Form.label [ for "name" ] [ text "Name" ]
            , Input.text [ Input.id "name", Input.onInput SaveName ]
            ]
        , Form.group []
            [ Form.label [ for "email" ] [ text "Email" ]
            , Input.email [ Input.id "email", Input.onInput SaveEmail ]
            ]
        , Form.group []
            [ Form.label [ for "password" ] [ text "Password" ]
            , Input.password [ Input.id "password", Input.onInput SavePassword ]
            ]
        , Button.submitButton [ Button.primary, Button.large, Button.onClick Signup ] [ text "Create my account" ]
        ]
