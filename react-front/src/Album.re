type track = {
  title: string,
  start: int,
  _end: option(int),
};

type album = {tracks: array(track)};

module Decode = {
  let track = json =>
    Json.Decode.{
      title: json |> field("title", string),
      start: json |> field("start", int),
      _end: json |> field("end", optional(int)),
    };
  let album = json =>
    Json.Decode.{tracks: json |> field("tracks", array(track))};
};

module Encode = {
  let album = tracks =>
    Json.Encode.(object_([("tracksString", string(tracks))]));
};

let toString = ({tracks}) => {
  let formatTime = t =>
    [t / 3600, t / 60 mod 60, t mod 60]
    |> List.map(t =>
         [t / 10, t mod 10] |> List.map(string_of_int) |> String.concat("")
       )
    |> String.concat(":");
  tracks
  ->Belt_Array.map(t => {formatTime(t.start) ++ " " ++ t.title})
  ->Belt_List.fromArray
  |> String.concat("\n");
};

let fetch = (id, onError, onSuccess) =>
  Fetcher.get(
    "/api/video/" ++ string_of_int(id) ++ "/album",
    [],
    Fetcher.statusResolver(
      [|(404, "Could not find album.")|],
      onError,
      Fetch.Response.json,
    ),
    json =>
    onSuccess(json |> Decode.album)
  );

let post = (id, album, onError, onSuccess) =>
  Fetcher.post(
    "/api/video/" ++ string_of_int(id) ++ "/album",
    Encode.album(album),
    Fetcher.statusResolver(
      [|(400, "Could not save album.")|],
      onError,
      Fetch.Response.text,
    ),
    t =>
    onSuccess(int_of_string(t))
  );

[@react.component]
let make = (~album: album) => {
  let (title, setTitle) = React.useState(() => None);

  Bootstrap.(
    <ListGroup>
      {album.tracks
       |> Array.map(t => {
            <ListGroup.Item
              key={t.title}
              action=true
              active={Some(t.title) == title}
              onClick={_ => setTitle(_ => Some(t.title))}>
              {ReasonReact.string(t.title)}
            </ListGroup.Item>
          })
       |> React.array}
    </ListGroup>
  );
};
