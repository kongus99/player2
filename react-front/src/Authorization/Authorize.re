open User;

module Authorize = {
  [@react.component]
  let make = (~onLogin: string => unit) => {
    let (modalVisible, setModalVisible) = React.useState(() => false);
    let (state, setState) = React.useState(() => Login);

    Bootstrap.(
      <>
        <Button onClick={() => {setModalVisible(_ => true)}}>
          {React.string("Login")}
        </Button>
        <Modal
          size="lg"
          show=modalVisible
          onHide={() => setModalVisible(_ => false)}>
          <Modal.Header>
            <ButtonGroup toggle=true>
              <ToggleButton
                _type="radio"
                checked={state == Login}
                variant="primary"
                onChange={_ => setState(_ => Login)}>
                {React.string("Log in")}
              </ToggleButton>
              <ToggleButton
                _type="radio"
                checked={state == Create}
                variant="primary"
                onChange={_ => setState(_ => Create)}>
                {React.string("Create")}
              </ToggleButton>
            </ButtonGroup>
          </Modal.Header>
          <Modal.Body>
            {switch (state) {
             | Login => <Login onLogin />
             | Create => <Create onCreate={_ => setState(_ => Login)} />
             }}
          </Modal.Body>
        </Modal>
      </>
    );
  };
};

[@react.component]
let make = () => {
  let (user, setUser) = React.useState(() => Unauthorized);

  let fetchUser = _ =>
    Fetcher.get(
      "/api/user",
      Belt_MapInt.fromArray([|
        (
          403,
          _ => {
            setUser(_ => Unauthorized);
            Js.Promise.reject(Not_found);
          },
        ),
        (200, Fetch.Response.json),
      |]),
      json => setUser(_ => Authorized(json |> Decode.authorized)),
      ~onError=_ => (),
    );

  React.useEffect0(() => {
    fetchUser();
    None;
  });

  switch (user) {
  | Authorized(_) => <Logout onLogout=fetchUser />
  | Unauthorized => <Authorize onLogin=fetchUser />
  };
};