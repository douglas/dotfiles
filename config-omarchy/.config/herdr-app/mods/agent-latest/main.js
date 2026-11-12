// Jump to the agent that most needs you (mod.open:agent-latest): one that is
// blocked, then one that finished while you weren't looking, newest first. If
// none does, go to the most recently changed agent. Skips the focused one.

import { View, div } from "gpui-kit";
import { run, agents, props, closeOverlay } from "herdr";

const URGENCY = { blocked: 2, done: 1 };

export default class AgentLatest extends View {
  init(_props, cx) {
    const [best] = agents()
      .filter((a) => !a.focused)
      .sort((a, b) => (URGENCY[b.status] ?? 0) - (URGENCY[a.status] ?? 0) || b.seq - a.seq);
    if (best) run("agent.focus", { terminal: best.address });
    cx.spawn(async () => closeOverlay(props()?.overlay));
  }

  render() {
    return div();
  }
}
