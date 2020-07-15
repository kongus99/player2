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
  let selectedVideo = Wrapper.useSelector(Config.Selector.selected);
  let (tab, setTab) = React.useState(() => browseTab.eventKey);
  let (album, setAlbum) = React.useState(() => None);

  React.useEffect0(() => {
    Store.Config.fetchVideos(false, dispatch);
    None;
  });

  React.useEffect1(
    () => {
      Belt_Option.forEach(selectedVideo, v => {
        Album.fetch(
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
      Config.fetchVideos(true, dispatch);
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
