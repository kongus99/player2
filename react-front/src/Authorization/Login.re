open User;

let userInput = "usernameInput";
let passInput = "passwordInput";

let validators =
  Validation.(
    init(
      [|
        (
          userInput,
          minLength(
            3,
            u => u.username,
            matches(
              "^[a-zA-Z0-9_-]{3,15}$",
              u => u.username,
              "Lower and upper case letters, numbers, - and _, min 3 and max 15 chars ",
              valid,
            ),
          ),
        ),
        (passInput, minLength(8, u => u.password, valid)),
      |],
      valid,
    )
  );
let recalculateInput = name =>
  Validation.Validate.recalculate(name, validators);

[@react.component]
let make = (~initial: unathorized, ~onAuthorized: authorized => unit) => {
  let (user, setUser) = React.useState(() => initial);
  let (alert, setAlert) = React.useState(() => None);
  let (loginVisible, setLoginVisible) = React.useState(() => false);
  let (valid, setValid) =
    React.useState(() => Validation.Validate.calculate(validators, user));
  let handleSubmit = e => {
    e->ReactEvent.Form.preventDefault;
    e->ReactEvent.Form.stopPropagation;
    Fetcher.post(
      "/api/authenticate",
      Encode.unathorized(user),
      Belt_MapInt.fromArray([|
        (
          403,
          _ => {
            setAlert(_ => Some("Incorrect login/password."));
            Js.Promise.reject(Not_found);
          },
        ),
        (
          200,
          response => {
            setAlert(_ => None);
            Fetch.Response.json(response);
          },
        ),
      |]),
      json =>
      onAuthorized(json |> Decode.authorized)
    );
  };

  Bootstrap.(
    <>
      <Button
        onClick={() => {
          setAlert(_ => None);
          setLoginVisible(_ => true);
        }}>
        {React.string("Login")}
      </Button>
      <Modal
        size="lg" show=loginVisible onHide={() => setLoginVisible(_ => false)}>
        <Modal.Header>
          <InputGroup>
            <Button variant="primary"> {React.string("Log in")} </Button>
            <Button variant="primary"> {React.string("Create")} </Button>
          </InputGroup>
        </Modal.Header>
        <Modal.Body>
          <Dialog.Alert alert dismissAlert={() => setAlert(_ => None)} />
          <Form onSubmit=handleSubmit>
            <Dialog.Control
              control={
                id: userInput,
                _type: "text",
                placeholder: "Username",
                value: user.username,
              }
              validation={Validation.Validate.validate(userInput, valid)}
              onChange={e => {
                let username = ReactEvent.Form.target(e)##value;
                setUser(u => {
                  let newUser = {...u, username};
                  setValid(v => recalculateInput(userInput, v, newUser));
                  newUser;
                });
              }}
            />
            <Dialog.Control
              control={
                id: passInput,
                _type: "password",
                placeholder: "Password",
                value: user.password,
              }
              validation={Validation.Validate.validate(passInput, valid)}
              onChange={e => {
                let password = ReactEvent.Form.target(e)##value;
                setUser(u => {
                  let newUser = {...u, password};
                  setValid(v => recalculateInput(passInput, v, newUser));
                  newUser;
                });
              }}
            />
            <Form.Group>
              {if (Validation.Validate.canSubmit(valid)) {
                 <Button variant="primary" _type="submit">
                   {React.string("Submit")}
                 </Button>;
               } else {
                 <div />;
               }}
            </Form.Group>
          </Form>
        </Modal.Body>
      </Modal>
    </>
  );
};
