exception Unknown_Status;

let post = (url, content, onStatus, ~onError=Js.log, onSuccess) =>
  Js.Promise.(
    Fetch.fetchWithInit(
      url,
      Fetch.RequestInit.make(
        ~method_=Post,
        ~body=Fetch.BodyInit.make(Json.stringify(content)),
        ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
        (),
      ),
    )
    |> then_(response => {
         let status = Fetch.Response.status(response);
         let statusResolver =
           onStatus->Belt_MapInt.getWithDefault(status, _ =>
             Js.Promise.reject(Unknown_Status)
           );
         statusResolver(response);
       })
    |> then_(value => {
         onSuccess(value);
         Js.Promise.resolve();
       })
    |> catch(err => {
         onError(err);
         Js.Promise.resolve();
       })
    |> ignore
  );

let get = (url, params, onStatus, ~onError=Js.log, onSuccess) =>
  Js.Promise.(
    Fetch.fetch(
      [
        url,
        params->Belt_List.map(((name, value)) => name ++ "=" ++ value)
        |> String.concat("&"),
      ]
      |> String.concat("?"),
    )
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
