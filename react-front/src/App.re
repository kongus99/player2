[@react.component]
let make = () => {
  open Store;
  let selected = Wrapper.useSelector(Config.Selector.selected);
  let authorized = Wrapper.useSelector(Config.Selector.authorized);
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
             <Video.Modal.Edit id={v.id} title={v.title} videoId={v.videoId} />
             <Video.Delete id={v.id} />
           </>
         )}
      </ButtonGroup>
      {Belt_Option.mapWithDefault(selected, <div />, v =>
         <Player videoId={v.videoId} />
       )}
      <Player.Options />
      <Tabs defaultActiveKey="browse" id="noanim-tab-example">
        <Tab eventKey="browse" title="Browse"> <Video.List /> </Tab>
        <Tab eventKey="album" title="Album" disabled={selected == None}>
          {Belt_Option.mapWithDefault(selected, <div />, v =>
             <Album id={v.id} />
           )}
        </Tab>
      </Tabs>
    </>
  );
};
