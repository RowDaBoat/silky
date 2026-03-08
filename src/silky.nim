import std/[tables]

when defined(silkyTesting):
  import silky/[semantic, atlas, widgets, textboxes, testing]
  export semantic, atlas, widgets, tables, textboxes, testing
else:
  import windy
  when not defined(windyDirectX):
    import opengl
  import silky/[drawing, atlas, widgets, textboxes]
  when not defined(windyDirectX):
    export opengl
  export windy, drawing, atlas, widgets, tables, textboxes
