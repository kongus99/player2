[@react.component]
let make = (~alert: option(string), ~dismissAlert: unit => unit) => {
  switch (alert) {
  | Some(a) =>
    Bootstrap.(
      <Alert
        variant="danger"
        show={alert != None}
        onClose=dismissAlert
        dismissible=true>
        {React.string(a)}
      </Alert>
    )
  | None => <div />
  };
};
