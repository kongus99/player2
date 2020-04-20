module Login.User exposing (..)

import Dict
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Login.Form as Form exposing (Field, Form, Type(..), emptyInput)
import Regex
import RemoteData exposing (WebData)
import Set
import Validation exposing (Validation(..))
import Validator exposing (Validator, email, emptyString, password, username, validator)



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
              , emptyInput Input [ validator username "username" .value ] "Username"
              )
            , ( "email"
              , emptyInput Input [ validator email "email" .value ] "Email"
              )
            , ( "password"
              , emptyInput Password [ validator password "password" .value ] "Password"
              )
            , ( "passwordRepeated"
              , emptyInput Password [ validatePasswordsMatch ] "Repeat password"
              )
            ]
                |> Dict.fromList
        , order = [ "username", "email", "password", "passwordRepeated" ]
        , url = "/api/user"
        }


userVerification : User
userVerification =
    LoggingIn
        { fields =
            [ ( "username"
              , emptyInput Input [ validator username "username" .value ] "Username"
              )
            , ( "password"
              , emptyInput Password [ validator emptyString "password" .value ] "Password"
              )
            ]
                |> Dict.fromList
        , order = [ "username", "password" ]
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


validatePasswordsMatch : Validator Field
validatePasswordsMatch toCheck =
    Maybe.map2
        (\f1 ->
            \f2 ->
                case ( f1.value, f2.value ) of
                    ( "", _ ) ->
                        Indeterminate

                    ( _, "" ) ->
                        Indeterminate

                    ( x, y ) ->
                        if x == y then
                            Valid

                        else
                            Invalid "Password fields must be the same"
        )
        (Dict.get "password" toCheck)
        (Dict.get "passwordRepeated" toCheck)
        |> Maybe.withDefault Indeterminate



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
