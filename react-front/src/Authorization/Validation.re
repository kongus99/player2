type validation =
  | Indeterminate
  | Valid
  | Invalid(string);

type validator('f) = 'f => validation;

type formValidator('f) = {
  forFields: Belt_MapString.t(validator('f)),
  forSubmit: validator('f),
};

let valid = _ => Valid;

let minLength = (length, extractor, validator, value) =>
  if (String.length(extractor(value)) >= length) {
    validator(value);
  } else {
    Indeterminate;
  };
let matches = (s, extractor, invalid, validator, value) =>
  if (s->Js.Re.fromString->Js.Re.test_(extractor(value))) {
    validator(value);
  } else {
    Invalid(invalid);
  };
let init = (validators, validator) => {
  forFields: Belt_MapString.fromArray(validators),
  forSubmit: validator,
};

module Validate = {
  type result = {
    fieldResults: Belt_MapString.t(validation),
    formResult: validation,
  };

  type fieldResult = {
    valid: bool,
    invalid: bool,
    text: string,
  };

  let calculateSubmit = (forSubmit, fieldResults, form) => {
    let reducer = (acc, value) => {
      switch (acc, value) {
      | (Invalid(_), _) => acc

      | (_, Invalid(_)) => value

      | (_, Indeterminate) => value

      | (_, Valid) => acc
      };
    };
    let formResult =
      switch (
        fieldResults
        ->Belt_MapString.valuesToArray
        ->Belt_Array.reduce(Valid, reducer)
      ) {
      | Valid => forSubmit(form)
      | x => x
      };
    {fieldResults, formResult};
  };

  let calculate = ({forFields, forSubmit}, form) => {
    calculateSubmit(
      forSubmit,
      Belt_MapString.map(forFields, v => v(form)),
      form,
    );
  };

  let recalculate = (name, {forFields, forSubmit}, {fieldResults}, form) => {
    calculateSubmit(
      forSubmit,
      Belt_MapString.update(fieldResults, name, _ => {
        Belt_MapString.get(forFields, name)->Belt_Option.map(f => f(form))
      }),
      form,
    );
  };

  let validate = (name, {fieldResults}) => {
    switch (Belt_MapString.getWithDefault(fieldResults, name, Indeterminate)) {
    | Invalid(s) => {invalid: true, valid: false, text: s}
    | Valid => {invalid: false, valid: true, text: ""}
    | Indeterminate => {invalid: false, valid: false, text: ""}
    };
  };

  let canSubmit = ({formResult}) => {
    switch (formResult) {
    | Valid => true
    | _ => false
    };
  };
};
