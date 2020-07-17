type track = {
  title: string,
  start: int,
  _end: int,
  selected: bool,
};

let tempEnd = Int32.max_int |> Int32.to_int;

type state = {
  tracks: Belt_MapInt.t(track),
  active: option(int),
};

type action =
  | Load(array(track))
  | Toggle(int)
  | UpdateTime(int);

let initial = {tracks: Belt_MapInt.empty, active: None};

let reducer = (state, action) =>
  switch (action) {
  | Load(tracks) => {
      tracks:
        Belt_MapInt.fromArray(Belt_Array.map(tracks, t => (t.start, t))),
      active: None,
    }
  | Toggle(start) => {
      ...state,
      tracks:
        Belt_MapInt.update(state.tracks, start, mt =>
          Belt_Option.map(mt, t => {...t, selected: !t.selected})
        ),
    }
  | UpdateTime(time) => {
      ...state,
      active:
        Belt_MapInt.findFirstBy(state.tracks, (_, {start, _end}) =>
          start <= time && time <= _end
        )
        ->Belt_Option.map(((_, {start})) => start),
    }
  };

module Fetcher = {
  module Decode = {
    let track = json =>
      Json.Decode.{
        title: json |> field("title", string),
        start: json |> field("start", int),
        _end:
          (json |> field("end", optional(int)))
          ->Belt_Option.getWithDefault(tempEnd),
        selected: true,
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
