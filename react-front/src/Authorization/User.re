type login = {
  username: string,
  password: string,
};

type create = {
  name: string,
  email: string,
  pass: string,
  passRepeated: string,
};

type authorized = {
  id: int,
  name: string,
  email: string,
};

type unathorized =
  | Login
  | Create;

type user =
  | Unauthorized
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
  let login: login => Js.Json.t =
    user =>
      Json.Encode.(
        object_([
          ("username", string(user.username)),
          ("password", string(user.password)),
        ])
      );
};
