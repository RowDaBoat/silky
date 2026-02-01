import std/[tables]

when defined(silkyTesting):
  import silky/[semantic, atlas, widgets, textinput, testing]
  export semantic, atlas, widgets, tables, textinput, testing
else:
  import silky/[drawing, atlas, widgets, textinput]
  export drawing, atlas, widgets, tables, textinput
