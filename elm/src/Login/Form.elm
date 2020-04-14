module Login.Form exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Dict
import Html exposing (Html, div, text)
import Http
import Json.Encode as E
import RemoteData exposing (WebData)
import Validation as Validation exposing (Validation(..))
import Validator exposing (Validator)


type Type
    = Password
    | Input


type alias Field =
    { placeholder : String
    , type_ : Type
    , value : String
    }


type alias ValidatedField =
    { field : Field
    , validators : List (Validator Field)
    }


type alias Form =
    { fields : Dict.Dict String ValidatedField
    , order : List String
    , url : String
    }


emptyInput : Type -> List (Validator Field) -> String -> ValidatedField
emptyInput type_ validators placeholder =
    { field =
        { placeholder = placeholder
        , type_ = type_
        , value = ""
        }
    , validators = validators
    }


edit : ( String, String ) -> Form -> Form
edit ( key, val ) form =
    let
        setValue f =
            { f | value = val }
    in
    { form
        | fields =
            Dict.update key (Maybe.map (\vf -> { vf | field = setValue vf.field })) form.fields
    }


submit : Form -> (WebData String -> c) -> Cmd c
submit form msg =
    let
        send args =
            Http.post
                { url = form.url
                , body =
                    E.object args
                        |> Http.jsonBody
                , expect = Http.expectString (RemoteData.fromResult >> msg)
                }

        toObject ( k, v ) =
            ( k, E.string v.field.value )
    in
    form.fields |> Dict.toList |> List.map toObject |> send


submitButton : a -> String -> Form -> Html.Html a
submitButton msg title form =
    let
        toValidate =
            form.fields |> Dict.map (\_ -> \vf -> vf.field)

        validation =
            form.fields |> Dict.values |> List.map (\v -> v.validators |> List.map (\val -> val toValidate) |> Validation.reduce) |> Validation.reduce
    in
    if validation == Valid then
        Button.submitButton
            [ Button.primary
            , Button.onClick msg
            ]
            [ text title ]

    else
        div [] []


view : (String -> String -> msg) -> Form -> List (List (Html msg))
view msg form =
    let
        toValidate =
            form.fields |> Dict.map (\_ -> \vf -> vf.field)

        typeToInput type_ =
            case type_ of
                Password ->
                    Input.password

                Input ->
                    Input.text

        singleInput : ( String, ValidatedField ) -> List (Html msg)
        singleInput ( key, valField ) =
            let
                validation =
                    valField.validators |> List.map (\v -> v toValidate) |> Validation.reduce
            in
            [ typeToInput valField.field.type_
                [ Validation.status validation
                , Input.placeholder valField.field.placeholder
                , Input.value valField.field.value
                , Input.onInput <| msg key
                ]
            , Validation.feedback validation
            ]
    in
    form.order |> List.filterMap (\k -> Dict.get k form.fields |> Maybe.map (\v -> ( k, v ))) |> List.map singleInput
