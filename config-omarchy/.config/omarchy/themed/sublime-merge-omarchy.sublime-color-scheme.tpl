{
  "name": "Omarchy",
  "globals": {
    "foreground": "{{ foreground }}",
    "background": "{{ background }}",
    "caret": "{{ cursor }}",
    "block_caret": "{{ selection_background }}",
    "selection": "{{ selection_background }}",
    "selection_foreground": "{{ selection_foreground }}",
    "line_highlight": "{{ color0 }}",
    "gutter": "{{ background }}",
    "gutter_foreground": "{{ color8 }}",
    "accent": "{{ accent }}",
    "find_highlight": "{{ color3 }}",
    "find_highlight_foreground": "{{ background }}",
    "misspelling": "{{ color1 }}",
    "diff.inserted": "{{ color2 }}",
    "diff.deleted": "{{ color1 }}",
    "diff.changed": "{{ color3 }}",
    "diff.inserted.char": "{{ color10 }}",
    "diff.deleted.char": "{{ color9 }}",
    "diff.changed.char": "{{ color11 }}",
    "brackets_options": "underline",
    "brackets_foreground": "{{ accent }}",
    "tags_options": "stippled_underline",
    "tags_foreground": "{{ color6 }}"
  },
  "rules": [
    {
      "scope": "comment",
      "foreground": "{{ color8 }}"
    },
    {
      "scope": "string",
      "foreground": "{{ color2 }}"
    },
    {
      "scope": "constant.numeric, constant.language, variable.language",
      "foreground": "{{ color3 }}"
    },
    {
      "scope": "keyword, storage, punctuation.section",
      "foreground": "{{ color5 }}"
    },
    {
      "scope": "entity.name, support.function, variable.function",
      "foreground": "{{ color4 }}"
    },
    {
      "scope": "markup.inserted.diff",
      "foreground": "{{ color2 }}",
      "background": "{{ color0 }}"
    },
    {
      "scope": "markup.deleted.diff",
      "foreground": "{{ color1 }}",
      "background": "{{ color0 }}"
    },
    {
      "scope": "markup.changed.diff",
      "foreground": "{{ color3 }}",
      "background": "{{ color0 }}"
    },
    {
      "scope": "markup.heading.diff",
      "foreground": "{{ color4 }}"
    },
    {
      "scope": "meta.diff.header",
      "foreground": "{{ color6 }}"
    }
  ]
}
