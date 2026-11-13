// One tab with a shell on every home machine (mod.open:machines, ctrl-k \):
//   desktop | t1g
//   --------+-----
//   mbp16   | t14s
// Each pane runs machine-shell, which is a local shell on its own machine and
// SSH elsewhere, so this works from any of them. Opens as an invisible popup,
// acts, and closes, like split-left.

import { View, div } from "gpui-kit";
import { run, props, closeOverlay } from "herdr";

const shell = (host) => ["machine-shell", host];

export default class Machines extends View {
  init(_props, cx) {
    run("tab.new", { name: "machines", argv: shell("desktop") });
    run("pane.split", { direction: "right", argv: shell("t1g") });
    run("pane.split", { direction: "down", argv: shell("t14s") });
    run("pane.go", { direction: "left" });
    run("pane.split", { direction: "down", argv: shell("mbp16") });
    run("pane.go", { direction: "up" });
    cx.spawn(async () => closeOverlay(props()?.overlay));
  }

  render() {
    return div();
  }
}
