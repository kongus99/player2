module Video.Add exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Modal as Modal
import Html exposing (Html, br, div, text)
import Video exposing (Video)


type alias Model =
    { visible : Modal.Visibility, name : String, url : String }


init =
    { visible = Modal.hidden, name = "", url = "" }


type Msg
    = Close
    | Open
    | Submit
    | UpdateName String
    | UpdateUrl String


update : Msg -> Model -> ( Model, Maybe Video )
update msg model =
    case msg of
        Close ->
            ( { model | visible = Modal.hidden }, Nothing )

        Open ->
            ( { model | visible = Modal.shown }, Nothing )

        Submit ->
            ( { model | visible = Modal.hidden }, Just (Video -1 model.name model.url) )

        UpdateName name ->
            ( { model | name = name }, Nothing )

        UpdateUrl url ->
            ( { model | url = url }, Nothing )


button : (Msg -> msg) -> ButtonGroup.ButtonItem msg
button mapper =
    ButtonGroup.button [ Button.primary, Button.onClick (mapper Open) ] [ text "Add" ]


modal : (Msg -> msg) -> Model -> Html msg
modal mapper model =
    div []
        [ Modal.config Close
            |> Modal.large
            |> Modal.hideOnBackdropClick True
            |> Modal.body []
                [ InputGroup.config
                    (InputGroup.text [ Input.placeholder "Name", Input.value model.name, Input.onInput UpdateName ])
                    |> InputGroup.view
                , br [] []
                , InputGroup.config
                    (InputGroup.text [ Input.placeholder "Url", Input.value model.url, Input.onInput UpdateUrl ])
                    |> InputGroup.view
                ]
            |> Modal.footer []
                [ Button.submitButton
                    [ Button.primary
                    , Button.onClick Submit
                    ]
                    [ text "Add" ]
                ]
            |> Modal.view model.visible
            |> Html.map mapper
        ]
