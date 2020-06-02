module Validator exposing (..)

import Dict
import Regex
import Validation exposing (Validation(..))


type alias Validator a =
    Dict.Dict String a -> Validation


validator : (String -> Validation) -> String -> (a -> String) -> Validator a
validator checker key extractor toCheck =
    Dict.get key toCheck
        |> Maybe.map (extractor >> checker)
        |> Maybe.withDefault Indeterminate


emptyString : String -> Validation
emptyString string =
    if String.isEmpty string then
        Indeterminate

    else
        Valid


username : String -> Validation
username =
    regexpValidator
        "^[a-zA-Z0-9_-]{3,15}$"
        (\_ -> "Lower and upper case letters, numbers, - and _, min 3 and max 15 chars ")


email : String -> Validation
email =
    regexpValidator
        "^(([^<>()\\[\\]\\.,;:\\s@\"]+(\\.[^<>()\\[\\]\\.,;:\\s@\"]+)*)|(\".+\"))@(([^<>()[\\]\\.,;:\\s@\"]+\\.)+[^<>()[\\]\\.,;:\\s@\"]{2,})$"
        (\_ -> "Incorrect email.")


password : String -> Validation
password =
    regexpValidator
        "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$"
        (\_ -> "Minimum eight characters, at least one uppercase letter, one lowercase letter, one number and one special character.")


url =
    regexpValidator
        "[(http(s)?):\\/\\/(www\\.)?a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
        (\_ -> "Correct url expected.")


regexpValidator : String -> (String -> String) -> String -> Validation
regexpValidator regexpString errorMessage tested =
    let
        regexp =
            Regex.fromString regexpString |> Maybe.withDefault Regex.never

        isValid string =
            Regex.find regexp string |> List.isEmpty |> not
    in
    if (String.trim tested |> String.length) < 3 then
        Indeterminate

    else if isValid tested then
        Valid

    else
        Invalid (errorMessage tested)
