module Login.Form exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input exposing (Option)
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Modal as Modal exposing (Config)
import Dict
import Html exposing (Html, div, text)
import Html.Attributes exposing (for)
import Http
import Json.Decode as Decode
import Json.Encode as E
import RemoteData exposing (WebData)
import Set exposing (Set)
import Url
import Validation as Validation exposing (Validation(..))
import Validator exposing (Validator)


type Type
    = Password String
    | Text String
    | Url String
    | Email String
    | TextArea Int


type alias Serializer =
    ( String, Field ) -> ( String, String )


type alias Label =
    { id : String
    , label : String
    }


type alias Field =
    { label : Maybe Label
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


emptyInput : Maybe Label -> Type -> List (Validator Field) -> ValidatedField
emptyInput label type_ validators =
    serializableEmptyInput label type_ validators (\( k, v ) -> ( k, v.value ))


serializableEmptyInput : Maybe Label -> Type -> List (Validator Field) -> Serializer -> ValidatedField
serializableEmptyInput label type_ validators serializer =
    { field =
        { label = label
        , type_ = type_
        , disabled = False
        , value = ""
        }
    , serializer = serializer
    , validators = validators
    }


infoInput : Label -> String -> ValidatedField
infoInput label value =
    serializableInfoInput label value (\( k, v ) -> ( k, v.value ))


serializableInfoInput : Label -> String -> Serializer -> ValidatedField
serializableInfoInput label value serializer =
    { field =
        { label = Just label
        , type_ = Text ""
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

        generateLabel field =
            field.label |> Maybe.map (\l -> Form.label [ for l.id ] [ text l.label ]) |> Maybe.withDefault (div [] [])

        generateField key validation field =
            let
                inputField generateInput placeholder =
                    generateInput
                        [ Validation.inputStatus validation
                        , Input.disabled field.disabled
                        , Input.placeholder placeholder
                        , Input.value field.value
                        , Input.onInput <| msg key
                        , field.label |> Maybe.map (\l -> Input.id l.id) |> Maybe.withDefault (Input.attrs [])
                        ]
            in
            case field.type_ of
                Password placeholder ->
                    inputField Input.password placeholder

                Text placeholder ->
                    inputField Input.text placeholder

                Url placeholder ->
                    inputField Input.url placeholder

                Email placeholder ->
                    inputField Input.email placeholder

                TextArea rows ->
                    Textarea.textarea
                        [ Validation.textAreaStatus validation
                        , if field.disabled then
                            Textarea.disabled

                          else
                            Textarea.attrs []
                        , Textarea.value field.value
                        , Textarea.onInput <| msg key
                        , field.label |> Maybe.map (\l -> Textarea.id l.id) |> Maybe.withDefault (Textarea.attrs [])
                        , Textarea.rows rows
                        ]

        formField : ( String, ValidatedField ) -> List (Html msg)
        formField ( key, valField ) =
            let
                validation =
                    valField.validators |> List.map (\v -> v toValidate) |> Validation.reduce
            in
            [ generateLabel valField.field
            , generateField key validation valField.field
            , Validation.feedback validation
            ]
    in
    form.order |> List.filterMap (\k -> Dict.get k form.fields |> Maybe.map (\v -> ( k, v ))) |> List.map formField
