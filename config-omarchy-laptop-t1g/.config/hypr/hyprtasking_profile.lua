-- ThinkPad T1G: four fingers open overview, three fingers move workspaces.
hl.config({
  plugin = {
    hyprtasking = {
      gestures = {
        enabled = 1,
        open_fingers = 4,
        move_fingers = 3,
        open_positive = 1,
      },
      grid = { rows = 3, cols = 3 },
    },
  },
})
