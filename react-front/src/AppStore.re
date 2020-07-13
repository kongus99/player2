type video = {
  id: int,
  title: string,
  videoId: string,
};

type appState = {selected: option(video)};
type appAction =
  | Select(video);

let appReducer = (_, action) =>
  switch (action) {
  | Select(v) => {selected: Some(v)}
  };

let appStore =
  Reductive.Store.create(
    ~reducer=appReducer,
    ~preloadedState={selected: None},
    (),
  );

module StoreWrapper = {
  include ReductiveContext.Make({
    type action = appAction;
    type state = appState;
  });
};
