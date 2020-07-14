[@react.component]
let make = () => {
  open VideoStore;
  let (authorized, setAuthorized) = React.useState(() => false);
  let selected = Wrapper.useSelector(Config.Selector.selected);
  Bootstrap.(
    <>
      <ButtonGroup>
        <Authorize onAuthorize={v => setAuthorized(_ => v)} />
        {if (authorized) {
           <Video.Modal.Add />;
         } else {
           <div />;
         }}
      </ButtonGroup>
      //        {switch (state) {
      //         | Loaded(Some(id), videos) =>
      //           videos
      //           ->Belt_Array.getBy(v => v.id == id)
      //           ->Belt_Option.mapWithDefault(<div />, v =>
      //               <Video.Edit id={v.id} title={v.title} videoId={v.videoId} />
      //             )
      //         | _ => <div />
      //         }}
      {Belt_Option.mapWithDefault(selected, <div />, v =>
         <Player videoId={v.videoId} />
       )}
      <Player.Options />
      <Video.List />
    </>
  );
};
