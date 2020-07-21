module Nav = {
  type tabData = {
    eventKey: string,
    title: string,
  };
  let browseTab = {eventKey: "browse", title: "Browse"};
  let albumTab = {eventKey: "album", title: "Album"};

  [@react.component]
  let make = () => {
    open Store;
    let dispatch = Wrapper.useDispatch();
    let selectedVideo = Wrapper.useSelector(Selector.VideoStore.selected);
    let (tab, setTab) = React.useState(() => browseTab.eventKey);
    let tracks = Wrapper.useSelector(Selector.AlbumStore.tracks);

    React.useEffect0(() => {
      VideoStore.Fetcher.fetch(v =>
        dispatch(VideoAction(VideoStore.Load(false, v)))
      );
      None;
    });

    React.useEffect1(
      () => {
        Belt_Option.forEach(selectedVideo, v => {
          AlbumStore.Fetcher.fetch(
            v.id,
            m =>
              Belt_Option.map(m, _ =>
                dispatch(AlbumAction(AlbumStore.Load([||])))
              ),
            tracks => dispatch(AlbumAction(AlbumStore.Load(tracks))),
          )
        });
        None;
      },
      [|selectedVideo|],
    );

    let onSelect = k => {
      if (k == browseTab.eventKey) {
        VideoStore.Fetcher.fetch(v =>
          dispatch(VideoAction(VideoStore.Load(true, v)))
        );
      };
      setTab(_ => k);
    };

    Bootstrap.(
      <Tabs activeKey=tab onSelect id="nav-tabs">
        <Tab eventKey={browseTab.eventKey} title={browseTab.title}>
          <Player.Options />
          <Video.List />
        </Tab>
        <Tab
          eventKey={albumTab.eventKey}
          title={albumTab.title}
          disabled={Belt_MapInt.isEmpty(tracks)}>
          <Album.Controls />
          <Album />
        </Tab>
      </Tabs>
    );
  };
};

module App = {
  [@react.component]
  let make = () => {
    open Store;
    let selected = Wrapper.useSelector(Selector.VideoStore.selected);
    let authorized = Wrapper.useSelector(Selector.authorized);
    Bootstrap.(
      <>
        <ButtonGroup>
          <Authorize />
          {if (authorized) {
             <Video.Modal.Add />;
           } else {
             <div />;
           }}
          {Belt_Option.mapWithDefault(selected, <div />, v =>
             <>
               <Video.Modal.Edit
                 id={v.id}
                 title={v.title}
                 videoId={v.videoId}
               />
               <Video.Delete id={v.id} />
             </>
           )}
        </ButtonGroup>
        {Belt_Option.mapWithDefault(selected, <div />, v =>
           <Player videoId={v.videoId} />
         )}
        <Nav />
      </>
    );
  };
};

ReactDOMRe.renderToElementWithId(
  <Store.Wrapper.Provider store=Store.store> <App /> </Store.Wrapper.Provider>,
  "app",
);
