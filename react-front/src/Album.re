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
  let (title, setTitle) = React.useState(() => None);
  let tracks = Wrapper.useSelector(Selector.AlbumStore.tracks);

  Bootstrap.(
    <ListGroup>
      {tracks
       |> Array.map(t => {
            <ListGroup.Item
              key={t.title}
              action=true
              active={Some(t.title) == title}
              onClick={_ => setTitle(_ => Some(t.title))}>
              {ReasonReact.string(t.title)}
            </ListGroup.Item>
          })
       |> React.array}
    </ListGroup>
  );
};
