let urlPrefix = "https://www.youtube.com/watch?v=";

type video = {
  id: option(int),
  title: string,
  videoId: string,
};

module Decode = {
  let video = json =>
    Json.Decode.{
      id: json |> field("id", optional(int)),
      title: json |> field("title", string),
      videoId: json |> field("videoId", string),
    };
};

module Encode = {
  let video = video =>
    Json.Encode.(
      object_([
        ("title", string(video.title)),
        ("videoId", string(video.videoId)),
      ])
    );
  let album = tracks =>
    Json.Encode.(object_([("tracksString", string(tracks))]));
};

[@react.component]
let make = (~initial: video) => {
  let (alert, setAlert) = React.useState(() => None);
  let (video, setVideo) =
    React.useState(() =>
      {id: initial.id, title: initial.title, videoId: initial.videoId}
    );
  let (album, setAlbum) = React.useState(() => "");
  let fetchAlbum = id =>
    Album.fetch(
      id,
      album =>
        setAlbum(_ => Belt_Option.mapWithDefault(album, "", Album.toString)),
      Js.log,
    );
  React.useEffect0(() => {
    video.id->Belt_Option.forEach(fetchAlbum);
    None;
  });

  let statusResolver = msg =>
    Fetcher.statusResolver(
      [|(400, msg)|],
      x => setAlert(_ => x),
      Fetch.Response.text,
    );

  let handleSubmit = e => {
    e->ReactEvent.Form.preventDefault;
    e->ReactEvent.Form.stopPropagation;
    switch (video.id) {
    | None =>
      Fetcher.post(
        "/api/video",
        Encode.video(video),
        statusResolver("Could not save video."),
        idString => {
          let id = int_of_string(idString);
          setVideo(v => {...v, id: Some(id)});
          fetchAlbum(id);
        },
      )
    | Some(id) =>
      Fetcher.post(
        "/api/video/" ++ string_of_int(id) ++ "/album",
        Encode.album(album),
        statusResolver("Could not save album for this video."),
        _ =>
        fetchAlbum(id)
      )
    };
  };

  Bootstrap.(
    <>
      <Dialog.Alert alert dismissAlert={() => setAlert(_ => None)} />
      <Form onSubmit=handleSubmit>
        <Form.Group controlId="titleInput">
          <Form.Label> {React.string("Title")} </Form.Label>
          <Form.Control
            _type="text"
            value={video.title}
            isValid=true
            disabled=true
          />
        </Form.Group>
        <Form.Group controlId="urlInput">
          <Form.Label> {React.string("Url")} </Form.Label>
          <Form.Control
            _type="url"
            value={urlPrefix ++ video.videoId}
            isValid=true
            disabled=true
          />
        </Form.Group>
        {switch (video.id) {
         | Some(_) =>
           <Form.Group controlId="albumInput">
             <Form.Label> {React.string("Album")} </Form.Label>
             <Form.Control
               _as="textarea"
               value=album
               onChange={e => {
                 let value = ReactEvent.Form.target(e)##value;
                 setAlbum(_ => value);
               }}
               isValid=true
               rows=15
             />
           </Form.Group>
         | None => <div />
         }}
        <Form.Group>
          <Button variant="primary" _type="submit">
            {switch (video.id) {
             | None => React.string("Save")
             | Some(_) => React.string("Update")
             }}
          </Button>
        </Form.Group>
      </Form>
    </>
  );
};
