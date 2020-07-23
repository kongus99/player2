module Controls = {
  [@react.component]
  let make = () => {
    open Store;
    open AlbumStore;
    let dispatch = Wrapper.useDispatch();

    Bootstrap.(
      <>
        <ButtonGroup size="sm" className="btn-block">
          <Button
            variant="primary" onClick={_ => dispatch(AlbumAction(First))}>
            {React.string("|<")}
          </Button>
          <Button
            variant="primary" onClick={_ => dispatch(AlbumAction(Prev))}>
            {React.string("<<")}
          </Button>
          <Button
            variant="primary"
            onClick={_ => dispatch(AlbumAction(Toggle(None)))}>
            {React.string("Toggle")}
          </Button>
          <Button
            variant="primary" onClick={_ => dispatch(AlbumAction(Next))}>
            {React.string(">>")}
          </Button>
          <Button
            variant="primary" onClick={_ => dispatch(AlbumAction(Last))}>
            {React.string(">|")}
          </Button>
        </ButtonGroup>
      </>
    );
  };
};

[@react.component]
let make = () => {
  open Store;
  open AlbumStore;
  let dsipatch = Wrapper.useDispatch();
  let tracks = Wrapper.useSelector(Selector.AlbumStore.tracks);
  let playing = Wrapper.useSelector(Selector.AlbumStore.playing);

  let variant = track =>
    if (Belt_Option.mapWithDefault(getTrack(playing), false, a =>
          track.start == a.start
        )) {
      "success";
    } else if (track.selected) {
      "primary";
    } else {
      "secondary";
    };
  Bootstrap.(
    <ListGroup>
      {tracks
       |> Belt_MapInt.toArray
       |> Array.map(((_, t)) => {
            <ListGroup.Item
              key={string_of_int(t.start)}
              action=true
              variant={variant(t)}
              onClick={_ => dsipatch(AlbumAction(Toggle(Some(t.start))))}>
              {ReasonReact.string(
                 t.title
                 ++ " : "
                 ++ Helper.Time.formatSeconds(t._end - t.start),
               )}
            </ListGroup.Item>
          })
       |> React.array}
    </ListGroup>
  );
};
