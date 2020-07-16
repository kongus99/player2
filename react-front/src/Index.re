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
    let (album, setAlbum) = React.useState(() => None);

    React.useEffect0(() => {
      VideoStore.fetch(v =>
        dispatch(VideoAction(VideoStore.Load(false, v)))
      );
      None;
    });

    React.useEffect1(
      () => {
        Belt_Option.forEach(selectedVideo, v => {
          AlbumStore.fetch(
            v.id,
            m => Belt_Option.map(m, _ => setAlbum(_ => None)),
            album => setAlbum(_ => Some(album)),
          )
        });
        None;
      },
      [|selectedVideo|],
    );

    let onSelect = k => {
      if (k == browseTab.eventKey) {
        VideoStore.fetch(v =>
          dispatch(VideoAction(VideoStore.Load(true, v)))
        );
      };
      setTab(_ => k);
    };

    Bootstrap.(
      <Tabs activeKey=tab onSelect id="nav-tabs">
        <Tab eventKey={browseTab.eventKey} title={browseTab.title}>
          <Video.List />
        </Tab>
        <Tab
          eventKey={albumTab.eventKey}
          title={albumTab.title}
          disabled={album == None}>
          {Belt_Option.mapWithDefault(album, <div />, a => <Album album=a />)}
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
        <Player.Options />
        <Nav />
      </>
    );
  };
};

ReactDOMRe.renderToElementWithId(
  <Store.Wrapper.Provider store=Store.store> <App /> </Store.Wrapper.Provider>,
  "app",
);
