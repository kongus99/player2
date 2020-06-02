module Login.Form exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input exposing (Option)
import Bootstrap.Modal as Modal exposing (Config)
import Dict
import Html exposing (Html, text)
import Http
import Json.Decode as Decode
import Json.Encode as E
import RemoteData exposing (WebData)
import Set exposing (Set)
import Url
import Validation as Validation exposing (Validation(..))
import Validator exposing (Validator)


type Type
    = Password
    | Text
    | Url
    | Email


type alias Serializer =
    ( String, Field ) -> ( String, String )


type alias Field =
    { placeholder : String
    , disabled : Bool
    , type_ : Type
    , value : String
    }


type alias ValidatedField =
    { field : Field
    , serializer : Serializer
    , validators : List (Validator Field)
    }


type alias Form =
    { fields : Dict.Dict String ValidatedField
    , order : List String
    , excluded : Set String
    }


emptyInput : Type -> List (Validator Field) -> String -> ValidatedField
emptyInput type_ validators placeholder =
    serializableEmptyInput type_ validators placeholder (\( k, v ) -> ( k, v.value ))


serializableEmptyInput : Type -> List (Validator Field) -> String -> Serializer -> ValidatedField
serializableEmptyInput type_ validators placeholder serializer =
    { field =
        { placeholder = placeholder
        , type_ = type_
        , disabled = False
        , value = ""
        }
    , serializer = serializer
    , validators = validators
    }


infoInput : String -> ValidatedField
infoInput value =
    serializableInfoInput value (\( k, v ) -> ( k, v.value ))


serializableInfoInput : String -> Serializer -> ValidatedField
serializableInfoInput value serializer =
    { field =
        { placeholder = ""
        , type_ = Text
        , disabled = True
        , value = value
        }
    , serializer = serializer
    , validators = []
    }


fieldValidator : (String -> Validation) -> String -> Validator Field
fieldValidator checker key toCheck =
    Validator.validator checker key .value toCheck


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



-- submits


expectString : (WebData String -> c) -> Http.Expect c
expectString msg =
    Http.expectString (RemoteData.fromResult >> msg)


expectJson : (WebData a -> c) -> Decode.Decoder a -> Http.Expect c
expectJson msg =
    Http.expectJson (RemoteData.fromResult >> msg)


serializeFields : Form -> List ( String, String )
serializeFields form =
    form.fields
        |> Dict.filter (\k -> \_ -> Set.member k form.excluded |> not)
        |> Dict.toList
        |> List.map
            (\( k, v ) -> v.serializer ( k, v.field ))


get : (String -> String) -> Form -> Http.Expect c -> Cmd c
get urlGenerator form expect =
    Http.get
        { url =
            form
                |> serializeFields
                |> List.map (\( k, v ) -> k ++ "=" ++ v)
                |> String.join "&"
                |> urlGenerator
        , expect = expect
        }


post : String -> Form -> Http.Expect c -> Cmd c
post url form expect =
    Http.post
        { url = url
        , body =
            form
                |> serializeFields
                |> List.map (\( k, v ) -> ( k, E.string v ))
                |> E.object
                |> Http.jsonBody
        , expect = expect
        }


footer :
    a
    -> String
    -> Form
    -> Config a
    -> Config a
footer msg title form =
    let
        toValidate =
            form.fields |> Dict.map (\_ -> \vf -> vf.field)

        validation =
            form.fields |> Dict.values |> List.map (\v -> v.validators |> List.map (\val -> val toValidate) |> Validation.reduce) |> Validation.reduce
    in
    if validation == Valid then
        Modal.footer []
            [ Button.submitButton
                [ Button.primary
                , Button.onClick msg
                ]
                [ text title ]
            ]

    else
        identity


resolveError : List ( Int, String ) -> Http.Error -> String
resolveError responses err =
    case err of
        Http.BadStatus status ->
            responses
                |> List.filterMap
                    (\( s, m ) ->
                        if s == status then
                            Just m

                        else
                            Nothing
                    )
                |> List.head
                |> Maybe.withDefault ("Server status " ++ String.fromInt status ++ " error.")

        _ ->
            "Server error."


view : (String -> String -> msg) -> Form -> List (List (Html msg))
view msg form =
    let
        toValidate =
            form.fields |> Dict.map (\_ -> \vf -> vf.field)

        typeToInput type_ =
            case type_ of
                Password ->
                    Input.password

                Text ->
                    Input.text

                Url ->
                    Input.url

                Email ->
                    Input.email

        singleInput : ( String, ValidatedField ) -> List (Html msg)
        singleInput ( key, valField ) =
            let
                validation =
                    valField.validators |> List.map (\v -> v toValidate) |> Validation.reduce
            in
            [ typeToInput valField.field.type_
                [ Validation.status validation
                , Input.disabled valField.field.disabled
                , Input.placeholder valField.field.placeholder
                , Input.value valField.field.value
                , Input.onInput <| msg key
                ]
            , Validation.feedback validation
            ]
    in
    form.order |> List.filterMap (\k -> Dict.get k form.fields |> Maybe.map (\v -> ( k, v ))) |> List.map singleInput
