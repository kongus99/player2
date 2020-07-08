module Alert = {
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
};

module Control = {
  type control = {
    id: string,
    _type: string,
    placeholder: string,
    value: string,
  };
  [@react.component]
  let make =
      (
        ~control: control,
        ~validation: Validation.Validate.fieldResult,
        ~onChange: ReactEvent.Form.t => unit,
      ) => {
    Bootstrap.(
      <Form.Group controlId={control.id}>
        <InputGroup>
          <Form.Control
            _type={control._type}
            placeholder={control.placeholder}
            value={control.value}
            onChange
            isInvalid={validation.invalid}
            isValid={validation.valid}
          />
          <Form.Control.Feedback _type="invalid">
            {ReasonReact.string(validation.text)}
          </Form.Control.Feedback>
        </InputGroup>
      </Form.Group>
    );
  };
};

let statusResolver = (errors, feedbackSetter, resultExtractor) =>
  errors
  ->Belt_Array.map(((code, message)) =>
      (
        code,
        _ => {
          feedbackSetter(Some(message));
          Js.Promise.reject(Not_found);
        },
      )
    )
  ->Belt_Array.concat([|
      (
        200,
        response => {
          feedbackSetter(None);
          resultExtractor(response);
        },
      ),
    |])
  ->Belt_MapInt.fromArray;
