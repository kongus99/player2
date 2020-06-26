module Button = {
  [@bs.module "react-bootstrap/Button"] [@react.component]
  external make:
    (~variant: string=?, ~children: React.element=?) => React.element =
    "default";
};

module ButtonGroup = {
  [@bs.module "react-bootstrap/ButtonGroup"] [@react.component]
  external make:
    (~toggle: bool=?, ~className: string=?, ~children: React.element=?) =>
    React.element =
    "default";
};

module ToggleButton = {
  [@bs.module "react-bootstrap/ToggleButton"] [@react.component]
  external make:
    (
      ~checked: bool=?,
      ~disabled: bool=?,
      ~_type: string=?,
      ~size: string=?,
      ~value: 'a=?,
      ~onChange: ReactEvent.Form.t => unit=?,
      ~children: React.element=?
    ) =>
    React.element =
    "default";
};

module ListGroup = {
  [@bs.module "react-bootstrap/ListGroup"] [@react.component]
  external make: (~children: React.element=?) => React.element = "default";
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
module Accordion = {
  [@bs.module "react-bootstrap/Accordion"] [@react.component]
  external make: (~children: React.element=?) => React.element = "default";
  module Toggle = {
    [@bs.module "react-bootstrap/AccordionToggle"] [@react.component]
    external make:
      (~_as: React.element=?, ~eventKey: string, ~children: React.element=?) =>
      React.element =
      "default";
  };
  module Collapse = {
    [@bs.module "react-bootstrap/AccordionCollapse"] [@react.component]
    external make:
      (~eventKey: string, ~children: React.element=?) => React.element =
      "default";
  };
};

module Card = {
  [@bs.module "react-bootstrap/Card"] [@react.component]
  external make: (~children: React.element=?) => React.element = "default";
  [@bs.module "react-bootstrap/Card"] [@bs.scope "default"]
  external header: React.element = "Header";
  module Body = {
    [@bs.module "react-bootstrap/Card"] [@react.component]
    external make: (~children: React.element=?) => React.element = "default";
  };
};
