## Basic Window UI tests using semantic capture.
## Run with: nim r tests/test.nim (from basicwindow folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import std/unittest
import silky
import ../basicwindow {.all.}

proc resetState() =
  ## Resets all state to initial values.
  showWindow = true
  basicwindow.inputText = "Type here!"
  option = 1
  cumulative = false
  element = "Fire"
  power = "Medium"
  progress = 0.0
  howMuch = 30.0

suite "Basic Window UI":

  setup:
    resetState()
    window.pumpFrame(sk)

  test "initial state - SubWindow present":
    let windowNode = sk.semantic.root.findByName("A SubWindow", "SubWindow")
    check windowNode != nil

  test "initial state - Hello world text present":
    let helloNode = sk.semantic.root.findByText("Hello world!")
    check helloNode != nil

  test "initial state - Close Me button present":
    let closeBtn = sk.semantic.root.findByText("Close Me", "Button")
    check closeBtn != nil

  test "initial state - radio buttons present":
    check sk.semantic.root.findByText("Avg", "RadioButton") != nil
    check sk.semantic.root.findByText("Max", "RadioButton") != nil
    check sk.semantic.root.findByText("Min", "RadioButton") != nil

  test "initial state - checkbox present":
    check sk.semantic.root.findByText("Cumulative", "CheckBox") != nil

  test "close button closes window":
    check showWindow == true
    window.clickButton(sk, "Close Me")
    check showWindow == false

  test "radio buttons cycle through options":
    check option == 1

    window.clickText(sk, "Max", "RadioButton")
    check option == 2

    window.clickText(sk, "Min", "RadioButton")
    check option == 3

    window.clickText(sk, "Avg", "RadioButton")
    check option == 1

  test "checkbox toggles on and off":
    check cumulative == false

    window.clickText(sk, "Cumulative", "CheckBox")
    check cumulative == true

    window.clickText(sk, "Cumulative", "CheckBox")
    check cumulative == false

  test "dropdowns show initial values":
    let elementDropdown = sk.semantic.root.findByText("Fire", "DropDown")
    check elementDropdown != nil

    let powerDropdown = sk.semantic.root.findByText("Medium", "DropDown")
    check powerDropdown != nil

  test "progress bar label present":
    let progressLabel = sk.semantic.root.findByText("Progress Bar:")
    check progressLabel != nil

  test "scrubber label present":
    let scrubberLabel = sk.semantic.root.findByText("How much: 30.00")
    check scrubberLabel != nil

  test "icons and group layout":
    check sk.semantic.root.findByText("Heart") != nil
    check sk.semantic.root.findByText("Cloud") != nil
