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
    Bootstrap.(
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
    );
  };
};
