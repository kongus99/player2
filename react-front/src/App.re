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
           <Video.Modal.Edit id={v.id} title={v.title} videoId={v.videoId} />
         )}
      </ButtonGroup>
      {Belt_Option.mapWithDefault(selected, <div />, v =>
         <Player videoId={v.videoId} />
       )}
      <Player.Options />
      <Video.List />
    </>
  );
};
