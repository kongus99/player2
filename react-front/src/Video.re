[@bs.val] external fetch: string => Js.Promise.t('a) = "fetch";

type video = {
  id: int,
  title: string,
  videoId: string,
};

type state =
  | Loading
  | ErrorLoading
  | Loaded(option(int), array(video));

module Decode = {
  let video = json =>
    Json.Decode.{
      id: json |> field("id", int),
      title: json |> field("title", string),
      videoId: json |> field("videoId", string),
    };
};
module VideoList = {
  [@react.component]
  let make =
      (
        ~id: option(int),
        ~videos: array(video),
        ~onClick: (int, ReactEvent.Mouse.t) => unit,
      ) => {
    Bootstrap.(
      <ListGroup>
        {videos
         |> Array.map(v => {
              <ListGroup.Item
                key={string_of_int(v.id)}
                action=true
                active={Some(v.id) == id}
                onClick={onClick(v.id)}>
                {ReasonReact.string(v.title)}
              </ListGroup.Item>
            })
         |> React.array}
      </ListGroup>
    );
  };
};

module Player = {
  [@react.component]
  let make = () => {
    let (state, setState) = React.useState(() => Loading);
    let (playerOptions, setPlayerOptions) =
      React.useState(() => Player.{play: true, playlist: true, loop: false});
    React.useEffect0(() => {
      Js.Promise.(
        fetch("/api/video")
        |> then_(response => response##json())
        |> then_(jsonResponse => {
             setState(_previousState =>
               Loaded(None, jsonResponse |> Json.Decode.array(Decode.video))
             );
             Js.Promise.resolve();
           })
        |> catch(_err => {
             setState(_previousState => ErrorLoading);
             Js.Promise.resolve();
           })
        |> ignore
      );
      None;
    });

    let nextVideoId = (~cyclic=false, id, videos) => {
      Belt_Array.getIndexBy(videos, e => e.id == id)
      |> Belt_Option.flatMap(
           _,
           i => {
             let index =
               if (cyclic) {
                 (i + 1) mod Belt_Array.length(videos);
               } else {
                 i + 1;
               };
             Belt_Array.get(videos, index) |> Belt_Option.map(_, v => v.id);
           },
         );
    };

    let renderPlayer = (id, videos) =>
      Belt.Array.getBy(videos, e => e.id == id)
      |> Belt_Option.map(_, v =>
           <Player
             videoId={v.videoId}
             playerOptions
             onVideoEnd={() =>
               setState(s =>
                 switch (s) {
                 | Loaded(Some(id), videos) =>
                   Loaded(
                     nextVideoId(
                       ~cyclic=playerOptions.playlist && playerOptions.loop,
                       id,
                       videos,
                     ),
                     videos,
                   )
                 | x => x
                 }
               )
             }
           />
         )
      |> Belt_Option.getWithDefault(_, <div />);

    Bootstrap.(
      <div>
        {switch (state) {
         | Loaded(Some(id), videos) => renderPlayer(id, videos)
         | _ => <div />
         }}
        <Accordion>
          <Card>
            <Accordion.Toggle _as=Card.header eventKey="0">
              {React.string("Playlist")}
            </Accordion.Toggle>
            <Accordion.Collapse eventKey="0">
              <Card.Body>
                {switch (state) {
                 | Loading => React.string("Loading")
                 | ErrorLoading => React.string("Error")
                 | Loaded(id, videos) =>
                   <VideoList
                     id
                     videos
                     onClick={(i, _) =>
                       setState(_ => Loaded(Some(i), videos))
                     }
                   />
                 }}
              </Card.Body>
            </Accordion.Collapse>
          </Card>
          {switch (state) {
           | Loaded(Some(id), _) => <Album id />
           | _ => <div />
           }}
        </Accordion>
      </div>
    );
  };
};
