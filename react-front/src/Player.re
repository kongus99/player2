type source = {
  [@bs.as "type"]
  type_: string,
  src: string,
};
type youtube = {ytControls: int};

type videoJSOptions = {
  controls: bool,
  techOrder: array(string),
  sources: array(source),
  youtube,
};

type playerOptions = {
  loop: bool,
  play: bool,
  playlist: bool,
};

let initialPlayerOptions = src => {
  {
    controls: true,
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

let callOnPlayer = f => {
  let playerNode = document##querySelector("#mainPlayer>.video-js");
  if (playerNode != Js.Nullable.null) {
    f(playerNode##player);
  };
};

let createPlayer = (videoId, setCurrentTime) => {
  callOnPlayer(p => p##dispose());
  let container = document##getElementById("mainPlayer");
  let playerNode = document##createElement("video");
  playerNode##className
  #= "video-js vjs-default-skin vjs-big-play-centered col vjs-fluid";

  let reference = container##appendChild(playerNode);
  let player =
    vids(
      ~_ref=reference,
      ~options=
        initialPlayerOptions("https://www.youtube.com/watch?v=" ++ videoId),
    );
  let () = player##responsive(true);
  let () =
    player##on("timeupdate", () => {setCurrentTime(player##currentTime())});
  ();
};

let applyOptions = (playerOptions, onVideoEnd) => {
  callOnPlayer(p => {
    p##loop(playerOptions.loop);
    if (playerOptions.play) {
      p##play();
    };
    p##off("ended");
    p##on("ended", _ => onVideoEnd());
  });
};

module Options = {
  [@react.component]
  let make = (~initial: playerOptions, ~onChange: playerOptions => unit) => {
    let (playerOptions, setPlayerOptions) = React.useState(() => initial);
    let toggle = (setter, e) => {
      let checked = ReactEvent.Form.currentTarget(e)##checked;
      setPlayerOptions(o => {
        let options = setter(o, checked);
        onChange(options);
        options;
      });
    };
    Bootstrap.(
      <Card border="dark" className="text-center">
        <Card.Body>
          <ButtonGroup toggle=true>
            <ToggleButton
              _type="checkbox"
              checked={playerOptions.play}
              size="sm"
              onChange={toggle((o, play) => {...o, play})}>
              {React.string("Autoplay")}
            </ToggleButton>
            <ToggleButton
              _type="checkbox"
              checked={playerOptions.loop}
              size="sm"
              onChange={toggle((o, loop) => {...o, loop})}>
              {React.string("Loop")}
            </ToggleButton>
            <ToggleButton
              _type="checkbox"
              checked={playerOptions.playlist}
              size="sm"
              onChange={toggle((o, playlist) => {...o, playlist})}>
              {React.string("Playlist")}
            </ToggleButton>
          </ButtonGroup>
        </Card.Body>
      </Card>
    );
  };
};

[@react.component]
let make = (~videoId: string, ~playerOptions, ~onVideoEnd: unit => unit) => {
  let (currentTime, setCurrentTime) = React.useState(() => 0);
  React.useEffect1(
    () => {
      createPlayer(videoId, setCurrentTime);
      applyOptions(playerOptions, onVideoEnd);
      Some(() => callOnPlayer(p => p##dispose()));
    },
    [|videoId|],
  );

  React.useEffect1(
    () => {
      applyOptions(playerOptions, onVideoEnd);
      None;
    },
    [|playerOptions|],
  );

  <div className="container">
    <span className="row">
      {React.string(
         "Current Time: "
         ++ {
           string_of_int(currentTime);
         },
       )}
    </span>
    <div id="mainPlayer" className="row" />
  </div>;
};
