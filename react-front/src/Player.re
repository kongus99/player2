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

[@bs.module "video.js"]
external vids:
  (~_ref: Js.nullable(Dom.element), ~options: videoJSOptions) => Js.t({..}) =
  "default";

[@bs.module] external ytVids: Js.t({..}) = "videojs-youtube/dist/Youtube.js";

Js.log(ytVids);

[@react.component]
let make = (~videoId: string) => {
  let videoPlayerRef: ReactDOM.Ref.currentDomRef =
    React.useRef(Js.Nullable.null);
  let (currentTime, setCurrentTime) = React.useState(() => 0);
  React.useEffect0(() => {
    if (videoPlayerRef.current != Js.Nullable.null) {
      let src = "https://www.youtube.com/watch?v=" ++ videoId;
      Js.log(src);
      let player =
        vids(~_ref=videoPlayerRef.current, ~options=playerOptions(src));
      player##on("timeupdate", () => {setCurrentTime(player##currentTime())});
      ();
    };
    None;
  });

  <div>
    <video
      ref={ReactDOMRe.Ref.domRef(videoPlayerRef)}
      className="video-js vjs-default-skin sticky-top"
    />
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
