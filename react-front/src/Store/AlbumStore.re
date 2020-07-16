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
