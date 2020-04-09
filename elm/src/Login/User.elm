module Login.User exposing (..)

import Dict
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Login.Form as Form exposing (Form, emptyInput, emptyPassword)
import Regex
import RemoteData exposing (WebData)
import Validation exposing (Validation(..))



--states


type alias UserData =
    { id : Int, username : String, email : String }


type User
    = Creation Form
    | LoggingIn Form
    | LoggedIn UserData


userCreation : User
userCreation =
    Creation
        { fields =
            [ ( "username"
              , emptyInput "Username" validateUsername
              )
            , ( "email"
              , emptyInput "Email" validateEmail
              )
            , ( "password"
              , emptyPassword "Password"
              )
            , ( "passwordRepeated"
              , emptyPassword "Repeat password"
              )
            ]
        , validators = []
        , url = "/api/authenticate"
        }


userVerification : User
userVerification =
    LoggingIn
        { fields =
            [ ( "username"
              , emptyInput "Username" validateUsername
              )
            , ( "password"
              , emptyPassword "Password"
              )
            ]
        , validators = []
        , url = "/api/authenticate"
        }


userLoggedIn : String -> Maybe User
userLoggedIn string =
    let
        decoder =
            Decode.succeed UserData
                |> required "id" Decode.int
                |> required "username" Decode.string
                |> required "email" Decode.string
    in
    Decode.decodeString decoder string |> Result.toMaybe |> Maybe.map LoggedIn



--validation


regexpValidator : String -> (String -> String) -> String -> Validation
regexpValidator regexpString errorMessage tested =
    let
        regexp =
            Regex.fromString regexpString |> Maybe.withDefault Regex.never

        isValid user =
            Regex.find regexp user |> List.isEmpty |> not
    in
    if (String.trim tested |> String.length) < 3 then
        Indeterminate

    else if isValid tested then
        Valid ""

    else
        Invalid (errorMessage tested)


validateUsername : String -> Validation
validateUsername =
    regexpValidator
        "^[a-z0-9_-]{3,15}$"
        (\t -> "Incorrect username " ++ t)


validateEmail : String -> Validation
validateEmail =
    regexpValidator
        "^(([^<>()\\[\\]\\.,;:\\s@\"]+(\\.[^<>()\\[\\]\\.,;:\\s@\"]+)*)|(\".+\"))@(([^<>()[\\]\\.,;:\\s@\"]+\\.)+[^<>()[\\]\\.,;:\\s@\"]{2,})$"
        (\t -> "Incorrect email " ++ t)


validatePassword : String -> Validation
validatePassword =
    regexpValidator
        "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        (\_ -> "Minimum eight characters, at least one letter, one number and one special character.")



--requests


edit : ( String, String ) -> User -> User
edit new user =
    case user of
        Creation f ->
            Creation (Form.edit new f)

        LoggingIn f ->
            LoggingIn (Form.edit new f)

        LoggedIn _ ->
            user


getData : (WebData String -> msg) -> Cmd msg
getData msg =
    Http.get
        { url = "/api/user"
        , expect = Http.expectString (RemoteData.fromResult >> msg)
        }


invalidate : (WebData String -> msg) -> Cmd msg
invalidate msg =
    Http.post
        { url = "/api/logout"
        , body = Http.emptyBody
        , expect = Http.expectString (RemoteData.fromResult >> msg)
        }
