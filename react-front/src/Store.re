module Video = {
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
};

module Implementation = {
  open Video;
  type state = {
    authorized: bool,
    selected: option(video),
    videos: array(video),
    options,
  };

  type action =
    | Authorize(bool)
    | Select(video)
    | Load(bool, array(video))
    | Next
    | Toggle(options => options);

  let reducer = (state, action) =>
    switch (action) {
    | Authorize(authorized) => {...state, authorized}
    | Select(v) => {...state, selected: Some(v)}
    | Load(keepSelected, videos) =>
      if (keepSelected
          && state.selected
             ->Belt_Option.mapWithDefault(false, sel =>
                 Array.exists(vid => sel.id == vid.id, videos)
               )) {
        {...state, videos};
      } else {
        {...state, videos, selected: None};
      }
    | Next => {
        ...state,
        selected:
          state.selected
          ->Belt_Option.flatMap(v => next(state.options, v, state.videos)),
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

  module Selector = {
    let authorized = state => state.authorized;
    let options = state => state.options;
    let selected = state => state.selected;
    let videos = state => state.videos;
  };
};
include Implementation;
module Wrapper = {
  include ReductiveContext.Make(Implementation);
};
