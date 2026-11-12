// Split the focused pane up (mod.open:split-up). herdr only splits right
// or down, so split down and swap the new pane up. Opens as an invisible
// popup, acts, and closes.

import { View, div } from "gpui-kit";
import { run, props, closeOverlay } from "herdr";

export default class Split extends View {
  init(_props, cx) {
    run("pane.split", { direction: "down" });
    run("pane.swap", { direction: "up" });
    cx.spawn(async () => closeOverlay(props()?.overlay));
  }

  render() {
    return div();
  }
}
