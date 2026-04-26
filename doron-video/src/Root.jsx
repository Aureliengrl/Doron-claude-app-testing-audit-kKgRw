import { Composition } from "remotion";
import { DoronVideo } from "./DoronVideo";

export const Root = () => (
  <Composition
    id="DoronVideo"
    component={DoronVideo}
    durationInFrames={1800}
    fps={30}
    width={1080}
    height={1920}
    defaultProps={{}}
  />
);
