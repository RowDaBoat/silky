import std/[tables]

when defined(silkyTesting):
  import silky/[semantic, atlas, widgets, textinput, textboxes, testing]
  export semantic, atlas, widgets, tables, textinput, textboxes, testing
else:
  import opengl, windy
  import silky/[drawing, atlas, widgets, textinput, textboxes]
  export opengl, windy, drawing, atlas, widgets, tables, textinput, textboxes
