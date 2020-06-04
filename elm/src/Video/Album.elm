module Video.Album exposing (..)

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (hardcoded, required)
import RemoteData exposing (WebData)
import Set exposing (Set)
import String exposing (fromInt)


type alias TrackTime =
    { now : Int, length : Int }


type alias Track =
    { title : String
    , end : Maybe Int
    }


type alias Album =
    { selected : Set Int
    , tracks : Dict Int Track
    }


url id =
    "/api/video/" ++ String.fromInt id ++ "/album"


get : Int -> (WebData (Maybe Album) -> c) -> Cmd c
get id msg =
    Http.get
        { url = url id
        , expect =
            Decode.nullable decodeAlbum
                |> Http.expectJson (RemoteData.fromResult >> msg)
        }


decodeTrack : Decoder ( Int, Track )
decodeTrack =
    Decode.succeed (\x -> \y -> \z -> ( x, y, z ))
        |> required "start" Decode.int
        |> required "end" (Decode.nullable Decode.int)
        |> required "title" Decode.string
        |> Decode.map (\( start, end, title ) -> ( start, Track title end ))


decodeAlbum : Decoder Album
decodeAlbum =
    Decode.succeed Album
        |> hardcoded Set.empty
        |> required "tracks" (Decode.list decodeTrack |> Decode.map Dict.fromList)


toString : Album -> String
toString album =
    let
        formatTime s =
            [ s // 3600, modBy 60 (s // 60), modBy 60 s ]
                |> List.map (\t -> String.padLeft 2 '0' <| String.fromInt t)
                |> String.join ":"
    in
    album.tracks
        |> Dict.toList
        |> List.map
            (\( s, { title } ) -> formatTime s ++ " " ++ title)
        |> String.join "\n"


init : Album
init =
    Album Set.empty Dict.empty


toggle : Int -> Album -> Album
toggle start album =
    if album.selected |> Set.member start then
        { album | selected = Set.remove start album.selected }

    else
        { album | selected = Set.insert start album.selected }


find : Album -> Int -> Maybe ( Int, Track )
find album start =
    Dict.get start album.tracks |> Maybe.map (\t -> ( start, t ))


firstTrack : List Int -> Album -> Maybe ( Int, Track )
firstTrack list album =
    list
        |> List.head
        |> Maybe.andThen (find album)


lastTrack : List Int -> Album -> Maybe ( Int, Track )
lastTrack list =
    firstTrack (List.reverse list)


active : Int -> Album -> Bool
active start album =
    album.selected |> Set.member start


ending : TrackTime -> Track -> Int
ending trackTime track =
    track.end |> Maybe.withDefault trackTime.length


isCurrentlyPlaying : TrackTime -> ( Int, Track ) -> Bool
isCurrentlyPlaying trackTime ( start, track ) =
    trackTime.now >= start && trackTime.now < ending trackTime track


playing : TrackTime -> Album -> Maybe ( Int, Track )
playing trackTime album =
    (case album.selected |> Set.partition (\s -> s < trackTime.now) |> Tuple.mapBoth Set.toList Set.toList of
        ( [], [] ) ->
            Nothing

        ( [], x :: _ ) ->
            Just x

        ( x :: [], [] ) ->
            Just x

        ( lesser, [] ) ->
            let
                maybeFirst =
                    firstTrack lesser album

                maybeLast =
                    lastTrack lesser album
            in
            Maybe.map2
                (\first ->
                    \last ->
                        if trackTime.now < ending trackTime (Tuple.second last) then
                            Tuple.first last

                        else
                            Tuple.first first
                )
                maybeFirst
                maybeLast

        ( lesser, greater ) ->
            let
                maybeNext =
                    firstTrack greater album

                maybeCurrent =
                    lastTrack lesser album
            in
            Maybe.map2
                (\current ->
                    \next ->
                        if trackTime.now < ending trackTime (Tuple.second current) then
                            Tuple.first current

                        else
                            Tuple.first next
                )
                maybeCurrent
                maybeNext
    )
        |> Maybe.andThen (find album)
