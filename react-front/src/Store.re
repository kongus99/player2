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

module Decode = {
  let video = json =>
    Json.Decode.{
      id: json |> field("id", int),
      title: json |> field("title", string),
      videoId: json |> field("videoId", string),
    };
};

let nextVideo = ({playlist, loop}, v, videos) => {
  playlist
    ? Array_Helper.find(~cyclic=loop, e => e.id == v.id, videos) : Some(v);
};

module Config = {
  type state = {
    authorized: bool,
    selected: option(video),
    videos: array(video),
    options,
  };

  module Selector = {
    let authorized = state => state.authorized;
    let options = state => state.options;
    let selected = state => state.selected;
    let videos = state => state.videos;
  };

  type action =
    | Authorize(bool)
    | Select(video)
    | Load(bool, Js.Json.t)
    | Next
    | Toggle(options => options);

  let fetchVideos = (keepSelected, dispatch) =>
    Fetcher.get(
      "/api/video",
      [],
      Fetcher.statusResolver([||], _ => (), Fetch.Response.json),
      json =>
      dispatch(Load(keepSelected, json))
    );

  let reducer = (state, action) =>
    switch (action) {
    | Authorize(authorized) => {...state, authorized}
    | Select(v) => {...state, selected: Some(v)}
    | Load(keepSelected, json) =>
      let videos = json |> Json.Decode.array(Decode.video);
      if (keepSelected
          && state.selected
             ->Belt_Option.mapWithDefault(false, sel =>
                 Array.exists(vid => sel.id == vid.id, videos)
               )) {
        {...state, videos};
      } else {
        {...state, videos, selected: None};
      };
    | Next => {
        ...state,
        selected:
          state.selected
          ->Belt_Option.flatMap(v =>
              nextVideo(state.options, v, state.videos)
            ),
      }
    | Toggle(f) => {...state, options: f(state.options)}
    };
  let store =
    Reductive.Store.create(
      ~reducer,
      ~preloadedState={
        authorized: false,
        selected: None,
        videos: [||],
        options: {
          loop: true,
          play: true,
          playlist: false,
        },
      },
      (),
    );
};

module Wrapper = {
  include ReductiveContext.Make(Config);
};
