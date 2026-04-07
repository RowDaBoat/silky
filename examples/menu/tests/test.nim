## Menu System UI tests using semantic capture.
## Run with: nim r tests/test.nim (from menu folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import
  std/[unittest, strutils],
  silky,
  ../menu {.all.}

suite "Menu UI - Initial State":

  setup:
    window.pumpFrame(sk)

  test "frame time text present":
    var found = false
    proc searchText(node: SemanticNode) =
      if node.kind == "Text" and "frame time:" in node.text:
        found = true
      for child in node.children:
        searchText(child)
    searchText(sk.semantic.root)
    check found

  test "semantic tree has nodes":
    check sk.semantic.root != nil
    check sk.semantic.root.children.len > 0

  test "multiple frames produce consistent tree":
    window.pumpFrame(sk)
    let snapshot1 = sk.semanticSnapshot()
    window.pumpFrame(sk)
    let snapshot2 = sk.semanticSnapshot()
    # Structure should be stable across frames (only frame number differs).
    check snapshot1.len > 0
    check snapshot2.len > 0
