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

let applyOptions = (options: VideoStore.options, dispatch) => {
  callOnPlayer(p => {
    p##loop(options.loop);
    if (options.play) {
      p##play();
    };
    p##off("ended");
    p##on("ended", _ => dispatch(VideoStore.Config.Next));
  });
};

module Options = {
  [@react.component]
  let make = () => {
    open VideoStore;
    let dispatch = Wrapper.useDispatch();
    let options = Wrapper.useSelector(Config.Selector.options);
    let toggle = (setter, e) => {
      dispatch(Toggle(setter(ReactEvent.Form.currentTarget(e)##checked)));
    };

    Bootstrap.(
      <Card className="text-center">
        <Card.Body>
          <ButtonGroup toggle=true>
            <ToggleButton
              _type="checkbox"
              checked={options.play}
              size="sm"
              onChange={toggle((play, o) => {...o, play})}>
              {React.string("Autoplay")}
            </ToggleButton>
            <ToggleButton
              _type="checkbox"
              checked={options.loop}
              size="sm"
              onChange={toggle((loop, o) => {...o, loop})}>
              {React.string("Loop")}
            </ToggleButton>
            <ToggleButton
              _type="checkbox"
              checked={options.playlist}
              size="sm"
              onChange={toggle((playlist, o) => {...o, playlist})}>
              {React.string("Playlist")}
            </ToggleButton>
          </ButtonGroup>
        </Card.Body>
      </Card>
    );
  };
};

[@react.component]
let make = (~videoId: string) => {
  open VideoStore;
  let (currentTime, setCurrentTime) = React.useState(() => 0);
  let dispatch = VideoStore.Wrapper.useDispatch();
  let options = Wrapper.useSelector(Config.Selector.options);
  React.useEffect1(
    () => {
      createPlayer(videoId, setCurrentTime);
      applyOptions(options, dispatch);
      Some(() => callOnPlayer(p => p##dispose()));
    },
    [|videoId|],
  );

  React.useEffect1(
    () => {
      applyOptions(options, dispatch);
      None;
    },
    [|options|],
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
