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
            <Icon icon="mdi:page-first" />
          </Button>
          <Button
            variant="primary" onClick={_ => dispatch(AlbumAction(Prev))}>
            <Icon icon="mdi:chevron-double-left" />
          </Button>
          <Button
            variant="primary"
            onClick={_ => dispatch(AlbumAction(Toggle(None)))}>
            <Icon icon="mdi:playlist-check" />
          </Button>
          <Button
            variant="primary" onClick={_ => dispatch(AlbumAction(Next))}>
            <Icon icon="mdi:chevron-double-right" />
          </Button>
          <Button
            variant="primary" onClick={_ => dispatch(AlbumAction(Last))}>
            <Icon icon="mdi:page-last" />
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
  let dispatch = Wrapper.useDispatch();
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
              onClick={_ => dispatch(AlbumAction(Toggle(Some(t.start))))}>
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
