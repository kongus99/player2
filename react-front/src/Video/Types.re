type unpersisted = {
  title: string,
  videoId: string,
};

type persisted = {
  id: int,
  title: string,
  videoId: string,
};

module Decode = {
  let unpersisted = json =>
    Json.Decode.{
      title: json |> field("title", string),
      videoId: json |> field("videoId", string),
    };
  let persisted = json =>
    Json.Decode.{
      id: json |> field("id", int),
      title: json |> field("title", string),
      videoId: json |> field("videoId", string),
    };
};
