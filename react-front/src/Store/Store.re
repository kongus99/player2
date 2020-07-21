module Implementation = {
  type state = {
    authorized: bool,
    videoState: VideoStore.state,
    albumState: AlbumStore.state,
  };

  type action =
    | Authorize(bool)
    | VideoAction(VideoStore.action)
    | AlbumAction(AlbumStore.action);

  let reducer = (state, action) =>
    switch (action) {
    | Authorize(authorized) => {...state, authorized}
    | VideoAction(a) => {
        ...state,
        videoState: VideoStore.reducer(state.videoState, a),
      }
    | AlbumAction(a) => {
        ...state,
        albumState: AlbumStore.reducer(state.albumState, a),
      }
    };
  let store =
    Reductive.Store.create(
      ~reducer,
      ~preloadedState={
        authorized: false,
        videoState: VideoStore.initial,
        albumState: AlbumStore.initial,
      },
      (),
    );

  module Selector = {
    let authorized = state => state.authorized;
    module VideoStore = {
      let options = state => state.videoState.options;
      let selected = state => state.videoState.selected;
      let loaded = state => state.videoState.loaded;
    };
    module AlbumStore = {
      let tracks = state => state.albumState.tracks;
      let playing = state => state.albumState.playing;
    };
  };
};
include Implementation;
module Wrapper = {
  include ReductiveContext.Make(Implementation);
};
