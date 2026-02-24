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

proc getDisplay(): string =
  ## Reads the display text from the UI semantic tree.
  window.pumpFrame(sk)
  let display = sk.semantic.root.findByName("display", "Display")
  if display != nil:
    return display.text
  return "0"

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

  # Check initial display shows 0.
  assert getDisplay() == "0", "Expected display to show '0' initially"

  echo "  PASS"

proc testSimpleAddition() =
  echo "Testing simple addition (7 + 3 = 10)..."
  resetCalculator()
  showWindow = true

  window.clickButton(sk, "7")
  assert getDisplay() == "7", "Expected display '7', got '" & getDisplay() & "'"

  window.clickButton(sk, "+")
  assert getDisplay() == "7+", "Expected display '7+', got '" & getDisplay() & "'"

  window.clickButton(sk, "3")
  assert getDisplay() == "7+3", "Expected display '7+3', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "10", "Expected display '10', got '" & getDisplay() & "'"

  echo "  PASS"

proc testMultiplication() =
  echo "Testing multiplication (6 × 7 = 42)..."
  resetCalculator()
  showWindow = true

  window.clickButton(sk, "6")
  window.clickButton(sk, "×")
  window.clickButton(sk, "7")
  assert getDisplay() == "6×7", "Expected display '6×7', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "42", "Expected display '42', got '" & getDisplay() & "'"

  echo "  PASS"

proc testDivision() =
  echo "Testing division (84 ÷ 2 = 42)..."
  resetCalculator()
  showWindow = true

  window.clickButton(sk, "8")
  window.clickButton(sk, "4")
  window.clickButton(sk, "÷")
  window.clickButton(sk, "2")
  assert getDisplay() == "84÷2", "Expected display '84÷2', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "42", "Expected display '42', got '" & getDisplay() & "'"

  echo "  PASS"

proc testSubtraction() =
  echo "Testing subtraction (100 - 58 = 42)..."
  resetCalculator()
  showWindow = true

  window.clickButton(sk, "1")
  window.clickButton(sk, "0")
  window.clickButton(sk, "0")
  window.clickButton(sk, "-")
  window.clickButton(sk, "5")
  window.clickButton(sk, "8")
  assert getDisplay() == "100-58", "Expected display '100-58', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "42", "Expected display '42', got '" & getDisplay() & "'"

  echo "  PASS"

proc testClearButton() =
  echo "Testing clear button..."
  resetCalculator()
  showWindow = true

  # Enter 5 + 3.
  window.clickButton(sk, "5")
  window.clickButton(sk, "+")
  window.clickButton(sk, "3")
  assert getDisplay() == "5+3", "Expected display '5+3', got '" & getDisplay() & "'"

  # Clear last symbol (3).
  window.clickButton(sk, "C")
  assert getDisplay() == "5+", "Expected display '5+' after first C, got '" & getDisplay() & "'"

  # Clear operator (+).
  window.clickButton(sk, "C")
  assert getDisplay() == "5", "Expected display '5' after second C, got '" & getDisplay() & "'"

  # Clear number (5).
  window.clickButton(sk, "C")
  assert getDisplay() == "0", "Expected display '0' after third C, got '" & getDisplay() & "'"

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
  assert getDisplay() == "3.14+2.86", "Expected display '3.14+2.86', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "6", "Expected display '6', got '" & getDisplay() & "'"

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
  assert getDisplay() == "2+3×4", "Expected display '2+3×4', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "14", "Expected display '14', got '" & getDisplay() & "'"

  echo "  PASS"

proc testChainedOperations() =
  echo "Testing chained operations (10 + 5 × 2 - 4 = 16)..."
  resetCalculator()
  showWindow = true

  window.clickButton(sk, "1")
  window.clickButton(sk, "0")
  window.clickButton(sk, "+")
  window.clickButton(sk, "5")
  window.clickButton(sk, "×")
  window.clickButton(sk, "2")
  window.clickButton(sk, "-")
  window.clickButton(sk, "4")
  assert getDisplay() == "10+5×2-4", "Expected display '10+5×2-4', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "16", "Expected display '16', got '" & getDisplay() & "'"

  echo "  PASS"

proc testNegativeResult() =
  echo "Testing negative result (5 - 10 = -5)..."
  resetCalculator()
  showWindow = true

  window.clickButton(sk, "5")
  window.clickButton(sk, "-")
  window.clickButton(sk, "1")
  window.clickButton(sk, "0")
  assert getDisplay() == "5-10", "Expected display '5-10', got '" & getDisplay() & "'"

  window.clickButton(sk, "=")
  assert getDisplay() == "-5", "Expected display '-5', got '" & getDisplay() & "'"

  echo "  PASS"

when isMainModule:
  echo "=== Calculator UI Tests ==="
  echo ""
  testInitialState()
  testSimpleAddition()
  testMultiplication()
  testDivision()
  testSubtraction()
  testClearButton()
  testDecimalNumbers()
  testOrderOfOperations()
  testChainedOperations()
  testNegativeResult()
  echo ""
  echo "=== All tests passed! ==="
