-- Desktop: three fingers open overview, four fingers move workspaces.
hl.config({
  plugin = {
    hyprtasking = {
      gestures = {
        enabled = 1,
        open_fingers = 3,
        move_fingers = 4,
        open_positive = 1,
      },
      grid = { rows = 3, cols = 3 },
    },
  },
})
