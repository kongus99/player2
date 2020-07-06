open User;
[@react.component]
let make = () => {
  let (user, setUser) = React.useState(() => Unauthorized);
  let onAuthorized = u => setUser(_ => Authorized(u));

  React.useEffect0(() => {
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
      json =>
      setUser(_ => Authorized(json |> Decode.authorized))
    );
    None;
  });

  switch (user) {
  | Unauthorized =>
    <Login initial={username: "", password: ""} onAuthorized />
  | Authorizing(unathorized) => <Login initial=unathorized onAuthorized />
  | _ => <Login initial={username: "", password: ""} onAuthorized />
  };
};
