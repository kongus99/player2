[@react.component]
let make = (~onLogout: string => unit) => {
  Bootstrap.(
    <Button
      onClick={_ => {
        Fetcher.post(
          "/api/logout",
          Js.Json.null,
          Belt_MapInt.fromArray([|(200, Fetch.Response.text)|]),
          onLogout,
        )
      }}>
      <Icon icon="mdi:logout" />
    </Button>
  );
};
