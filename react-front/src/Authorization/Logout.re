[@react.component]
let make = (~onLogout: string => unit) => {
  Bootstrap.(
    <Button
      onClick={() => {
        Fetcher.post(
          "/api/logout",
          Js.Json.null,
          Belt_MapInt.fromArray([|(200, Fetch.Response.text)|]),
          onLogout,
        )
      }}>
      {React.string("Logout")}
    </Button>
  );
};
