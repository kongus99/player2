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
