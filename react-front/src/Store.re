module AlbumStore = {
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
};

module VideoStore = {
  type video = {
    id: int,
    title: string,
    videoId: string,
  };

  type options = {
    loop: bool,
    play: bool,
    playlist: bool,
  };

  type state = {
    selected: option(video),
    loaded: array(video),
    options,
  };

  type action =
    | Select(video)
    | Load(bool, array(video))
    | Next
    | Toggle(options => options);

  module Decode = {
    let video = json =>
      Json.Decode.{
        id: json |> field("id", int),
        title: json |> field("title", string),
        videoId: json |> field("videoId", string),
      };
  };

  let next = ({playlist, loop}, v, videos) => {
    playlist
      ? Array_Helper.find(~cyclic=loop, e => e.id == v.id, videos) : Some(v);
  };

  let fetch = onSuccess =>
    Fetcher.get(
      "/api/video",
      [],
      Fetcher.statusResolver([||], _ => (), Fetch.Response.json),
      json =>
      onSuccess(json |> Json.Decode.array(Decode.video))
    );
  let initial = {
    selected: None,
    loaded: [||],
    options: {
      loop: true,
      play: true,
      playlist: false,
    },
  };
  let reducer = (state, action) =>
    switch (action) {
    | Select(v) => {...state, selected: Some(v)}
    | Load(keepSelected, loaded) =>
      if (keepSelected
          && state.selected
             ->Belt_Option.mapWithDefault(false, sel =>
                 Array.exists(vid => sel.id == vid.id, loaded)
               )) {
        {...state, loaded};
      } else {
        {...state, loaded, selected: None};
      }
    | Next => {
        ...state,
        selected:
          state.selected
          ->Belt_Option.flatMap(v => next(state.options, v, state.loaded)),
      }
    | Toggle(f) => {...state, options: f(state.options)}
    };
};

module Implementation = {
  type state = {
    authorized: bool,
    videoState: VideoStore.state,
  };

  type action =
    | Authorize(bool)
    | VideoAction(VideoStore.action);

  let reducer = (state, action) =>
    switch (action) {
    | Authorize(authorized) => {...state, authorized}
    | VideoAction(vid) => {
        ...state,
        videoState: VideoStore.reducer(state.videoState, vid),
      }
    };
  let store =
    Reductive.Store.create(
      ~reducer,
      ~preloadedState={authorized: false, videoState: VideoStore.initial},
      (),
    );

  module Selector = {
    let authorized = state => state.authorized;
    module VideoStore = {
      let options = state => state.videoState.options;
      let selected = state => state.videoState.selected;
      let loaded = state => state.videoState.loaded;
    };
  };
};
include Implementation;
module Wrapper = {
  include ReductiveContext.Make(Implementation);
};
