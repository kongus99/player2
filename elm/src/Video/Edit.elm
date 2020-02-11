module Video.Edit exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Modal as Modal
import Extra exposing (isJust)
import Html exposing (Html, br, div, text)
import RemoteData exposing (WebData)
import Url exposing (Url)
import Video.Meta as Meta exposing (Meta)
import Video.Video as Video exposing (Video)


type alias Model =
    { visible : Modal.Visibility, submitted : Bool, video : Maybe Video }


init =
    { visible = Modal.hidden, submitted = False, video = Nothing }


resetSubmitted model =
    { model | submitted = False }


setVideo : Model -> Video -> Model
setVideo model video =
    { model | video = Just video }


type Msg
    = Close
    | Open (Maybe Video)
    | Submit
    | Submitted (WebData (Maybe Int))
    | Verified Url (WebData Meta)
    | UpdateUrl String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Close ->
            ( { model | visible = Modal.hidden }, Cmd.none )

        Open video ->
            let
                openModal =
                    { model | visible = Modal.shown }
            in
            ( video |> Maybe.map (setVideo openModal) |> Maybe.withDefault openModal, Cmd.none )

        Submit ->
            let
                cmd =
                    model.video
                        |> Maybe.map
                            (\v ->
                                case v.id of
                                    Nothing ->
                                        Video.post Submitted v

                                    _ ->
                                        Video.put Submitted v
                            )
                        |> Maybe.withDefault Cmd.none
            in
            ( model, cmd )

        UpdateUrl url ->
            ( model
            , url
                |> Url.fromString
                |> Maybe.map
                    (\u -> Meta.get u (Verified u))
                |> Maybe.withDefault Cmd.none
            )

        Submitted _ ->
            ( { model | visible = Modal.hidden, submitted = True, video = Nothing }, Cmd.none )

        Verified videoUrl webData ->
            let
                video =
                    case webData of
                        RemoteData.Success meta ->
                            Just (Video Nothing meta.title videoUrl)

                        _ ->
                            Nothing
            in
            ( { model | video = video }, Cmd.none )


addButton : (Msg -> a) -> Html a
addButton mapper =
    Button.button [ Button.success, Button.onClick (mapper (Open Nothing)) ] [ text "+" ]


editButton : Video -> (Msg -> msg) -> ButtonGroup.ButtonItem msg
editButton video mapper =
    ButtonGroup.button [ Button.info, Button.small, Button.onClick (mapper (Open (Just video))) ] [ text "Edit" ]


modal : (Msg -> msg) -> Model -> Html msg
modal mapper model =
    let
        name =
            model.video |> Maybe.map .title |> Maybe.withDefault ""

        url =
            model.video
                |> Maybe.map .videoUrl
                |> Maybe.map Url.toString
                |> Maybe.withDefault ""
    in
    div []
        [ Modal.config Close
            |> Modal.large
            |> Modal.hideOnBackdropClick True
            |> Modal.body []
                [ InputGroup.config
                    (InputGroup.text [ Input.disabled True, Input.placeholder "Name", Input.value name ])
                    |> InputGroup.view
                , br [] []
                , InputGroup.config
                    (InputGroup.text
                        [ Input.placeholder "Please paste correct youtube url"
                        , Input.value url
                        , Input.onInput UpdateUrl
                        ]
                    )
                    |> InputGroup.view
                ]
            |> Modal.footer []
                [ Button.submitButton
                    [ Button.primary
                    , Button.onClick Submit
                    , Button.disabled (not <| isJust model.video)
                    ]
                    [ text "Save" ]
                ]
            |> Modal.view model.visible
            |> Html.map mapper
        ]
