module Modal = {
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

  module Save = {
    let urlPrefix = "https://www.youtube.com/watch?v=";

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
            setAlbum(_ =>
              Belt_Option.mapWithDefault(album, "", Album.toString)
            ),
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
  };

  module Add = {
    type user =
      | Unverified
      | Verified(video);

    module Verify = {
      let urlInput = "urlInput";
      let videoIdRegexp = "v=([^&\\s]+)";
      let validators =
        Validation.(
          init(
            [|
              (
                urlInput,
                minLength(
                  3,
                  x => x,
                  Validation.matches(
                    "[(http(s)?):\\/\\/(www\\.)?a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)",
                    x => x,
                    "Correct url expected.",
                    Validation.matches(
                      videoIdRegexp,
                      x => x,
                      "This url does not contain video id.",
                      Validation.valid,
                    ),
                  ),
                ),
              ),
            |],
            valid,
          )
        );
      let recalculateInput = name =>
        Validation.Validate.recalculate(name, validators);

      [@react.component]
      let make = (~onVerified: video => unit) => {
        let (url, setUrl) = React.useState(() => "");
        let (alert, setAlert) = React.useState(() => None);
        let (valid, setValid) =
          React.useState(() =>
            Validation.Validate.calculate(validators, url)
          );
        let statusResolver =
          Fetcher.statusResolver(
            [|(400, "Could not verify url.")|],
            x => setAlert(_ => x),
            Fetch.Response.json,
          );

        let handleSubmit = e => {
          e->ReactEvent.Form.preventDefault;
          e->ReactEvent.Form.stopPropagation;
          let videoId =
            videoIdRegexp
            ->Js.Re.fromString
            ->Js.Re.exec_(url)
            ->Belt_Option.getExn
            ->Js.Re.captures
            ->Belt_Array.getExn(1)
            ->Js.Nullable.toOption
            ->Belt_Option.getExn;
          Fetcher.get(
            "/api/verify", [("videoId", videoId)], statusResolver, json => {
            onVerified(Decode.video(json))
          });
        };

        let handleChange = (id, update, e) => {
          let value = ReactEvent.Form.target(e)##value;
          setUrl(u => {
            let newUrl = update(u, value);
            setValid(v => recalculateInput(id, v, newUrl));
            newUrl;
          });
        };

        Bootstrap.(
          <>
            <Dialog.Alert alert dismissAlert={() => setAlert(_ => None)} />
            <Form onSubmit=handleSubmit>
              <Dialog.Control
                control={
                  id: urlInput,
                  _type: "url",
                  placeholder: "Video url",
                  value: url,
                }
                validation={Validation.Validate.validate(urlInput, valid)}
                onChange={handleChange(urlInput, (_, newUrl) => newUrl)}
              />
              <Form.Group>
                {if (Validation.Validate.canSubmit(valid)) {
                   <Button variant="primary" _type="submit">
                     {React.string("Verify")}
                   </Button>;
                 } else {
                   <div />;
                 }}
              </Form.Group>
            </Form>
          </>
        );
      };
    };

    [@react.component]
    let make = () => {
      let (modalVisible, setModalVisible) = React.useState(() => false);
      let (state, setState) = React.useState(() => Unverified);

      Bootstrap.(
        <>
          <Button
            onClick={() => {
              setState(_ => Unverified);
              setModalVisible(_ => true);
            }}>
            {React.string("+")}
          </Button>
          <Modal
            size="lg"
            show=modalVisible
            onHide={() => setModalVisible(_ => false)}>
            <Modal.Body>
              {switch (state) {
               | Unverified =>
                 <Verify onVerified={v => setState(_ => Verified(v))} />
               | Verified(video) => <Save initial=video />
               }}
            </Modal.Body>
          </Modal>
        </>
      );
    };
  };

  module Edit = {
    [@react.component]
    let make = (~id: int, ~title: string, ~videoId: string) => {
      let (modalVisible, setModalVisible) = React.useState(() => false);
      Bootstrap.(
        <>
          <Button onClick={() => setModalVisible(_ => true)}>
            {React.string("Edit")}
          </Button>
          <Modal
            size="lg"
            show=modalVisible
            onHide={() => setModalVisible(_ => false)}>
            <Modal.Body>
              <Save initial={id: Some(id), title, videoId} />
            </Modal.Body>
          </Modal>
        </>
      );
    };
  };
};

module List = {
  open VideoStore;
  type state = array(video);

  [@react.component]
  let make = () => {
    let selected = Wrapper.useSelector(Config.Selector.selected);
    let videos = Wrapper.useSelector(Config.Selector.videos);

    let dispatch = Wrapper.useDispatch();
    React.useEffect0(() => {
      Fetcher.get(
        "/api/video",
        [],
        Fetcher.statusResolver([||], _ => (), Fetch.Response.json),
        json =>
        dispatch(Load(json))
      );
      None;
    });

    Bootstrap.(
      <>
        {selected->Belt_Option.mapWithDefault(<div />, v =>
           <Card border="dark" className="text-center">
             <Card.Body> <Player videoId={v.videoId} /> </Card.Body>
           </Card>
         )}
        <Player.Options />
        <Accordion>
          <Card>
            <Accordion.Toggle _as=Card.header eventKey="0">
              {React.string("Playlist")}
            </Accordion.Toggle>
            <Accordion.Collapse eventKey="0">
              <Card.Body>
                <ListGroup>
                  {videos
                   |> Array.map(v => {
                        <ListGroup.Item
                          key={string_of_int(v.id)}
                          action=true
                          active={Belt_Option.mapWithDefault(
                            selected, false, p =>
                            p.id == v.id
                          )}
                          onClick={_ => dispatch(Select(v))}>
                          {ReasonReact.string(v.title)}
                        </ListGroup.Item>
                      })
                   |> React.array}
                </ListGroup>
              </Card.Body>
            </Accordion.Collapse>
          </Card>
          {Belt_Option.mapWithDefault(selected, <div />, v =>
             <Album id={v.id} />
           )}
        </Accordion>
      </>
    );
  };
};
