[@bs.module "@iconify/react-with-api"] [@react.component]
external make:
  (
    ~icon: string,
    ~align: string=?,
    ~color: string=?,
    ~flip: string=?,
    ~height: string=?,
    ~rotate: int=?,
    ~width: string=?
  ) =>
  React.element =
  "Icon";

module Inline = {
  [@bs.module "@iconify/react-with-api"] [@react.component]
  external make:
    (
      ~icon: string,
      ~align: string=?,
      ~color: string=?,
      ~flip: string=?,
      ~height: string=?,
      ~rotate: int=?,
      ~width: string=?
    ) =>
    React.element =
    "InlineIcon";
};
