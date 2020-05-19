module Video.Album exposing (..)

import Dict exposing (Dict)
import Set exposing (Set)
import Video.Video exposing (Video)


type alias Track =
    { title : String
    , end : Float
    }


type alias Album =
    { video : Video
    , selected : Set Float
    , tracks : Dict Float Track
    }


init : Video -> Album
init video =
    Album video Set.empty Dict.empty


mock : Album -> Float -> Album
mock album end =
    let
        starts =
            [ 0, end / 4, end / 2, 3 * end / 4 ]

        ends =
            starts |> List.tail |> Maybe.withDefault [] |> List.reverse |> (::) end |> List.reverse

        tracks =
            List.map2 (\s -> \e -> ( s, Track (String.fromFloat s) e )) starts ends |> Dict.fromList
    in
    Album album.video (Dict.keys tracks |> Set.fromList) tracks


toggle : Float -> Album -> Album
toggle start album =
    if album.selected |> Set.member start then
        { album | selected = Set.remove start album.selected }

    else
        { album | selected = Set.insert start album.selected }


find : Album -> Float -> Maybe ( Float, Track )
find album start =
    Dict.get start album.tracks |> Maybe.map (\t -> ( start, t ))


firstTrack : List Float -> Album -> Maybe ( Float, Track )
firstTrack list album =
    list
        |> List.head
        |> Maybe.andThen (find album)


lastTrack : List Float -> Album -> Maybe ( Float, Track )
lastTrack list =
    firstTrack (List.reverse list)


active : Float -> Album -> Bool
active start album =
    album.selected |> Set.member start


playing : Float -> Album -> Maybe ( Float, Track )
playing now album =
    (case album.selected |> Set.partition (\s -> s < now) |> Tuple.mapBoth Set.toList Set.toList of
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
                        if now < (Tuple.second last).end then
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
                        if now < (Tuple.second current).end then
                            Tuple.first current

                        else
                            Tuple.first next
                )
                maybeCurrent
                maybeNext
    )
        |> Maybe.andThen (find album)
