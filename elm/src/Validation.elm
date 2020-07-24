module Validation exposing (..)

import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Textarea as Textarea
import Dict
import Html exposing (div, text)


type Validation
    = Indeterminate
    | Valid
    | Invalid String


inputStatus : Validation -> Input.Option msg
inputStatus validation =
    case validation of
        Indeterminate ->
            Input.attrs []

        Valid ->
            Input.success

        Invalid _ ->
            Input.danger


textAreaStatus : Validation -> Textarea.Option msg
textAreaStatus validation =
    case validation of
        Indeterminate ->
            Textarea.attrs []

        Valid ->
            Textarea.success

        Invalid _ ->
            Textarea.danger


feedback : Validation -> Html.Html a
feedback validation =
    let
        formFeed feed generator =
            if String.isEmpty feed then
                div [] []

            else
                generator [] [ text feed ]
    in
    case validation of
        Indeterminate ->
            div [] []

        Valid ->
            formFeed "" Form.validFeedback

        Invalid t ->
            formFeed t Form.invalidFeedback


reduce : List Validation -> Validation
reduce validations =
    validations
        |> List.foldl
            (\val ->
                \acc ->
                    case ( val, acc ) of
                        ( _, Invalid _ ) ->
                            acc

                        ( Invalid _, _ ) ->
                            val

                        ( Indeterminate, _ ) ->
                            val

                        ( Valid, _ ) ->
                            acc
            )
            Valid
