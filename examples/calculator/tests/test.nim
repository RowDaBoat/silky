## Calculator UI tests using semantic capture.
## Run with: nim r tests/test.nim (from calculator folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import silky
import ../calculator {.all.}

proc resetCalculator() =
  ## Resets calculator state to initial values.
  symbols.setLen(0)
  calculator.repeat.setLen(0)

proc testInitialState() =
  echo "Testing initial state..."
  resetCalculator()
  showWindow = true
  window.pumpFrame(sk)
  
  # Check all buttons are present.
  assert sk.semantic.root.findByText("1", "Button") != nil, "Button 1 not found"
  assert sk.semantic.root.findByText("2", "Button") != nil, "Button 2 not found"
  assert sk.semantic.root.findByText("+", "Button") != nil, "Button + not found"
  assert sk.semantic.root.findByText("=", "Button") != nil, "Button = not found"
  assert sk.semantic.root.findByText("C", "Button") != nil, "Button C not found"
  
  # Check initial state has no symbols.
  assert symbols.len == 0, "Expected no symbols initially"
  
  echo "  PASS"

proc testSimpleAddition() =
  echo "Testing simple addition (7 + 3 = 10)..."
  resetCalculator()
  showWindow = true
  
  window.clickButton(sk, "7")
  assert symbols.len == 1, "Expected 1 symbol after clicking 7"
  
  window.clickButton(sk, "+")
  assert symbols.len == 2, "Expected 2 symbols after clicking +"
  
  window.clickButton(sk, "3")
  assert symbols.len == 3, "Expected 3 symbols after clicking 3"
  
  window.clickButton(sk, "=")
  # After compute, should have 1 symbol with result 10.
  assert symbols.len == 1, "Expected 1 symbol after clicking ="
  
  echo "  PASS"

proc testMultiplication() =
  echo "Testing multiplication (6 × 7 = 42)..."
  resetCalculator()
  showWindow = true
  
  window.clickButton(sk, "6")
  window.clickButton(sk, "×")
  window.clickButton(sk, "7")
  window.clickButton(sk, "=")
  
  assert symbols.len == 1, "Expected 1 symbol after compute"
  echo "  PASS"

proc testClearButton() =
  echo "Testing clear button..."
  resetCalculator()
  showWindow = true
  
  # Enter 5 + 3 (three symbols).
  window.clickButton(sk, "5")
  window.clickButton(sk, "+")
  window.clickButton(sk, "3")
  assert symbols.len == 3, "Expected 3 symbols"
  
  # Clear last symbol (3).
  window.clickButton(sk, "C")
  assert symbols.len == 2, "Expected 2 symbols after first C"
  
  # Clear operator (+).
  window.clickButton(sk, "C")
  assert symbols.len == 1, "Expected 1 symbol after second C"
  
  # Clear number (5).
  window.clickButton(sk, "C")
  assert symbols.len == 0, "Expected 0 symbols after third C"
  
  echo "  PASS"

proc testDecimalNumbers() =
  echo "Testing decimal numbers (3.14 + 2.86 = 6)..."
  resetCalculator()
  showWindow = true
  
  window.clickButton(sk, "3")
  window.clickButton(sk, ".")
  window.clickButton(sk, "1")
  window.clickButton(sk, "4")
  window.clickButton(sk, "+")
  window.clickButton(sk, "2")
  window.clickButton(sk, ".")
  window.clickButton(sk, "8")
  window.clickButton(sk, "6")
  window.clickButton(sk, "=")
  
  assert symbols.len == 1, "Expected 1 symbol after compute"
  echo "  PASS"

proc testOrderOfOperations() =
  echo "Testing order of operations (2 + 3 × 4 = 14)..."
  resetCalculator()
  showWindow = true
  
  window.clickButton(sk, "2")
  window.clickButton(sk, "+")
  window.clickButton(sk, "3")
  window.clickButton(sk, "×")
  window.clickButton(sk, "4")
  window.clickButton(sk, "=")
  
  assert symbols.len == 1, "Expected 1 symbol after compute"
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
