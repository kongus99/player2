module Video.Edit exposing (..)

import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Modal as Modal
import Extra exposing (isJust)
import Html exposing (Html, div, text)
import Process
import RemoteData exposing (WebData)
import Task
import Url
import Validation exposing (Validation(..), feedback, status)
import Video.Video as Video exposing (Video)


type alias Model =
    { visible : Modal.Visibility, submitted : Bool, url : String, videoId : Maybe String, video : Maybe Video }


init =
    { visible = Modal.hidden, submitted = False, url = "", videoId = Nothing, video = Nothing }


resetSubmitted model =
    { model | submitted = False }


setVideo : Model -> Video -> Model
setVideo model video =
    { model
        | url =
            Video.toUrl video.videoId
                |> Maybe.map Url.toString
                |> Maybe.withDefault ""
        , videoId = Just video.videoId
    }


type Msg
    = Close
    | Open (Maybe Video)
    | Submit
    | Submitted (WebData (Maybe Int))
    | Verified (WebData Video)
    | ChangeUrl String
    | VerifyUrl ()


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
            ( video |> Maybe.map (setVideo openModal) |> Maybe.withDefault openModal, Task.succeed () |> Task.perform VerifyUrl )

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

        ChangeUrl url ->
            let
                parsed =
                    Video.parseId url
            in
            ( { model | url = url, videoId = parsed, video = Maybe.andThen (\_ -> model.video) parsed }
            , Process.sleep 1000 |> Task.perform VerifyUrl
            )

        VerifyUrl _ ->
            ( model
            , model.videoId
                |> Maybe.map
                    (\u -> Video.verify u Verified)
                |> Maybe.withDefault Cmd.none
            )

        Submitted _ ->
            ( { model | visible = Modal.hidden, submitted = True, video = Nothing }, Cmd.none )

        Verified webData ->
            let
                video =
                    case webData of
                        RemoteData.Success v ->
                            Just v

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


validate model =
    if String.trim model.url |> String.isEmpty then
        ( Indeterminate, Indeterminate )

    else if not <| isJust model.videoId then
        ( Indeterminate, Invalid ("No video id found in " ++ model.url) )

    else if not <| isJust model.video then
        ( Invalid "", Invalid ("Incorrect video id " ++ Maybe.withDefault "" model.videoId) )

    else
        ( Valid, Valid )


modal : (Msg -> msg) -> Model -> Html msg
modal mapper model =
    let
        name =
            model.video |> Maybe.map .title |> Maybe.withDefault ""

        ( upper, lower ) =
            validate model
    in
    div []
        [ Modal.config Close
            |> Modal.large
            |> Modal.hideOnBackdropClick True
            |> Modal.body []
                [ Form.form []
                    [ Form.form []
                        [ Form.group []
                            [ Form.label [] [ text "Title" ]
                            , Input.text
                                [ upper |> status
                                , Input.readonly True
                                , Input.placeholder "Name"
                                , Input.value name
                                ]
                            ]
                        , Form.group []
                            [ Form.label [] [ text "Url" ]
                            , Input.text
                                [ lower |> status
                                , Input.placeholder "Please enter correct youtube url"
                                , Input.value model.url
                                , Input.onInput ChangeUrl
                                ]
                            , lower |> feedback
                            ]
                        ]
                    ]
                ]
            |> Modal.footer []
                (if Extra.isJust model.video then
                    [ Button.submitButton
                        [ Button.primary
                        , Button.onClick Submit
                        ]
                        [ text "Save" ]
                    ]

                 else
                    []
                )
            |> Modal.view model.visible
            |> Html.map mapper
        ]
