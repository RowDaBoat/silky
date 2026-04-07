## Calculator UI tests using semantic capture.
## Run with: nim r tests/test.nim (from calculator folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import std/unittest
import silky
import ../calculator {.all.}

proc resetCalculator() =
  ## Resets calculator state to initial values.
  symbols.setLen(0)
  calculator.repeat.setLen(0)
  showWindow = true

proc getDisplay(): string =
  ## Reads the display text from the UI semantic tree.
  window.pumpFrame(sk)
  let display = sk.semantic.root.findByName("display", "Display")
  if display != nil:
    return display.text
  return "0"

suite "Calculator UI - Initial State":

  setup:
    resetCalculator()
    window.pumpFrame(sk)

  test "all digit buttons present":
    for digit in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
      let btn = sk.semantic.root.findByText(digit, "Button")
      check btn != nil
      check btn.rect.w > 0
      check btn.rect.h > 0

  test "all operator buttons present":
    for op in ["+", "-", "×", "÷", "=", "C", "±", "%", "."]:
      let btn = sk.semantic.root.findByText(op, "Button")
      check btn != nil
      check btn.rect.w > 0

  test "display shows 0 initially":
    let display = sk.semantic.root.findByName("display", "Display")
    check display != nil
    check display.text == "0"
    check display.rect.w > 0
    check display.rect.h > 0

  test "calculator SubWindow present":
    let win = sk.semantic.root.findByName("Calculator", "SubWindow")
    check win != nil
    check win.rect.w > 0
    check win.rect.h > 0

suite "Calculator UI - Basic Arithmetic":

  setup:
    resetCalculator()

  test "simple addition (7 + 3 = 10)":
    window.clickButton(sk, "7")
    check getDisplay() == "7"
    window.clickButton(sk, "+")
    check getDisplay() == "7+"
    window.clickButton(sk, "3")
    check getDisplay() == "7+3"
    window.clickButton(sk, "=")
    check getDisplay() == "10"

  test "multiplication (6 × 7 = 42)":
    window.clickButton(sk, "6")
    window.clickButton(sk, "×")
    window.clickButton(sk, "7")
    check getDisplay() == "6×7"
    window.clickButton(sk, "=")
    check getDisplay() == "42"

  test "division (84 ÷ 2 = 42)":
    window.clickButton(sk, "8")
    window.clickButton(sk, "4")
    window.clickButton(sk, "÷")
    window.clickButton(sk, "2")
    check getDisplay() == "84÷2"
    window.clickButton(sk, "=")
    check getDisplay() == "42"

  test "subtraction (100 - 58 = 42)":
    window.clickButton(sk, "1")
    window.clickButton(sk, "0")
    window.clickButton(sk, "0")
    window.clickButton(sk, "-")
    window.clickButton(sk, "5")
    window.clickButton(sk, "8")
    check getDisplay() == "100-58"
    window.clickButton(sk, "=")
    check getDisplay() == "42"

  test "negative result (5 - 10 = -5)":
    window.clickButton(sk, "5")
    window.clickButton(sk, "-")
    window.clickButton(sk, "1")
    window.clickButton(sk, "0")
    check getDisplay() == "5-10"
    window.clickButton(sk, "=")
    check getDisplay() == "-5"

  test "decimal numbers (3.14 + 2.86 = 6)":
    window.clickButton(sk, "3")
    window.clickButton(sk, ".")
    window.clickButton(sk, "1")
    window.clickButton(sk, "4")
    window.clickButton(sk, "+")
    window.clickButton(sk, "2")
    window.clickButton(sk, ".")
    window.clickButton(sk, "8")
    window.clickButton(sk, "6")
    check getDisplay() == "3.14+2.86"
    window.clickButton(sk, "=")
    check getDisplay() == "6"

suite "Calculator UI - Order of Operations":

  setup:
    resetCalculator()

  test "multiplication before addition (2 + 3 × 4 = 14)":
    window.clickButton(sk, "2")
    window.clickButton(sk, "+")
    window.clickButton(sk, "3")
    window.clickButton(sk, "×")
    window.clickButton(sk, "4")
    check getDisplay() == "2+3×4"
    window.clickButton(sk, "=")
    check getDisplay() == "14"

  test "chained operations (10 + 5 × 2 - 4 = 16)":
    window.clickButton(sk, "1")
    window.clickButton(sk, "0")
    window.clickButton(sk, "+")
    window.clickButton(sk, "5")
    window.clickButton(sk, "×")
    window.clickButton(sk, "2")
    window.clickButton(sk, "-")
    window.clickButton(sk, "4")
    check getDisplay() == "10+5×2-4"
    window.clickButton(sk, "=")
    check getDisplay() == "16"

suite "Calculator UI - Clear Button":

  setup:
    resetCalculator()

  test "clear removes symbols one at a time":
    window.clickButton(sk, "5")
    window.clickButton(sk, "+")
    window.clickButton(sk, "3")
    check getDisplay() == "5+3"

    window.clickButton(sk, "C")
    check getDisplay() == "5+"

    window.clickButton(sk, "C")
    check getDisplay() == "5"

    window.clickButton(sk, "C")
    check getDisplay() == "0"

  test "clear on empty display stays at 0":
    check getDisplay() == "0"
    window.clickButton(sk, "C")
    check getDisplay() == "0"

  test "can enter new expression after clear":
    window.clickButton(sk, "9")
    window.clickButton(sk, "+")
    window.clickButton(sk, "1")
    window.clickButton(sk, "C")
    window.clickButton(sk, "C")
    window.clickButton(sk, "C")
    check getDisplay() == "0"

    window.clickButton(sk, "4")
    window.clickButton(sk, "2")
    check getDisplay() == "42"

suite "Calculator UI - Display State":

  setup:
    resetCalculator()

  test "display node updates text after each button":
    window.clickButton(sk, "1")
    window.pumpFrame(sk)
    let
      d1 = sk.semantic.root.findByName("display", "Display")
    check d1 != nil
    check d1.text == "1"

    window.clickButton(sk, "2")
    window.pumpFrame(sk)
    let d2 = sk.semantic.root.findByName("display", "Display")
    check d2.text == "12"

  test "display resets after equals then new input":
    window.clickButton(sk, "5")
    window.clickButton(sk, "+")
    window.clickButton(sk, "3")
    window.clickButton(sk, "=")
    check getDisplay() == "8"

    window.clickButton(sk, "1")
    check getDisplay() == "81"
