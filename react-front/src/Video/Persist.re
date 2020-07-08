open Types;
let urlPrefix = "https://www.youtube.com/watch?v=";

[@react.component]
let make = (~unpersisted: unpersisted, ~onPersist: string => unit) => {
  let (url, setUrl) = React.useState(() => "");
  let (alert, setAlert) = React.useState(() => None);

  let statusResolver =
    Dialog.statusResolver(
      [|(400, "Could not save video.")|],
      x => setAlert(_ => x),
      Fetch.Response.text,
    );

  let handleSubmit = e => {
    e->ReactEvent.Form.preventDefault;
    e->ReactEvent.Form.stopPropagation;
    Fetcher.post(
      "/api/video/",
      Types.Encode.unpersisted(unpersisted),
      statusResolver,
      onPersist,
    );
  };

  Bootstrap.(
    <>
      <Dialog.Alert alert dismissAlert={() => setAlert(_ => None)} />
      <Form onSubmit=handleSubmit>
        <Form.Group controlId="titleInput">
          <Form.Label> {React.string("Title")} </Form.Label>
          <Form.Control
            _type="text"
            value={unpersisted.title}
            isValid=true
            disabled=true
          />
        </Form.Group>
        <Form.Group controlId="urlInput">
          <Form.Label> {React.string("Url")} </Form.Label>
          <Form.Control
            _type="url"
            value={urlPrefix ++ unpersisted.videoId}
            isValid=true
            disabled=true
          />
        </Form.Group>
        <Form.Group>
          <Button variant="primary" _type="submit">
            {React.string("Save")}
          </Button>
        </Form.Group>
      </Form>
    </>
  );
};
