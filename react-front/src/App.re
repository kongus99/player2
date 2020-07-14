[@react.component]
let make = () => {
  let (authorized, setAuthorized) = React.useState(() => false);
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
      <VideoStore.Wrapper.Provider store=VideoStore.Config.store>
        <Video.List />
      </VideoStore.Wrapper.Provider>
    </>
  );
};
