type source = {
  [@bs.as "type"]
  type_: string,
  src: string,
};
type youtube = {ytControls: int};

type videoJSOptions = {
  controls: bool,
  width: int,
  height: int,
  techOrder: array(string),
  sources: array(source),
  youtube,
};

type player = {on: (string, unit => unit) => unit};

let playerOptions = src => {
  {
    controls: true,
    width: 480,
    height: 360,
    techOrder: [|"youtube"|],
    sources: [|{type_: "video/youtube", src}|],
    youtube: {
      ytControls: 0,
    },
  };
};

[@bs.val] external document: Js.t({..}) = "document";
[@bs.module "video.js"]
external vids:
  (~_ref: Js.nullable(Dom.element), ~options: videoJSOptions) => Js.t({..}) =
  "default";

[@bs.module] external ytVids: Js.t({..}) = "videojs-youtube/dist/Youtube.js";

Js.log(ytVids);

let getPlayer = () => {
  let playerNode = document##querySelector("#mainPlayer>.video-js");
  if (playerNode != Js.Nullable.null) {
    Some(playerNode##player);
  } else {
    None;
  };
};

let createPlayer = (videoId, setCurrentTime) => {
  Belt_Option.forEach(getPlayer(), p => p##dispose());
  let container = document##getElementById("mainPlayer");
  let playerNode = document##createElement("video");
  playerNode##className #= "video-js vjs-default-skin sticky-top";

  let reference = container##appendChild(playerNode);
  let player =
    vids(
      ~_ref=reference,
      ~options=playerOptions("https://www.youtube.com/watch?v=" ++ videoId),
    );
  let () =
    player##on("timeupdate", () => {setCurrentTime(player##currentTime())});
  ();
};

[@react.component]
let make = (~videoId: string) => {
  let (currentTime, setCurrentTime) = React.useState(() => 0);
  React.useEffect1(
    () => {
      createPlayer(videoId, setCurrentTime);
      Some(() => {Belt_Option.forEach(getPlayer(), p => p##dispose())});
    },
    [|videoId|],
  );

  <div id="mainPlayer">
    <span>
      {React.string(
         "Current Time: "
         ++ {
           string_of_int(currentTime);
         },
       )}
    </span>
  </div>;
};
