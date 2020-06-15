port module Video.List exposing (..)

import Extra exposing (resolveFetch)
import Html exposing (..)
import Login.Login as Login
import RemoteData exposing (RemoteData(..), WebData)
import TextFilter exposing (TextFilter)
import Video.Options as Options exposing (Option(..), Options)
import Video.Player as Player exposing (Msg(..))
import Video.Video as Video exposing (Video, VideoData)


port videoStatus : (( String, Float ) -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    Player.subscriptions |> Sub.map PlayerUpdate


type alias Model =
    { videos : List VideoData
    , player : Player.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model [] (Player.init Options.init []), Video.getAll Fetched )


view : Login.Model -> Model -> Html Msg
view login model =
    Player.view login model.player |> Html.map PlayerUpdate


type Msg
    = PlayerUpdate Player.Msg
    | Fetch
    | Fetched (WebData (List VideoData))


update : TextFilter -> Options -> Msg -> Model -> ( Model, Cmd Msg )
update filter options msg model =
    case msg of
        Fetch ->
            ( { model | videos = [] }, Video.getAll Fetched )

        Fetched response ->
            let
                fetched =
                    resolveFetch response []
            in
            ( { model
                | videos = fetched
                , player =
                    fetched
                        |> List.filter
                            (\v -> TextFilter.apply filter v.title)
                        |> Player.init options
              }
            , Cmd.none
            )

        PlayerUpdate m ->
            let
                refresh =
                    case m of
                        Delete v ->
                            Video.delete Fetch v

                        _ ->
                            Cmd.none

                ( player, cmd ) =
                    Player.update m model.player
            in
            ( { model | player = player }, [ Cmd.map PlayerUpdate cmd, refresh ] |> Cmd.batch )
