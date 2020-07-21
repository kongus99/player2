let toString = (tracks: array(AlbumStore.track)) => {
  let formatTime = t =>
    [t / 3600, t / 60 mod 60, t mod 60]
    |> List.map(t =>
         [t / 10, t mod 10] |> List.map(string_of_int) |> String.concat("")
       )
    |> String.concat(":");
  tracks
  ->Belt_Array.map(t => {formatTime(t.start) ++ " " ++ t.title})
  ->Belt_List.fromArray
  |> String.concat("\n");
};
module Controls = {
  [@react.component]
  let make = () => {
    open Store;
    open AlbumStore;
    let dispatch = Wrapper.useDispatch();

    Bootstrap.(
      <ButtonGroup size="sm" className="btn-block">
        <Button variant="primary" onClick={_ => dispatch(AlbumAction(Prev))}>
          {React.string("<<")}
        </Button>
        <Button variant="primary" onClick={_ => dispatch(AlbumAction(Next))}>
          {React.string(">>")}
        </Button>
      </ButtonGroup>
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
              onClick={_ => dsipatch(AlbumAction(Toggle(t.start)))}>
              {ReasonReact.string(t.title)}
            </ListGroup.Item>
          })
       |> React.array}
    </ListGroup>
  );
};
