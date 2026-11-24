// One tab with a shell on every home machine (mod.open:machines, ctrl-k \),
// in a 3x2 grid:
//   f22  | f35 | f18
//   -----+-----+----
//   su34 | f15 | av8
// Each pane runs machine-shell, which is a local shell on its own machine and
// SSH elsewhere, so this works from any of them. Opens as an invisible popup,
// acts, and closes, like split-left.
//
// Every split names the pane it splits: focus after a split isn't settled
// right away, so splitting "the focused pane" stacked panes in one column.

import { View, div } from "gpui-kit";
import { run, props, closeOverlay, focused, panes } from "herdr";

// By full path: herdr's terminal server may start without ~/.bin on its PATH.
const shell = (host) => ["sh", "-c", 'exec "$HOME/.bin/machine-shell" "$0"', host];

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
      run("tab.new", { name: "machines", argv: shell("f22") });
      let here = focused();
      for (let i = 0; i < 40 && (!here?.pane || here.tab === before); i++) {
        await cx.sleep(25);
        here = focused();
      }
      const tab = here.tab;
      const f22 = here.pane;
      const seen = new Set([f22]);

      // Top row: f22 | f35 | f18
      run("pane.split", { direction: "right", pane: f22, argv: shell("f35") });
      const f35 = (await waitForPanes(cx, tab, 2)).find((p) => !seen.has(p));
      seen.add(f35);
      run("pane.split", { direction: "right", pane: f35, argv: shell("f18") });
      const f18 = (await waitForPanes(cx, tab, 3)).find((p) => !seen.has(p));
      seen.add(f18);

      // Bottom row: su34 | f15 | av8
      run("pane.split", { direction: "down", pane: f22, argv: shell("su34") });
      await waitForPanes(cx, tab, 4);
      run("pane.split", { direction: "down", pane: f35, argv: shell("f15") });
      await waitForPanes(cx, tab, 5);
      run("pane.split", { direction: "down", pane: f18, argv: shell("av8") });
      await waitForPanes(cx, tab, 6);

      run("pane.focus", { pane: f22 });
      closeOverlay(props()?.overlay);
    });
  }

  render() {
    return div();
  }
}
