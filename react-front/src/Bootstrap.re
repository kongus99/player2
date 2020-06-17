module Button = {
  [@bs.module "react-bootstrap/Button"] [@react.component]
  external make: (~_type: string, ~children: React.element=?) => React.element =
    "default";
};

module ListGroup = {
  [@bs.module "react-bootstrap/ListGroup"] [@react.component]
  external make: (~children: React.element) => React.element = "default";
  module Item = {
    [@bs.module "react-bootstrap/ListGroupItem"] [@react.component]
    external make:
      (
        ~action: bool=?,
        ~active: bool=?,
        ~onClick: ReactEvent.Mouse.t => unit=?,
        ~children: React.element
      ) =>
      React.element =
      "default";
  };
};
