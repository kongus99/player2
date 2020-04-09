module Alert exposing (..)

import Bootstrap.Alert as Alert
import Html exposing (Html, text)


type Msg
    = Close Alert.Visibility
    | Success String
    | Info String
    | Warning String
    | Danger String


type alias Model msg =
    { text : String, style : Alert.Config msg -> Alert.Config msg, visible : Alert.Visibility }


init : Model msg
init =
    { text = "", style = Alert.info, visible = Alert.closed }


update : Msg -> Model msg -> Model msg
update msg model =
    case msg of
        Close _ ->
            init

        Success text ->
            { text = text, style = Alert.success, visible = Alert.shown }

        Info text ->
            { text = text, style = Alert.info, visible = Alert.shown }

        Warning text ->
            { text = text, style = Alert.warning, visible = Alert.shown }

        Danger text ->
            { text = text, style = Alert.danger, visible = Alert.shown }


view : Model Msg -> Html Msg
view model =
    Alert.config
        |> model.style
        |> Alert.dismissable Close
        |> Alert.children [ text model.text ]
        |> Alert.view model.visible
