## Calculator UI tests using semantic capture.
## Run with: nim r tests/test.nim (from calculator folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import std/[strutils]
import vmath, bumpy
import silky
import ../calculator {.all.}

# Frame callback for the calculator UI
proc calcFrame(sk: Silky, window: Window) =
  sk.beginUi(window, window.size)
  drawCalculatorFrame(sk, window)
  sk.endUi()

# Helper to get display text from snapshot
proc getDisplayText(h: TestHarness): string =
  let display = h.findByPath("Calculator.Calculator.display")
  if display != nil:
    return display.text
  return ""

# Helper to click a calculator button by label
proc clickCalcButton(h: var TestHarness, label: string) =
  let node = h.findByText(label, "Button")
  if node != nil and node.rect.w > 0:
    let centerX = (node.rect.x + node.rect.w / 2).int
    let centerY = (node.rect.y + node.rect.h / 2).int
    h.window.moveMouse(centerX, centerY)
  
  h.window.pressButton(MouseLeft)
  discard h.pumpFrame(calcFrame, 1)
  h.window.releaseButton(MouseLeft)
  discard h.pumpFrame(calcFrame, 1)  # Click registers, symbols updated
  discard h.pumpFrame(calcFrame, 1)  # UI redraws with new symbols value

proc testInitialState() =
  echo "Testing initial state..."
  resetCalculator()
  showWindow = true
  
  var h = newTestHarness("dist/atlas.png", "dist/atlas.json", 800, 600)
  discard h.pumpFrame(calcFrame, 1)
  
  # Check display shows "0" initially
  let displayText = h.getDisplayText()
  assert displayText == "0", "Expected display '0', got '" & displayText & "'"
  
  # Check all buttons are present
  assert h.findByText("1", "Button") != nil, "Button 1 not found"
  assert h.findByText("2", "Button") != nil, "Button 2 not found"
  assert h.findByText("+", "Button") != nil, "Button + not found"
  assert h.findByText("=", "Button") != nil, "Button = not found"
  
  echo "  PASS"

proc testSimpleAddition() =
  echo "Testing simple addition (7 + 3 = 10)..."
  resetCalculator()
  showWindow = true
  
  var h = newTestHarness("dist/atlas.png", "dist/atlas.json", 800, 600)
  discard h.pumpFrame(calcFrame, 1)
  
  # Click 7
  h.clickCalcButton("7")
  assert h.getDisplayText() == "7", "After clicking 7, expected '7' got '" & h.getDisplayText() & "'"
  
  # Click +
  h.clickCalcButton("+")
  assert h.getDisplayText() == "7+", "After clicking +, expected '7+' got '" & h.getDisplayText() & "'"
  
  # Click 3
  h.clickCalcButton("3")
  assert h.getDisplayText() == "7+3", "After clicking 3, expected '7+3' got '" & h.getDisplayText() & "'"
  
  # Click =
  h.clickCalcButton("=")
  assert h.getDisplayText() == "10", "After clicking =, expected '10' got '" & h.getDisplayText() & "'"
  
  echo "  PASS"

proc testMultiplication() =
  echo "Testing multiplication (6 × 7 = 42)..."
  resetCalculator()
  showWindow = true
  
  var h = newTestHarness("dist/atlas.png", "dist/atlas.json", 800, 600)
  discard h.pumpFrame(calcFrame, 1)
  
  h.clickCalcButton("6")
  h.clickCalcButton("×")
  h.clickCalcButton("7")
  h.clickCalcButton("=")
  
  assert h.getDisplayText() == "42", "Expected '42' got '" & h.getDisplayText() & "'"
  echo "  PASS"

proc testClearButton() =
  echo "Testing clear button..."
  resetCalculator()
  showWindow = true
  
  var h = newTestHarness("dist/atlas.png", "dist/atlas.json", 800, 600)
  discard h.pumpFrame(calcFrame, 1)
  
  # Enter 5 + 3 (three symbols)
  h.clickCalcButton("5")
  h.clickCalcButton("+")
  h.clickCalcButton("3")
  assert h.getDisplayText() == "5+3", "Expected '5+3' got '" & h.getDisplayText() & "'"
  
  # Clear last symbol (3)
  h.clickCalcButton("C")
  assert h.getDisplayText() == "5+", "After C, expected '5+' got '" & h.getDisplayText() & "'"
  
  # Clear operator (+)
  h.clickCalcButton("C")
  assert h.getDisplayText() == "5", "After second C, expected '5' got '" & h.getDisplayText() & "'"
  
  # Clear number (5)
  h.clickCalcButton("C")
  assert h.getDisplayText() == "0", "After third C, expected '0' got '" & h.getDisplayText() & "'"
  
  echo "  PASS"

proc testDecimalNumbers() =
  echo "Testing decimal numbers (3.14 + 2.86 = 6)..."
  resetCalculator()
  showWindow = true
  
  var h = newTestHarness("dist/atlas.png", "dist/atlas.json", 800, 600)
  discard h.pumpFrame(calcFrame, 1)
  
  h.clickCalcButton("3")
  h.clickCalcButton(".")
  h.clickCalcButton("1")
  h.clickCalcButton("4")
  h.clickCalcButton("+")
  h.clickCalcButton("2")
  h.clickCalcButton(".")
  h.clickCalcButton("8")
  h.clickCalcButton("6")
  h.clickCalcButton("=")
  
  assert h.getDisplayText() == "6", "Expected '6' got '" & h.getDisplayText() & "'"
  echo "  PASS"

proc testOrderOfOperations() =
  echo "Testing order of operations (2 + 3 × 4 = 14)..."
  resetCalculator()
  showWindow = true
  
  var h = newTestHarness("dist/atlas.png", "dist/atlas.json", 800, 600)
  discard h.pumpFrame(calcFrame, 1)
  
  h.clickCalcButton("2")
  h.clickCalcButton("+")
  h.clickCalcButton("3")
  h.clickCalcButton("×")
  h.clickCalcButton("4")
  h.clickCalcButton("=")
  
  assert h.getDisplayText() == "14", "Expected '14' got '" & h.getDisplayText() & "'"
  echo "  PASS"

when isMainModule:
  echo "=== Calculator UI Tests ==="
  echo ""
  testInitialState()
  testSimpleAddition()
  testMultiplication()
  testClearButton()
  testDecimalNumbers()
  testOrderOfOperations()
  echo ""
  echo "=== All tests passed! ==="
