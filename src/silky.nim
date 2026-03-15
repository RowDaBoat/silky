import std/[tables]

when defined(silkyTesting):
  import silky/[semantic, atlas, widgets, textboxes, testing]
  export semantic, atlas, widgets, tables, textboxes, testing
else:
  import windy
  when not defined(useDirectX) and
      not defined(useMetal4):
    import opengl
  import silky/[contexts, atlas, widgets, textboxes]
  when not defined(useDirectX) and
      not defined(useMetal4):
    export opengl
  export windy, contexts, atlas, widgets, tables, textboxes

  when defined(useDirectX) or defined(useMetal4):
    proc loadExtensions*() {.inline.} =
      ## No-op helper for non-OpenGL backends.
      discard
