open Store.AlbumStore;
let toString = ({tracks}) => {
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
let make = (~album: album) => {
  let (title, setTitle) = React.useState(() => None);

  Bootstrap.(
    <ListGroup>
      {album.tracks
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
