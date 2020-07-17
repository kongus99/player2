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

[@react.component]
let make = () => {
  open Store;
  open AlbumStore;
  let dsipatch = Wrapper.useDispatch();
  let selected = Wrapper.useSelector(Selector.AlbumStore.selected);
  let tracks = Wrapper.useSelector(Selector.AlbumStore.tracks);

  Bootstrap.(
    <ListGroup>
      {tracks
       |> Belt_MapInt.toArray
       |> Array.map(((_, t)) => {
            <ListGroup.Item
              key={string_of_int(t.start)}
              action=true
              active={Belt_SetInt.has(selected, t.start)}
              onClick={_ => dsipatch(AlbumAction(Toggle(t.start)))}>
              {ReasonReact.string(t.title)}
            </ListGroup.Item>
          })
       |> React.array}
    </ListGroup>
  );
};
