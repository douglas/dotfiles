// One tab with a shell on every home machine (mod.open:machines, ctrl-k \),
// in four equal quarters:
//   desktop | t1g
//   --------+-----
//   mbp16   | t14s
// Each pane runs machine-shell, which is a local shell on its own machine and
// SSH elsewhere, so this works from any of them. Opens as an invisible popup,
// acts, and closes, like split-left.
//
// Every split names the pane it splits: focus after a split isn't settled
// right away, so splitting "the focused pane" stacked panes in one column.

import { View, div } from "gpui-kit";
import { run, props, closeOverlay, focused, panes } from "herdr";

const shell = (host) => ["machine-shell", host];

// The panes of a tab, by id.
const tabPanes = (tab) => panes().filter((p) => p.tab === tab).map((p) => p.pane);

// Polls until the tab has `count` panes (each step lands after a frame or two).
async function waitForPanes(cx, tab, count) {
  for (let i = 0; i < 40 && tabPanes(tab).length < count; i++) await cx.sleep(25);
  return tabPanes(tab);
}

export default class Machines extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      const before = focused()?.tab;
      run("tab.new", { name: "machines", argv: shell("desktop") });
      let here = focused();
      for (let i = 0; i < 40 && (!here?.pane || here.tab === before); i++) {
        await cx.sleep(25);
        here = focused();
      }
      const tab = here.tab;
      const desktop = here.pane;

      // Left and right halves, then each half split top and bottom.
      run("pane.split", { direction: "right", pane: desktop, argv: shell("t1g") });
      const t1g = (await waitForPanes(cx, tab, 2)).find((p) => p !== desktop);
      run("pane.split", { direction: "down", pane: desktop, argv: shell("mbp16") });
      await waitForPanes(cx, tab, 3);
      run("pane.split", { direction: "down", pane: t1g, argv: shell("t14s") });
      await waitForPanes(cx, tab, 4);

      run("pane.focus", { pane: desktop });
      closeOverlay(props()?.overlay);
    });
  }

  render() {
    return div();
  }
}
