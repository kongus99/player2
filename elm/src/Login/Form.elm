module Login.Form exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Dict
import Html exposing (Html, div, text)
import Http
import Json.Encode as E
import RemoteData exposing (WebData)
import Set exposing (Set)
import Validation as Validation exposing (Validation(..))


type Type
    = Password
    | Input


type alias Validator =
    { dependents : Set String, target : String, check : Dict.Dict String String -> Validation }


type alias Field =
    { placeholder : String
    , value : String
    , validator : String -> Validation
    , type_ : Type
    }


type alias Form =
    { fields : List ( String, Field ), validators : List Validator, url : String }


emptyPassword : String -> Field
emptyPassword placeholder =
    { placeholder = placeholder
    , value = ""
    , validator =
        \s ->
            if String.isEmpty s then
                Indeterminate

            else
                Valid "Ok"
    , type_ = Password
    }


emptyInput : String -> (String -> Validation) -> Field
emptyInput placeholder validator =
    { placeholder = placeholder, value = "", validator = validator, type_ = Input }



--validate validator form =


edit : ( String, String ) -> Form -> Form
edit ( key, val ) form =
    { form
        | fields =
            List.map
                (\( k, field ) ->
                    if k == key then
                        ( k, { field | value = val } )

                    else
                        ( k, field )
                )
                form.fields
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
            ( k, E.string v.value )
    in
    form.fields |> List.map toObject |> send


submitButton : a -> String -> Form -> Html.Html a
submitButton msg title form =
    let
        validate ( _, { value, validator } ) =
            validator value

        validations =
            List.map validate form.fields
    in
    if List.any Validation.isInvalid validations then
        div [] []

    else
        Button.submitButton
            [ Button.primary
            , Button.onClick msg
            ]
            [ text title ]


view : (String -> String -> msg) -> Form -> List (List (Html msg))
view msg form =
    let
        singleInput ( key, field ) =
            case field.type_ of
                Password ->
                    [ Input.password
                        [ Input.placeholder field.placeholder
                        , Input.value field.value
                        , Input.onInput <| msg key
                        ]
                    ]

                Input ->
                    let
                        validation =
                            field.validator field.value
                    in
                    [ Input.text
                        [ Validation.status validation
                        , Input.placeholder field.placeholder
                        , Input.value field.value
                        , Input.onInput <| msg key
                        ]
                    , Validation.feedback validation
                    ]
    in
    List.map singleInput form.fields
