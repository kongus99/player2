open Store;
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

let createPlayer = (videoId, dispatch) => {
  open Store;
  open AlbumStore;
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
    player##on("timeupdate", () =>
      if (player##duration() > 0) {
        let () = player##off("timeupdate");
        dispatch(AlbumAction(Duration(player##duration())));
        player##on("timeupdate", () => {
          dispatch(AlbumAction(UpdateTime(player##currentTime())))
        });
      }
    );
  ();
};

let applyOptions = (options: VideoStore.options, dispatch) => {
  callOnPlayer(p => {
    p##loop(options.loop);
    if (options.play) {
      p##play();
    };
    p##off("ended");
    p##on("ended", _ => dispatch(VideoAction(VideoStore.Next)));
  });
};

module Options = {
  [@react.component]
  let make = () => {
    let dispatch = Wrapper.useDispatch();
    let options = Wrapper.useSelector(Selector.VideoStore.options);
    let toggle = (options, _) => {
      dispatch(VideoAction(VideoStore.Toggle(options)));
    };

    Bootstrap.(
      <ButtonGroup size="sm" className="btn-block" toggle=true>
        <Button
          _type="checkbox"
          active={options.play}
          variant="outline-primary"
          onClick={toggle(o => {...o, play: !o.play})}>
          {React.string("Autoplay")}
        </Button>
        <Button
          _type="checkbox"
          active={options.loop}
          variant="outline-primary"
          onClick={toggle(o => {...o, loop: !o.loop})}>
          {React.string("Loop")}
        </Button>
        <Button
          _type="checkbox"
          active={options.playlist}
          variant="outline-primary"
          onClick={toggle(o => {...o, playlist: !o.playlist})}>
          {React.string("Playlist")}
        </Button>
      </ButtonGroup>
    );
  };
};

[@react.component]
let make = (~videoId: string) => {
  open AlbumStore;
  let dispatch = Wrapper.useDispatch();
  let options = Wrapper.useSelector(Selector.VideoStore.options);
  let playingTrack = Wrapper.useSelector(Selector.AlbumStore.playing);

  React.useEffect1(
    () => {
      createPlayer(videoId, dispatch);
      applyOptions(options, dispatch);
      Some(() => callOnPlayer(p => p##dispose()));
    },
    [|videoId|],
  );

  React.useEffect1(
    () => {
      callOnPlayer(p =>
        switch (playingTrack) {
        | Seeking(t) =>
          let time = p##currentTime(Js.Undefined.empty);
          if (!isPlaying(time, t)) {
            let _ = p##currentTime(Js.Undefined.return(t.start));
            ();
          };
        | _ => ()
        }
      );
      None;
    },
    [|playingTrack|],
  );

  React.useEffect1(
    () => {
      applyOptions(options, dispatch);
      None;
    },
    [|options|],
  );
  Bootstrap.(
    <Card className="text-center">
      <Card.Body>
        <div className="container">
          <div id="mainPlayer" className="row" />
        </div>
      </Card.Body>
    </Card>
  );
};
