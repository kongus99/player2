type login = {
  username: string,
  password: string,
};

module Encode = {
  let login = user =>
    Json.Encode.(
      object_([
        ("username", string(user.username)),
        ("password", string(user.password)),
      ])
    );
};

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
let make = (~onLogin: string => unit) => {
  let (user, setUser) = React.useState(() => {username: "", password: ""});
  let (alert, setAlert) = React.useState(() => None);
  let (valid, setValid) =
    React.useState(() => Validation.Validate.calculate(validators, user));
  let statusResolver =
    Fetcher.statusResolver(
      [|(403, "Incorrect login/password.")|],
      x => setAlert(_ => x),
      Fetch.Response.text,
    );

  let handleSubmit = e => {
    e->ReactEvent.Form.preventDefault;
    e->ReactEvent.Form.stopPropagation;
    Fetcher.post(
      "/api/authenticate",
      Encode.login(user),
      statusResolver,
      onLogin,
    );
  };

  let handleChange = (id, update, e) => {
    let value = ReactEvent.Form.target(e)##value;
    setUser(u => {
      let newUser = update(u, value);
      setValid(v => recalculateInput(id, v, newUser));
      newUser;
    });
  };

  Bootstrap.(
    <>
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
          onChange={handleChange(userInput, (u, username) =>
            {...u, username}
          )}
        />
        <Dialog.Control
          control={
            id: passInput,
            _type: "password",
            placeholder: "Password",
            value: user.password,
          }
          validation={Validation.Validate.validate(passInput, valid)}
          onChange={handleChange(passInput, (u, password) =>
            {...u, password}
          )}
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
    </>
  );
};
