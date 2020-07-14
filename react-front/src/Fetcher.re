exception Unknown_Status;

let resolveCall = (call, onStatus, ~onError=Js.log, onSuccess) =>
  Js.Promise.(
    call
    |> then_(response => {
         let status = Fetch.Response.status(response);
         let statusResolver =
           onStatus->Belt_MapInt.getWithDefault(status, _ =>
             Js.Promise.reject(Unknown_Status)
           );
         statusResolver(response);
       })
    |> then_(success => {
         onSuccess(success);
         Js.Promise.resolve();
       })
    |> catch(err => {
         onError(err);
         Js.Promise.resolve();
       })
    |> ignore
  );

let post = (url, content) =>
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(
      ~method_=Post,
      ~body=Fetch.BodyInit.make(Json.stringify(content)),
      ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
      (),
    ),
  )
  ->resolveCall;

let get = (url, params) =>
  Fetch.fetch(
    [
      url,
      params->Belt_List.map(((name, value)) => name ++ "=" ++ value)
      |> String.concat("&"),
    ]
    |> String.concat("?"),
  )
  ->resolveCall;

let delete = (url, id) =>
  Fetch.fetchWithInit(
    url ++ "/" ++ string_of_int(id),
    Fetch.RequestInit.make(
      ~method_=Delete,
      ~body=Fetch.BodyInit.make(""),
      ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
      (),
    ),
  )
  ->resolveCall;

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
