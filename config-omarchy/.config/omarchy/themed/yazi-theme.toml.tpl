[manager]
cwd = { fg = "{{ color6 }}" }

# Hovered
hovered         = { fg = "{{ background }}", bg = "{{ color4 }}" }
preview_hovered = { fg = "{{ background }}", bg = "{{ foreground }}" }

# Find
find_keyword  = { fg = "{{ color3 }}", italic = true }
find_position = { fg = "{{ color5 }}", bg = "reset", italic = true }

# Marker
marker_copied   = { fg = "{{ color2 }}", bg = "{{ color2 }}" }
marker_cut      = { fg = "{{ color1 }}", bg = "{{ color1 }}" }
marker_selected = { fg = "{{ color4 }}", bg = "{{ color4 }}" }

# Tab
tab_active   = { fg = "{{ background }}", bg = "{{ foreground }}" }
tab_inactive = { fg = "{{ foreground }}", bg = "{{ color0 }}" }
tab_width    = 1

# Count
count_copied   = { fg = "{{ background }}", bg = "{{ color2 }}" }
count_cut      = { fg = "{{ background }}", bg = "{{ color1 }}" }
count_selected = { fg = "{{ background }}", bg = "{{ color4 }}" }

# Border
border_symbol = "│"
border_style  = { fg = "{{ color8 }}" }

[status]
separator_open  = ""
separator_close = ""
separator_style = { fg = "{{ color0 }}", bg = "{{ color0 }}" }

# Mode
mode_normal = { fg = "{{ background }}", bg = "{{ color4 }}", bold = true }
mode_select = { fg = "{{ background }}", bg = "{{ color2 }}", bold = true }
mode_unset  = { fg = "{{ background }}", bg = "{{ cursor }}", bold = true }

# Progress
progress_label  = { fg = "#ffffff", bold = true }
progress_normal = { fg = "{{ color4 }}", bg = "{{ color0 }}" }
progress_error  = { fg = "{{ color1 }}", bg = "{{ color0 }}" }

# Permissions
permissions_t = { fg = "{{ color4 }}" }
permissions_r = { fg = "{{ color3 }}" }
permissions_w = { fg = "{{ color1 }}" }
permissions_x = { fg = "{{ color2 }}" }
permissions_s = { fg = "{{ color8 }}" }

[input]
border   = { fg = "{{ color4 }}" }
title    = {}
value    = {}
selected = { reversed = true }

[select]
border   = { fg = "{{ color4 }}" }
active   = { fg = "{{ color5 }}" }
inactive = {}

[tasks]
border  = { fg = "{{ color4 }}" }
title   = {}
hovered = { underline = true }

[which]
mask            = { bg = "{{ color0 }}" }
cand            = { fg = "{{ color6 }}" }
rest            = { fg = "{{ color15 }}" }
desc            = { fg = "{{ color5 }}" }
separator       = "  "
separator_style = { fg = "{{ color8 }}" }

[help]
on      = { fg = "{{ color5 }}" }
exec    = { fg = "{{ color6 }}" }
desc    = { fg = "{{ color15 }}" }
hovered = { bg = "{{ color8 }}", bold = true }
footer  = { fg = "{{ color0 }}", bg = "{{ foreground }}" }

[filetype]

rules = [
	# Media
	{ mime = "image/*", fg = "{{ color6 }}" },
	{ mime = "{audio,video}/*", fg = "{{ color3 }}" },

	# Archives
	{ mime = "application/{,g}zip", fg = "{{ color5 }}" },
	{ mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}", fg = "{{ color5 }}" },

	# Fallback
	{ name = "*", fg = "{{ foreground }}" },
	{ name = "*/", fg = "{{ color4 }}" }
]
