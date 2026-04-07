## Game Player UI tests using semantic capture.
## Run with: nim r tests/test.nim (from gameplayer folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import
  std/[unittest, strutils],
  silky,
  ../gameplayer {.all.}

proc resetState() =
  scrubValue = 0

suite "Game Player UI - Initial State":

  setup:
    resetState()
    window.pumpFrame(sk)

  test "info text present":
    let node = sk.semantic.root.findByText(
      "Step: 1 of 10\nscore: 100\nlevel: 1\nwidth: 100\nheight: 100\nnum agents: 10")
    check node != nil
    check node.kind == "Text"

  test "vibe frame present":
    let node = sk.semantic.root.findByName("vibe-frame", "Frame")
    check node != nil
    check node.rect.w > 0
    check node.rect.h > 0

  test "frame time text present":
    var found = false
    proc searchText(node: SemanticNode) =
      if node.kind == "Text" and "frame time:" in node.text:
        found = true
      for child in node.children:
        searchText(child)
    searchText(sk.semantic.root)
    check found
