type create = {
  username: string,
  email: string,
  password: string,
  passwordRepeated: string,
};

module Encode = {
  let create: create => Js.Json.t =
    user =>
      Json.Encode.(
        object_([
          ("username", string(user.username)),
          ("email", string(user.email)),
          ("password", string(user.password)),
        ])
      );
};

let usernameInput = "username";
let emailInput = "email";
let passwordInput = "password";
let passwordRepeatedInput = "passwordRepeated";

let validators =
  Validation.(
    init(
      [|
        (
          usernameInput,
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
        (
          emailInput,
          minLength(
            3,
            u => u.email,
            matches(
              "^(([^<>()\\[\\]\\.,;:\\s@\"]+(\\.[^<>()\\[\\]\\.,;:\\s@\"]+)*)|(\".+\"))@(([^<>()[\\]\\.,;:\\s@\"]+\\.)+[^<>()[\\]\\.,;:\\s@\"]{2,})$",
              u => u.email,
              "Incorrect email.",
              valid,
            ),
          ),
        ),
        (
          passwordInput,
          minLength(
            3,
            u => u.password,
            matches(
              "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$",
              u => u.password,
              "Minimum eight characters, at least one uppercase letter, one lowercase letter, one number and one special character.",
              valid,
            ),
          ),
        ),
        (
          passwordRepeatedInput,
          minLength(
            3,
            u => u.passwordRepeated,
            areSame(
              u => u.password,
              u => u.passwordRepeated,
              "Password fields must be the same",
              valid,
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
let make = (~onCreate: string => unit) => {
  let (user, setUser) =
    React.useState(() =>
      {username: "", email: "", password: "", passwordRepeated: ""}
    );
  let (alert, setAlert) = React.useState(() => None);
  let (valid, setValid) =
    React.useState(() => Validation.Validate.calculate(validators, user));

  let statusResolver =
    Fetcher.statusResolver(
      [|(403, "Could not create user.")|],
      x => setAlert(_ => x),
      Fetch.Response.text,
    );

  let handleSubmit = e => {
    e->ReactEvent.Form.preventDefault;
    e->ReactEvent.Form.stopPropagation;
    Fetcher.post("/api/user", Encode.create(user), statusResolver, onCreate);
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
            id: usernameInput,
            _type: "text",
            placeholder: "Username",
            value: user.username,
          }
          validation={Validation.Validate.validate(usernameInput, valid)}
          onChange={handleChange(usernameInput, (u, username) =>
            {...u, username}
          )}
        />
        <Dialog.Control
          control={
            id: emailInput,
            _type: "email",
            placeholder: "Email",
            value: user.email,
          }
          validation={Validation.Validate.validate(emailInput, valid)}
          onChange={handleChange(emailInput, (u, email) => {...u, email})}
        />
        <Dialog.Control
          control={
            id: passwordInput,
            _type: "password",
            placeholder: "Password",
            value: user.password,
          }
          validation={Validation.Validate.validate(passwordInput, valid)}
          onChange={handleChange(passwordInput, (u, password) =>
            {...u, password}
          )}
        />
        <Dialog.Control
          control={
            id: passwordRepeatedInput,
            _type: "password",
            placeholder: "Repeat password",
            value: user.passwordRepeated,
          }
          validation={Validation.Validate.validate(
            passwordRepeatedInput,
            valid,
          )}
          onChange={handleChange(passwordRepeatedInput, (u, passwordRepeated) =>
            {...u, passwordRepeated}
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
