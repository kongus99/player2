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
