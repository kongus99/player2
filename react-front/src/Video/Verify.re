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
let make = (~onVerified: Save.video => unit) => {
  let (url, setUrl) = React.useState(() => "");
  let (alert, setAlert) = React.useState(() => None);
  let (valid, setValid) =
    React.useState(() => Validation.Validate.calculate(validators, url));
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
    Fetcher.get("/api/verify", [("videoId", videoId)], statusResolver, json => {
      onVerified(Save.Decode.video(json))
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
