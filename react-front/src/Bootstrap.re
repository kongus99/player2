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

module Alert = {
  [@bs.module "react-bootstrap/Alert"] [@react.component]
  external make:
    (
      ~closeLabel: string=?,
      ~dismissible: bool=?,
      ~show: bool=?,
      ~variant: string=?,
      ~onClose: unit => unit=?,
      ~children: React.element=?
    ) =>
    React.element =
    "default";
  module Heading = {
    [@bs.module "react-bootstrap/Alert"] [@react.component]
    external make: (~children: React.element=?) => React.element = "default";
  };
};

module Button = {
  [@bs.module "react-bootstrap/Button"] [@react.component]
  external make:
    (
      ~variant: string=?,
      ~onClick: unit => unit=?,
      ~_type: string=?,
      ~children: React.element=?
    ) =>
    React.element =
    "default";
};

module ButtonGroup = {
  [@bs.module "react-bootstrap/ButtonGroup"] [@react.component]
  external make:
    (~toggle: bool=?, ~className: string=?, ~children: React.element=?) =>
    React.element =
    "default";
};

module Card = {
  [@bs.module "react-bootstrap/Card"] [@react.component]
  external make:
    (
      ~bg: string=?,
      ~border: string=?,
      ~className: string=?,
      ~text: string=?,
      ~children: React.element=?
    ) =>
    React.element =
    "default";
  [@bs.module "react-bootstrap/Card"] [@bs.scope "default"]
  external header: React.element = "Header";
  module Body = {
    [@bs.module "react-bootstrap/Card"] [@react.component]
    external make: (~children: React.element=?) => React.element = "default";
  };
};

module Form = {
  [@bs.module "react-bootstrap/Form"] [@react.component]
  external make:
    (
      ~inline: bool=?,
      ~validated: bool=?,
      ~onSubmit: ReactEvent.Form.t => unit=?,
      ~children: React.element=?
    ) =>
    React.element =
    "default";
  module Check = {
    [@bs.module "react-bootstrap/FormCheck"] [@react.component]
    external make:
      (
        ~disabled: bool=?,
        ~feedback: React.element=?,
        ~feedbackTooltip: React.element=?,
        ~id: string=?,
        ~inline: bool=?,
        ~isInvalid: bool=?,
        ~isValid: bool=?,
        ~label: React.element=?,
        ~title: string=?,
        ~_type: string=?,
        ~children: React.element=?
      ) =>
      React.element =
      "default";
  };
  module Group = {
    [@bs.module "react-bootstrap/FormGroup"] [@react.component]
    external make:
      (~controlId: string=?, ~children: React.element=?) => React.element =
      "default";
  };
  module Label = {
    [@bs.module "react-bootstrap/FormLabel"] [@react.component]
    external make:
      (~column: bool=?, ~htmlFor: string=?, ~children: React.element=?) =>
      React.element =
      "default";
  };
  module Control = {
    [@bs.module "react-bootstrap/FormControl"] [@react.component]
    external make:
      (
        ~_as: string=?,
        ~disabled: bool=?,
        ~isInvalid: bool=?,
        ~isValid: bool=?,
        ~id: string=?,
        ~_type: string=?,
        ~placeholder: string=?,
        ~required: bool=?,
        ~rows: int=?,
        ~value: string=?,
        ~onChange: ReactEvent.Form.t => unit=?,
        ~children: React.element=?
      ) =>
      React.element =
      "default";
    module Feedback = {
      [@bs.module "react-bootstrap/Feedback"] [@react.component]
      external make:
        (~tooltip: bool=?, ~_type: string=?, ~children: React.element=?) =>
        React.element =
        "default";
    };
  };
  module Text = {
    [@bs.module "react-bootstrap/FormText"] [@react.component]
    external make:
      (~muted: bool=?, ~className: string=?, ~children: React.element=?) =>
      React.element =
      "default";
  };
};
module InputGroup = {
  [@bs.module "react-bootstrap/InputGroup"] [@react.component]
  external make: (~size: string=?, ~children: React.element=?) => React.element =
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

module Modal = {
  [@bs.module "react-bootstrap/Modal"] [@react.component]
  external make:
    (
      ~show: bool=?,
      ~centered: bool=?,
      ~scrollable: bool=?,
      ~size: string=?,
      ~onHide: unit => unit=?,
      ~children: React.element=?
    ) =>
    React.element =
    "default";
  module Dialog = {
    [@bs.module "react-bootstrap/ModalDialog"] [@react.component]
    external make:
      (
        ~centered: bool=?,
        ~scrollable: bool=?,
        ~size: string=?,
        ~children: React.element=?
      ) =>
      React.element =
      "default";
  };
  module Header = {
    [@bs.module "react-bootstrap/ModalHeader"] [@react.component]
    external make:
      (
        ~closeButton: bool=?,
        ~closeLabel: string=?,
        ~children: React.element=?
      ) =>
      React.element =
      "default";
  };
  module Title = {
    [@bs.module "react-bootstrap/ModalTitle"] [@react.component]
    external make: (~children: React.element=?) => React.element = "default";
  };

  module Body = {
    [@bs.module "react-bootstrap/ModalBody"] [@react.component]
    external make: (~children: React.element=?) => React.element = "default";
  };

  module Footer = {
    [@bs.module "react-bootstrap/ModalFooter"] [@react.component]
    external make: (~children: React.element=?) => React.element = "default";
  };
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
      ~variant: string=?,
      ~onChange: ReactEvent.Form.t => unit=?,
      ~children: React.element=?
    ) =>
    React.element =
    "default";
};
