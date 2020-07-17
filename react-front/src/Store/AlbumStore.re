type track = {
  title: string,
  start: int,
  _end: option(int),
};

type state = {
  tracks: Belt_MapInt.t(track),
  selected: Belt_SetInt.t,
};

type action =
  | Load(array(track))
  | Toggle(int);

let initial = {tracks: Belt_MapInt.empty, selected: Belt_SetInt.empty};

let reducer = (state, action) =>
  switch (action) {
  | Load(tracks) => {
      tracks:
        Belt_MapInt.fromArray(Belt_Array.map(tracks, t => (t.start, t))),
      selected: Belt_Array.map(tracks, t => t.start) |> Belt_SetInt.fromArray,
    }
  | Toggle(start) => {
      ...state,
      selected:
        Belt_SetInt.has(state.selected, start)
          ? Belt_SetInt.remove(state.selected, start)
          : Belt_SetInt.add(state.selected, start),
    }
  };

module Fetcher = {
  module Decode = {
    let track = json =>
      Json.Decode.{
        title: json |> field("title", string),
        start: json |> field("start", int),
        _end: json |> field("end", optional(int)),
      };
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
      onSuccess(Json.Decode.(json |> field("tracks", array(Decode.track))))
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
};
