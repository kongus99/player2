type tabData = {
  eventKey: string,
  title: string,
};
let browseTab = {eventKey: "browse", title: "Browse"};
let albumTab = {eventKey: "album", title: "Album"};

[@react.component]
let make = () => {
  open Store;
  let selectedVideo = Wrapper.useSelector(Config.Selector.selected);
  let (tab, setTab) = React.useState(() => browseTab.eventKey);
  let dispatcher = Wrapper.useDispatch();

  let onSelect = k => {
    if (k == browseTab.eventKey) {
      Config.fetchVideos(true, dispatcher);
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
        disabled={selectedVideo == None}>
        {Belt_Option.mapWithDefault(selectedVideo, <div />, v =>
           <Album id={v.id} />
         )}
      </Tab>
    </Tabs>
  );
};
