module Video.Validation exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Html exposing (div, text)


type Validation
    = Indeterminate
    | Valid String
    | Invalid String


status : Validation -> Input.Option msg
status validation =
    case validation of
        Indeterminate ->
            Input.attrs []

        Valid _ ->
            Input.success

        Invalid _ ->
            Input.danger


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

        Valid t ->
            formFeed t Form.validFeedback

        Invalid t ->
            formFeed t Form.invalidFeedback


isInvalid : Validation -> Bool
isInvalid validation =
    case validation of
        Valid _ ->
            False

        _ ->
            True


forSubmit : a -> String -> List Validation -> Html.Html a
forSubmit msg title validations =
    if List.any isInvalid validations then
        div [] []

    else
        Button.submitButton
            [ Button.primary
            , Button.onClick msg
            ]
            [ text title ]
