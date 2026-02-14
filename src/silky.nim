import std/[tables]

when defined(silkyTesting):
  import silky/[semantic, atlas, widgets, textboxes, testing]
  export semantic, atlas, widgets, tables, textboxes, testing
else:
  import opengl, windy
  import silky/[drawing, atlas, widgets, textboxes]
  export opengl, windy, drawing, atlas, widgets, tables, textboxes
