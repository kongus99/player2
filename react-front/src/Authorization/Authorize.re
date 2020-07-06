open User;
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
  | Unauthorized =>
    <Login initial={username: "", password: ""} onLogin=fetchUser />
  | Authorized(_) => <Logout onLogout=fetchUser />
  | Creating => <div />
  };
};
