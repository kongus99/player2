module Video.Edit exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Modal as Modal
import Html exposing (Html, br, div, text)
import Video exposing (Video)


type alias Model =
    { visible : Modal.Visibility, id : Maybe Int, name : String, url : String }


init =
    { visible = Modal.hidden, id = Nothing, name = "", url = "" }


setVideo : Model -> Video -> Model
setVideo model video =
    { model | id = Just video.id, name = video.title, url = video.videoUrl }


type Msg
    = Close
    | Open (Maybe Video)
    | Submit
    | UpdateName String
    | UpdateUrl String


update : Msg -> Model -> ( Model, Maybe Video )
update msg model =
    case msg of
        Close ->
            ( { model | visible = Modal.hidden }, Nothing )

        Open video ->
            let
                openModal =
                    { model | visible = Modal.shown }
            in
            ( video |> Maybe.map (setVideo openModal) |> Maybe.withDefault openModal, Nothing )

        Submit ->
            let
                video =
                    Video (Maybe.withDefault -1 model.id) model.name model.url
            in
            ( { model | visible = Modal.hidden }, Just video )

        UpdateName name ->
            ( { model | name = name }, Nothing )

        UpdateUrl url ->
            ( { model | url = url }, Nothing )


addButton : (Msg -> msg) -> ButtonGroup.ButtonItem msg
addButton mapper =
    ButtonGroup.button [ Button.primary, Button.onClick (mapper (Open Nothing)) ] [ text "Add" ]


editButton : Video -> (Msg -> msg) -> ButtonGroup.ButtonItem msg
editButton video mapper =
    ButtonGroup.button [ Button.info, Button.small, Button.onClick (mapper (Open (Just video))) ] [ text "Edit" ]


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
                    [ text "Save" ]
                ]
            |> Modal.view model.visible
            |> Html.map mapper
        ]
