module Video.Video exposing (Video, delete, get, parseId, post, put, toUrl)

import Http
import Json.Decode as Decode exposing (Decoder, int, list, nullable)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Regex
import RemoteData exposing (RemoteData(..), WebData)
import Url exposing (Url)


type alias Video =
    { id : Maybe Int
    , title : String
    , videoId : String
    }


parseId : String -> Maybe String
parseId videoUrl =
    Regex.fromString "v=([^&\\s]+)"
        |> Maybe.andThen
            (\r ->
                Regex.find r videoUrl
                    |> List.map .submatches
                    |> List.foldl List.append []
                    |> List.filterMap identity
                    |> List.head
            )


toUrl : String -> Maybe Url
toUrl videoId =
    "https://www.youtube.com/watch?v=" ++ videoId |> Url.fromString


url =
    "/api/video"


get : (WebData (List Video) -> msg) -> Cmd msg
get msg =
    Http.get
        { url = url
        , expect =
            list decode |> Http.expectJson (RemoteData.fromResult >> msg)
        }


post : (WebData (Maybe Int) -> c) -> Video -> Cmd c
post msg video =
    Http.post
        { url = url
        , body =
            encode video
                |> Http.jsonBody
        , expect = Http.expectJson (RemoteData.fromResult >> msg) (nullable int)
        }


delete : c -> Video -> Cmd c
delete msg video =
    video.id
        |> Maybe.map
            (\id ->
                Http.request
                    { method = "DELETE"
                    , headers = []
                    , url = url ++ "/" ++ String.fromInt id
                    , body = Http.emptyBody
                    , expect = Http.expectJson (RemoteData.fromResult >> (\_ -> msg)) (nullable int)
                    , timeout = Nothing
                    , tracker = Nothing
                    }
            )
        |> Maybe.withDefault Cmd.none


put : (WebData (Maybe Int) -> c) -> Video -> Cmd c
put msg video =
    Http.request
        { method = "PUT"
        , headers = []
        , url = url
        , body =
            encode video
                |> Http.jsonBody
        , expect = Http.expectJson (RemoteData.fromResult >> msg) (nullable int)
        , timeout = Nothing
        , tracker = Nothing
        }


encode : Video -> Encode.Value
encode video =
    Encode.object
        [ ( "id", Encode.int (Maybe.withDefault -1 video.id) )
        , ( "title", Encode.string video.title )
        , ( "videoId", Encode.string video.videoId )
        ]


decode : Decoder Video
decode =
    Decode.succeed Video
        |> required "id" (Decode.map Just Decode.int)
        |> required "title" Decode.string
        |> required "videoId" Decode.string
