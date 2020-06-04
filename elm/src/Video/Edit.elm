module Video.Edit exposing (..)

import Alert
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form as Form
import Bootstrap.Modal as Modal
import Html exposing (Html, text)
import Json.Decode
import Login.Form as Form exposing (resolveError)
import RemoteData exposing (WebData)
import Task
import Video.Album as Album exposing (Album)
import Video.Video as Video exposing (VerifiedVideo, Video(..), VideoData, decodeVerified, edit, persisted, unverified, verified)


type alias Model =
    { video : Video
    , alert : Alert.Model Alert.Msg
    , visible : Modal.Visibility
    }


init =
    { video = unverified, alert = Alert.init, visible = Modal.hidden }


type Msg
    = Submit
    | VerifiedVideo (WebData ( Maybe Int, VerifiedVideo ))
    | PersistedVideo (WebData Int)
    | AlbumSaved Int (WebData Int)
    | VideoFetched (WebData VideoData)
    | AlbumFetched VideoData (WebData (Maybe Album))
    | Edit String String
    | Open (Maybe Int)
    | Close
    | AlertMsg Alert.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        showFeedback m =
            Task.perform AlertMsg (Task.succeed m)

        resolveResponse errMsg successFunction response =
            case response of
                RemoteData.Failure err ->
                    ( model, resolveError [ ( 400, errMsg ) ] err |> Alert.Danger |> showFeedback )

                RemoteData.Success v ->
                    successFunction v

                _ ->
                    ( model, Cmd.none )
    in
    case msg of
        Submit ->
            ( model
            , case model.video of
                Unverified v ->
                    Form.get (\s -> "/api/verify?" ++ s) v (Form.expectJson VerifiedVideo decodeVerified)

                Verified v ->
                    Form.post Video.url v (Form.expectJson PersistedVideo Json.Decode.int)

                Persisted id v ->
                    Form.post (Album.url id) v (Form.expectJson (AlbumSaved id) Json.Decode.int)
            )

        VerifiedVideo response ->
            resolveResponse "Could not verify url."
                (\r -> ( { model | video = verified r }, Alert.Success "Video successfully verified." |> showFeedback ))
                response

        PersistedVideo response ->
            resolveResponse "Could not save video."
                (\videoId -> ( model, Cmd.batch [ Alert.Success "Video saved." |> showFeedback, Video.get videoId VideoFetched ] ))
                response

        AlbumSaved videoId response ->
            resolveResponse "Could not save album for this video"
                (\_ -> ( model, Cmd.batch [ Alert.Success "Album saved." |> showFeedback, Video.get videoId VideoFetched ] ))
                response

        VideoFetched response ->
            resolveResponse "Error fetching video."
                (\data -> ( { model | visible = Modal.shown, video = persisted data Nothing }, Album.get data.id (AlbumFetched data) ))
                response

        AlbumFetched video response ->
            resolveResponse "Error fetching album."
                (\album -> ( { model | visible = Modal.shown, video = persisted video album }, Cmd.none ))
                response

        Edit k v ->
            ( { model | video = edit ( k, v ) model.video }, Cmd.none )

        Open mid ->
            case mid of
                Just id ->
                    ( model, Video.get id VideoFetched )

                Nothing ->
                    ( { init | visible = Modal.shown, video = unverified }, Cmd.none )

        Close ->
            ( init, Cmd.none )

        AlertMsg m ->
            ( { model | alert = Alert.update m model.alert }, Cmd.none )


view : (Msg -> msg) -> Model -> Html msg
view mapper model =
    let
        modal form submit =
            let
                fields =
                    (Alert.view model.alert |> Html.map AlertMsg) :: (Form.view Edit form |> List.map (Form.group []))
            in
            Modal.config Close
                |> Modal.large
                |> Modal.hideOnBackdropClick True
                |> Modal.body []
                    [ Form.form [] fields
                    ]
                |> Form.footer Submit submit form
                |> Modal.view model.visible
                |> Html.map mapper
    in
    case model.video of
        Unverified form ->
            modal form "Verify"

        Verified form ->
            modal form "Save"

        Persisted _ form ->
            modal form "Update"


addButton : (Msg -> a) -> Html a
addButton mapper =
    Button.button [ Button.success, Button.onClick <| mapper <| Open Nothing ] [ text "+" ]


editButton : VideoData -> (Msg -> msg) -> ButtonGroup.ButtonItem msg
editButton video mapper =
    ButtonGroup.button [ Button.info, Button.small, Button.onClick <| mapper <| Open <| Just video.id ] [ text "Edit" ]
