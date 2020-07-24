module Video.Album exposing (..)

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import RemoteData exposing (WebData)
import Set exposing (Set)
import String


type alias TrackTime =
    { now : Int
    , length : Int
    }


type alias Track =
    { title : String
    , end : Maybe Int
    }


type alias TrackData =
    { start : Int
    , end : Int
    , isActive : Bool
    , title : String
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
    Decode.field "tracks"
        (Decode.list decodeTrack
            |> Decode.map (\l -> Album (l |> List.map Tuple.first |> Set.fromList) (Dict.fromList l))
        )


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


toggleAll : Bool -> Album -> Album
toggleAll include album =
    if include then
        { album | selected = album.tracks |> Dict.toList |> List.map Tuple.first |> Set.fromList }

    else
        { album | selected = Set.empty }


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


isCurrentlyPlaying : TrackTime -> TrackData -> Bool
isCurrentlyPlaying { now } { start, end } =
    now >= start && now < end


trackData trackTime album ( start, track ) =
    TrackData start
        (track.end |> Maybe.withDefault trackTime.length)
        (album.selected |> Set.member start)
        track.title


tracksData : Album -> TrackTime -> List TrackData
tracksData album trackTime =
    album.tracks |> Dict.toList |> List.map (trackData trackTime album)


playing : TrackTime -> Album -> Maybe TrackData
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
        |> Maybe.map (trackData trackTime album)
