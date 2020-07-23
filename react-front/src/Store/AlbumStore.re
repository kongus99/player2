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
  | Toggle(option(int))
  | Duration(int)
  | UpdateTime(int)
  | Next
  | Prev
  | First
  | Last;

let initial = {tracks: Belt_MapInt.empty, selected: [||], playing: Inactive};

let seek = track =>
  Belt_Option.mapWithDefault(track, Inactive, x => Seeking(x));

let firstTrack = ({selected}) => {
  selected->Belt_Array.get(0) |> seek;
};

let lastTrack = ({selected}) => {
  selected->Belt_Array.get(selected->Belt_Array.size - 1) |> seek;
};

let nextTrack = ({start}, {selected}) => {
  Helper.Array.next(~cyclic=true, t => t.start >= start, selected) |> seek;
};

let prevTrack = ({start}, {selected}) => {
  Helper.Array.next(
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

let reducer = (state, action) => {
  let mapTrack = (f, track) =>
    switch (track) {
    | Seeking(t) => f(t, state)
    | Active(t) => f(t, state)
    | x => x
    };
  let generateSelected = tracks =>
    Belt_MapInt.keep(tracks, (_, {selected}: track) => selected)
    |> Belt_MapInt.valuesToArray;
  let toggle = (t: track) => {...t, selected: !t.selected};

  switch (action) {
  | Load(received) =>
    let tracks =
      Belt_MapInt.fromArray(Belt_Array.map(received, t => (t.start, t)));
    {tracks, selected: generateSelected(tracks), playing: Inactive};
  | Toggle(start) =>
    let (playing, tracks) = {
      switch (start) {
      | Some(s) => (
          mapTrack(
            (t, st) => t.start == s ? nextTrack(t, st) : st.playing,
            state.playing,
          ),
          Belt_MapInt.update(state.tracks, s, mt =>
            Belt_Option.map(mt, toggle)
          ),
        )
      | None =>
        let s =
          getTrack(state.playing)
          ->Belt_Option.mapWithDefault(-1, t => t.start);
        let tracks =
          Belt_MapInt.map(state.tracks, t => t.start == s ? t : toggle(t));
        (state.playing, tracks);
      };
    };
    let selected = generateSelected(tracks);
    if (Belt_Array.size(selected) > 0) {
      {tracks, selected, playing};
    } else {
      state;
    };
  | Duration(time) =>
    Belt_MapInt.maximum(state.tracks)
    ->Belt_Option.mapWithDefault(
        state,
        ((_, max)) => {
          let last = {...max, _end: time};
          let tracks =
            Belt_MapInt.update(state.tracks, last.start, _ => Some(last));
          let playing =
            mapTrack(
              (t, _) => t.start == last.start ? Seeking(last) : Seeking(t),
              state.playing,
            );
          {tracks, playing, selected: generateSelected(tracks)};
        },
      )
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
            nextTrack(t, state);
          }
        },
    }

  | Next => {...state, playing: mapTrack(nextTrack, state.playing)}
  | Prev => {...state, playing: mapTrack(prevTrack, state.playing)}
  | First => {...state, playing: firstTrack(state)}
  | Last => {...state, playing: lastTrack(state)}
  };
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
