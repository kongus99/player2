[@bs.val] external fetch: string => Js.Promise.t('a) = "fetch";

type video = {
  id: int,
  title: string,
  videoId: string,
};

type state =
  | Loading
  | ErrorLoading
  | Loaded(int, array(video));

module Decode = {
  let video = json =>
    Json.Decode.{
      id: json |> field("id", int),
      title: json |> field("title", string),
      videoId: json |> field("videoId", string),
    };
};
[@react.component]
let make = () => {
  let (state, setState) = React.useState(() => Loading);
  React.useEffect0(() => {
    Js.Promise.(
      fetch("/api/video")
      |> then_(response => response##json())
      |> then_(jsonResponse => {
           setState(_previousState =>
             Loaded(0, jsonResponse |> Json.Decode.array(Decode.video))
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
    switch (state) {
    | Loading => React.string("Loading")
    | ErrorLoading => React.string("Error")
    | Loaded(index, videoArray) =>
      <ListGroup>
        {videoArray
         |> Array.mapi((i, v) => {
              <ListGroup.Item
                key={string_of_int(v.id)}
                action=true
                active={i == index}
                onClick={_ => setState(_ => Loaded(i, videoArray))}>
                {ReasonReact.string(v.title)}
              </ListGroup.Item>
            })
         |> React.array}
      </ListGroup>
    }
  );
};
