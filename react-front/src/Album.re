type track = {
  title: string,
  start: int,
  _end: option(int),
};

type album = {tracks: array(track)};

type state =
  | Loading
  | ErrorLoading
  | Loaded(option(string), album)
  | NotFound;

module Decode = {
  let track = json =>
    Json.Decode.{
      title: json |> field("title", string),
      start: json |> field("start", int),
      _end: json |> field("end", optional(int)),
    };
  let album = json =>
    Json.Decode.{tracks: json |> field("tracks", array(track))};
};

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

let fetch = (id, onSuccess, onError) =>
  Fetcher.get(
    "/api/video/" ++ string_of_int(id) ++ "/album",
    [],
    Fetcher.statusResolver([||], _ => (), Fetch.Response.json),
    json => onSuccess(json |> Json.Decode.optional(Decode.album)),
    ~onError,
  );

[@react.component]
let make = (~id: int) => {
  let (state, setState) = React.useState(() => Loading);
  React.useEffect1(
    () => {
      fetch(
        id,
        album =>
          setState(_ => {
            album
            |> Belt_Option.map(_, a => Loaded(None, a))
            |> Belt_Option.getWithDefault(_, NotFound)
          }),
        _ => setState(_ => ErrorLoading),
      );
      None;
    },
    [|id|],
  );

  switch (state) {
  | Loading => React.string("Loading")
  | ErrorLoading => React.string("Error")
  | Loaded(title, album) =>
    Bootstrap.(
      <Card>
        <Accordion.Toggle _as=Card.header eventKey="1">
          {React.string("Tracks")}
        </Accordion.Toggle>
        <Accordion.Collapse eventKey="1">
          <Card.Body>
            <ListGroup>
              {album.tracks
               |> Array.map(t => {
                    <ListGroup.Item
                      key={t.title}
                      action=true
                      active={Some(t.title) == title}
                      onClick={_ =>
                        setState(_ => Loaded(Some(t.title), album))
                      }>
                      {ReasonReact.string(t.title)}
                    </ListGroup.Item>
                  })
               |> React.array}
            </ListGroup>
          </Card.Body>
        </Accordion.Collapse>
      </Card>
    )
  | NotFound => <div />
  };
};
