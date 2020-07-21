type track = {
  title: string,
  start: int,
  _end: int,
  selected: bool,
};

type trackState =
  | Inactive
  | Seeking(track)
  | Active(track);

let tempEnd = Int32.max_int |> Int32.to_int;

type state = {
  tracks: Belt_MapInt.t(track),
  selected: array(track),
  playing: trackState,
};

type action =
  | Load(array(track))
  | Toggle(int)
  | UpdateTime(int)
  | Next
  | Prev;

let initial = {tracks: Belt_MapInt.empty, selected: [||], playing: Inactive};

let seek = track =>
  Belt_Option.mapWithDefault(track, Inactive, x => Seeking(x));

let firstTrack = ({selected}) => {
  selected->Belt_Array.get(0) |> seek;
};

let lastTrack = ({selected}) => {
  selected->Belt_Array.get(selected->Belt_Array.size - 1) |> seek;
};

let nextTrack = (start, {selected}) => {
  Array_Helper.next(~cyclic=true, t => t.start >= start, selected) |> seek;
};

let prevTrack = (start, {selected}) => {
  Array_Helper.next(
    ~cyclic=true,
    t => start >= t.start,
    selected |> Belt_Array.reverse,
  )
  |> seek;
};

//API
let isPlaying = (time, {start, _end}) => {
  start <= time && time < _end;
};

let getTrack = playing =>
  switch (playing) {
  | Inactive => None
  | Seeking(t) => Some(t)
  | Active(t) => Some(t)
  };

let reducer = (state, action) =>
  switch (action) {
  | Load(received) =>
    let tracks =
      Belt_MapInt.fromArray(Belt_Array.map(received, t => (t.start, t)));
    {
      tracks,
      selected:
        Belt_MapInt.keep(tracks, (_, {selected}) => selected)
        |> Belt_MapInt.valuesToArray,
      playing: Inactive,
    };
  | Toggle(start) =>
    let tracks =
      Belt_MapInt.update(state.tracks, start, mt =>
        Belt_Option.map(mt, t => {...t, selected: !t.selected})
      );
    {
      ...state,
      tracks,
      selected:
        Belt_MapInt.keep(tracks, (_, {selected}) => selected)
        |> Belt_MapInt.valuesToArray,
    };
  | UpdateTime(time) => {
      ...state,
      playing:
        switch (state.playing) {
        | Inactive => firstTrack(state)
        | Seeking(t) =>
          if (isPlaying(time, t)) {
            Active(t);
          } else {
            state.playing;
          }
        | Active(t) =>
          if (isPlaying(time, t)) {
            state.playing;
          } else {
            nextTrack(t.start, state);
          }
        },
    }

  | Next => {
      ...state,
      playing:
        switch (state.playing) {
        | Inactive => firstTrack(state)
        | Seeking(t) => nextTrack(t.start, state)
        | Active(t) => nextTrack(t.start, state)
        },
    }
  | Prev => {
      ...state,
      playing:
        switch (state.playing) {
        | Inactive => firstTrack(state)
        | Seeking(t) => prevTrack(t.start, state)
        | Active(t) => prevTrack(t.start, state)
        },
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
