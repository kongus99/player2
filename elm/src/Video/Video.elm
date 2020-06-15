module Video.Video exposing (..)

import Dict
import Http
import Json.Decode as Decode exposing (Decoder, int, list, nullable)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Login.Form as Form exposing (Form, Type(..), disabled, editable, fieldValidator, withSerializer, withValue)
import Regex
import RemoteData exposing (WebData)
import Set
import String exposing (fromInt)
import Url exposing (Url)
import Validation exposing (Validation)
import Validator
import Video.Album as Album exposing (Album)


type alias VideoData =
    { id : Int
    , title : String
    , videoId : String
    , album : Maybe Album
    }


type alias VerifiedVideo =
    { title : String
    , videoId : String
    }


type Video
    = Unverified Form
    | Verified Form
    | Persisted Int Form


toUrl : String -> Maybe Url
toUrl videoId =
    "https://www.youtube.com/watch?v=" ++ videoId |> Url.fromString


url =
    "/api/video"


videoIdRegexp =
    "v=([^&\\s]+)"


videoIdValidator : String -> Validation
videoIdValidator =
    Validator.regexpValidator videoIdRegexp (\_ -> "This url does not contain video id.")


parseId : String -> String
parseId videoUrl =
    Regex.fromString videoIdRegexp
        |> Maybe.andThen
            (\r ->
                Regex.find r videoUrl
                    |> List.map .submatches
                    |> List.foldl List.append []
                    |> List.filterMap identity
                    |> List.head
            )
        |> Maybe.withDefault ""



-- video states


unverified : Video
unverified =
    Unverified
        { fields =
            [ ( "videoUrl"
              , editable Nothing
                    (Form.Url "Video url")
                    [ fieldValidator Validator.url "videoUrl"
                    , fieldValidator videoIdValidator "videoUrl"
                    ]
                    |> withSerializer
                        (\( _, v ) -> ( "videoId", parseId v.value ))
              )
            ]
                |> Dict.fromList
        , order = [ "videoUrl" ]
        , excluded = Set.empty
        }


verified : ( Maybe Int, VerifiedVideo ) -> Video
verified ( mid, v ) =
    case mid of
        Just id ->
            persisted (VideoData id v.title v.videoId Nothing) Nothing

        Nothing ->
            Verified
                { fields =
                    [ ( "title"
                      , disabled (Form.Label "title" "Title") v.title
                      )
                    , ( "videoId"
                      , disabled (Form.Label "videoId" "Url") ("https://www.youtube.com/watch?v=" ++ v.videoId)
                            |> withSerializer (\( _, f ) -> ( "videoId", parseId f.value ))
                      )
                    ]
                        |> Dict.fromList
                , order = [ "title", "videoId" ]
                , excluded = Set.empty
                }


persisted : VideoData -> Maybe Album -> Video
persisted video album =
    Persisted video.id
        { fields =
            [ ( "title"
              , disabled (Form.Label "title" "Title") video.title
              )
            , ( "videoUrl"
              , disabled (Form.Label "videoUrl" "Url") ("https://www.youtube.com/watch?v=" ++ video.videoId)
              )
            , ( "album"
              , editable (Form.Label "album" "Album" |> Just) (TextArea 15) []
                    |> withSerializer (\( _, f ) -> ( "tracksString", f.value ))
                    |> (album |> Maybe.map (Album.toString >> withValue) |> Maybe.withDefault identity)
              )
            ]
                |> Dict.fromList
        , order = [ "title", "videoUrl", "album" ]
        , excluded = Set.fromList [ "title", "videoUrl" ]
        }



-- backend api


get : Int -> (WebData VideoData -> c) -> Cmd c
get id msg =
    Http.get
        { url = url ++ "/" ++ fromInt id
        , expect =
            decodeData
                |> Http.expectJson (RemoteData.fromResult >> msg)
        }


getAll : (WebData (List VideoData) -> msg) -> Cmd msg
getAll msg =
    Http.get
        { url = url
        , expect =
            list decodeData |> Http.expectJson (RemoteData.fromResult >> msg)
        }


delete : c -> Int -> Cmd c
delete msg id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = url ++ "/" ++ String.fromInt id
        , body = Http.emptyBody
        , expect = Http.expectJson (RemoteData.fromResult >> (\_ -> msg)) (nullable int)
        , timeout = Nothing
        , tracker = Nothing
        }


edit : ( String, String ) -> Video -> Video
edit new video =
    case video of
        Unverified f ->
            Unverified (Form.edit new f)

        Persisted id f ->
            Persisted id (Form.edit new f)

        _ ->
            video


decodeVerified : Decoder ( Maybe Int, VerifiedVideo )
decodeVerified =
    Decode.map2
        (\id -> \vid -> ( id, vid ))
        (Decode.field "id" (Decode.nullable Decode.int))
        (Decode.succeed VerifiedVideo
            |> required "title" Decode.string
            |> required "videoId" Decode.string
        )


decodeData : Decoder VideoData
decodeData =
    Decode.succeed VideoData
        |> required "id" Decode.int
        |> required "title" Decode.string
        |> required "videoId" Decode.string
        |> hardcoded Nothing
