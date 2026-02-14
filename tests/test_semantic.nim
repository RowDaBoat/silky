## Test for semantic capture functionality.
## Compile with: nim r tests/test_semantic.nim

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import std/[strutils]
import bumpy
import silky

proc testUI(sk: Silky, window: Window) =
  sk.beginWidget("SubWindow", name = "TestWindow", rect = rect(10, 10, 300, 200))
  
  sk.beginWidget("Button", text = "Click Me", rect = rect(20, 50, 100, 30))
  sk.setWidgetState(enabled = true, hovered = false, pressed = false)
  sk.endWidget()
  
  sk.beginWidget("Button", text = "Cancel", rect = rect(130, 50, 80, 30))
  sk.setWidgetState(enabled = true, hovered = false, pressed = false)
  sk.endWidget()
  
  sk.beginWidget("CheckBox", text = "Option 1", rect = rect(20, 90, 100, 20))
  sk.setWidgetState(checked = true)
  sk.endWidget()
  
  sk.endWidget()

proc testBasicSnapshot() =
  echo "Testing basic snapshot..."
  var sk = Silky()
  sk.semantic.reset()
  
  var window = newWindow(800, 600)
  testUI(sk, window)
  
  let snapshot = sk.semanticSnapshot()
  echo "Snapshot:\n", snapshot
  
  assert "TestWindow" in snapshot
  assert "Click Me" in snapshot
  assert "Cancel" in snapshot
  assert "Option 1" in snapshot
  assert "checked" in snapshot
  echo "  PASS"

proc testFindByPath() =
  echo "Testing find by path..."
  var sk = Silky()
  sk.semantic.reset()
  
  var window = newWindow(800, 600)
  testUI(sk, window)
  
  let windowNode = sk.semantic.root.findByPath("TestWindow")
  assert windowNode != nil
  assert windowNode.kind == "SubWindow"
  assert windowNode.name == "TestWindow"
  
  let buttonNode = sk.semantic.root.findByPath("TestWindow.0")
  assert buttonNode != nil
  assert buttonNode.kind == "Button"
  assert buttonNode.text == "Click Me"
  echo "  PASS"

proc testFindByText() =
  echo "Testing find by text..."
  var sk = Silky()
  sk.semantic.reset()
  
  var window = newWindow(800, 600)
  testUI(sk, window)
  
  let button = sk.semantic.root.findByText("Cancel")
  assert button != nil
  assert button.kind == "Button"
  
  let checkbox = sk.semantic.root.findByText("Option 1", "CheckBox")
  assert checkbox != nil
  assert checkbox.state.checked == true
  echo "  PASS"

proc testDiffDetection() =
  echo "Testing diff detection..."
  let old = """frame: 1
TestWindow:
  type: SubWindow
  children:
    0:
      type: Button
      text: Click Me
"""
  
  let new = """frame: 2
TestWindow:
  type: SubWindow
  children:
    0:
      type: Button
      text: Click Me!
"""
  
  let d = diff(old, new)
  echo "Diff:\n", d
  assert "Click Me!" in d
  echo "  PASS"

when isMainModule:
  echo "=== Semantic Capture Tests ==="
  echo ""
  testBasicSnapshot()
  testFindByPath()
  testFindByText()
  testDiffDetection()
  echo ""
  echo "=== All tests completed ==="
