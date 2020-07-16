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
