// Split the focused pane left (mod.open:split-left). herdr only splits right
// or down, so split right and swap the new pane left. Opens as an invisible
// popup, acts, and closes.

import { View, div } from "gpui-kit";
import { run, props, closeOverlay } from "herdr";

export default class Split extends View {
  init(_props, cx) {
    run("pane.split", { direction: "right" });
    run("pane.swap", { direction: "left" });
    cx.spawn(async () => closeOverlay(props()?.overlay));
  }

  render() {
    return div();
  }
}
