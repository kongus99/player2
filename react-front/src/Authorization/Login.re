type unathorized = {
  username: string,
  password: string,
};

type authorized = {
  id: int,
  name: string,
  email: string,
};

type user =
  | Unauthorized
  | Creating
  | Authorizing(unathorized)
  | Authorized(authorized);

module Decode = {
  let authorized: Js.Json.t => authorized =
    json =>
      Json.Decode.{
        id: json |> field("id", int),
        name: json |> field("username", string),
        email: json |> field("email", string),
      };
};

module Encode = {
  let unathorized: unathorized => Js.Json.t =
    user =>
      Json.Encode.(
        object_([
          ("username", string(user.username)),
          ("password", string(user.password)),
        ])
      );
};

[@react.component]
let make = () => {
  let (user, setUser) = React.useState(() => Unauthorized);
  let (alert, setAlert) = React.useState(() => None);
  let (loginVisible, setLoginVisible) = React.useState(() => false);
  React.useEffect0(() => {
    Js.Promise.(
      Fetch.fetch("/api/user")
      |> then_(response =>
           if (Fetch.Response.status(response) == 403) {
             setAlert(_ => Some("Not authorized"));
             Js.Promise.reject(Not_found);
           } else {
             setAlert(_ => None);
             Fetch.Response.json(response);
           }
         )
      |> then_(json => {
           setUser(_ => Authorized(json |> Decode.authorized));
           Js.Promise.resolve();
         })
      |> catch(err => {
           Js.log(err);
           setUser(_ => Unauthorized);
           Js.Promise.resolve();
         })
      |> ignore
    );
    None;
  });

  module FormControl = {
    type control = {
      _type: string,
      placeholder: string,
      value: string,
    };
    [@react.component]
    let make =
        (
          ~id: string,
          ~control: control,
          ~validation: Validation.Validate.fieldResult,
          ~onChange: ReactEvent.Form.t => unit,
        ) => {
      Bootstrap.(
        <Form.Group controlId=id>
          <InputGroup>
            <Form.Control
              _type={control._type}
              placeholder={control.placeholder}
              value={control.value}
              onChange
              isInvalid={validation.invalid}
              isValid={validation.valid}
            />
            <Form.Control.Feedback _type="invalid">
              {ReasonReact.string(validation.text)}
            </Form.Control.Feedback>
          </InputGroup>
        </Form.Group>
      );
    };
  };

  module Authorization = {
    [@react.component]
    let make = (~username: string, ~onAuthorized: authorized => unit) => {
      let validators =
        Validation.(
          init(
            [|
              (
                "usernameInput",
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
              ("passwordInput", minLength(8, u => u.password, valid)),
            |],
            valid,
          )
        );
      let recalculateInput = name =>
        Validation.Validate.recalculate(name, validators);
      let (user, setUser) = React.useState(() => {username, password: ""});
      let (valid, setValid) =
        React.useState(() => Validation.Validate.calculate(validators, user));
      let handleSubmit = e => {
        e->ReactEvent.Form.preventDefault;
        e->ReactEvent.Form.stopPropagation;
        Js.Promise.(
          Fetch.fetchWithInit(
            "/api/authenticate",
            Fetch.RequestInit.make(
              ~method_=Post,
              ~body=
                Fetch.BodyInit.make(
                  Json.stringify(Encode.unathorized(user)),
                ),
              ~headers=
                Fetch.HeadersInit.make({"Content-Type": "application/json"}),
              (),
            ),
          )
          |> then_(response =>
               if (Fetch.Response.status(response) == 403) {
                 setAlert(_ => Some("Incorrect login/password."));
                 Js.Promise.reject(Not_found);
               } else {
                 setAlert(_ => None);
                 Fetch.Response.json(response);
               }
             )
          |> then_(json => {
               onAuthorized(json |> Decode.authorized);
               Js.Promise.resolve();
             })
          |> catch(err => {
               Js.log(err);
               Js.Promise.resolve();
             })
          |> ignore
        );
      };
      Bootstrap.(
        <Form onSubmit=handleSubmit>
          <FormControl
            id="usernameInput"
            control={
              _type: "text",
              placeholder: "Username",
              value: user.username,
            }
            validation={Validation.Validate.validate("usernameInput", valid)}
            onChange={e => {
              let username = ReactEvent.Form.target(e)##value;
              setUser(u => {
                let newUser = {...u, username};
                setValid(v => recalculateInput("usernameInput", v, newUser));
                newUser;
              });
            }}
          />
          <FormControl
            id="passwordInput"
            control={
              _type: "password",
              placeholder: "Password",
              value: user.password,
            }
            validation={Validation.Validate.validate("passwordInput", valid)}
            onChange={e => {
              let password = ReactEvent.Form.target(e)##value;
              setUser(u => {
                let newUser = {...u, password};
                setValid(v => recalculateInput("passwordInput", v, newUser));
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
      );
    };
  };
  Bootstrap.(
    <>
      <Button
        onClick={() => {
          setUser(u =>
            switch (u) {
            | Unauthorized => Authorizing({username: "", password: ""})
            | Authorizing({username}) =>
              Authorizing({username, password: ""})
            | x => x
            }
          );
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
          <FormAlert alert dismissAlert={() => setAlert(_ => None)} />
          {switch (user) {
           | Unauthorized => <p> {React.string("Unauthorized")} </p>
           | Authorizing(user) =>
             <Authorization
               username={user.username}
               onAuthorized={a => setUser(_ => Authorized(a))}
             />
           | _ => <div />
           }}
        </Modal.Body>
      </Modal>
    </>
  );
};
