type video = {
  id: int,
  title: string,
  videoId: string,
};

module Decode = {
  let video = json =>
    Json.Decode.{
      id: json |> field("id", int),
      title: json |> field("title", string),
      videoId: json |> field("videoId", string),
    };
};

type state =
  | Loading
  | ErrorLoading
  | Loaded(option(int), array(video));

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

let nextVideoId = (Player.{playlist, loop}, id, videos) => {
  let find = cyclic =>
    videos
    ->Belt_Array.getIndexBy(e => e.id == id)
    ->Belt_Option.flatMap(i => {
        let index =
          if (cyclic) {
            (i + 1) mod Belt_Array.length(videos);
          } else {
            i + 1;
          };
        Belt_Array.get(videos, index)->Belt_Option.map(v => v.id);
      });
  playlist ? find(loop) : Some(id);
};

module Player = {
  [@react.component]
  let make = () => {
    let (state, setState) = React.useState(() => Loading);
    let (authorized, setAuthorized) = React.useState(() => false);
    let (playerOptions, setPlayerOptions) =
      React.useState(() => Player.{play: true, playlist: true, loop: false});
    React.useEffect0(() => {
      Fetcher.get(
        "/api/video",
        [],
        Fetcher.statusResolver([||], _ => (), Fetch.Response.json),
        ~onError=_ => setState(_ => ErrorLoading),
        json =>
          setState(_ =>
            Loaded(None, json |> Json.Decode.array(Decode.video))
          ),
      );
      None;
    });

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
                   Loaded(nextVideoId(playerOptions, id, videos), videos)
                 | x => x
                 }
               )
             }
           />
         )
      |> Belt_Option.getWithDefault(_, <div />);

    Bootstrap.(
      <>
        <ButtonGroup>
          <Authorize onAuthorize={v => setAuthorized(_ => v)} />
          {if (authorized) {
             <Video.Add />;
           } else {
             <div />;
           }}
          {switch (state) {
           | Loaded(Some(id), videos) =>
             videos
             ->Belt_Array.getBy(v => v.id == id)
             ->Belt_Option.mapWithDefault(<div />, v =>
                 <Video.Edit id={v.id} title={v.title} videoId={v.videoId} />
               )
           | _ => <div />
           }}
        </ButtonGroup>
        <Card border="dark" className="text-center">
          <Card.Body>
            {switch (state) {
             | Loaded(Some(id), videos) => renderPlayer(id, videos)
             | _ => <div />
             }}
            <ButtonGroup toggle=true>
              <ToggleButton
                _type="checkbox"
                checked={playerOptions.play}
                size="sm"
                onChange={e =>
                  setPlayerOptions(o =>
                    {...o, play: ReactEvent.Form.currentTarget(e)##checked}
                  )
                }>
                {React.string("Autoplay")}
              </ToggleButton>
              <ToggleButton
                _type="checkbox"
                checked={playerOptions.loop}
                size="sm"
                onChange={e =>
                  setPlayerOptions(o =>
                    {...o, loop: ReactEvent.Form.currentTarget(e)##checked}
                  )
                }>
                {React.string("Loop")}
              </ToggleButton>
              <ToggleButton
                _type="checkbox"
                checked={playerOptions.playlist}
                size="sm"
                onChange={e =>
                  setPlayerOptions(o =>
                    {
                      ...o,
                      playlist: ReactEvent.Form.currentTarget(e)##checked,
                    }
                  )
                }>
                {React.string("Playlist")}
              </ToggleButton>
            </ButtonGroup>
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
          </Card.Body>
        </Card>
      </>
    );
  };
};
