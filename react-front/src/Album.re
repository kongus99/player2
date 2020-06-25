[@bs.val] external fetch: string => Js.Promise.t('a) = "fetch";

type track = {
  title: string,
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
      _end: json |> field("end", optional(int)),
    };
  let album = json =>
    Json.Decode.{tracks: json |> field("tracks", array(track))};
};

[@react.component]
let make = (~id: int) => {
  let (state, setState) = React.useState(() => Loading);
  React.useEffect1(
    () => {
      Js.Promise.(
        fetch("/api/video/" ++ string_of_int(id) ++ "/album")
        |> then_(response => response##json())
        |> then_(jsonResponse => {
             setState(_previousState => {
               let album = jsonResponse |> Json.Decode.optional(Decode.album);
               album
               |> Belt_Option.map(_, a => Loaded(None, a))
               |> Belt_Option.getWithDefault(_, NotFound);
             });
             Js.Promise.resolve();
           })
        |> catch(_err => {
             setState(_previousState => ErrorLoading);
             Js.Promise.resolve();
           })
        |> ignore
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
