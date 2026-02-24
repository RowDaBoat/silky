## Basic Window UI tests using semantic capture.
## Run with: nim r tests/test.nim (from basicwindow folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

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

proc testInitialState() =
  echo "Testing initial state..."
  resetState()
  window.pumpFrame(sk)

  # Check the window title is present.
  let windowNode = sk.semantic.root.findByName("A SubWindow", "SubWindow")
  assert windowNode != nil, "SubWindow not found"

  # Check Hello world text is present.
  let helloNode = sk.semantic.root.findByText("Hello world!")
  assert helloNode != nil, "Hello world text not found"

  # Check Close Me button is present.
  let closeBtn = sk.semantic.root.findByText("Close Me", "Button")
  assert closeBtn != nil, "Close Me button not found"

  # Check radio buttons.
  assert sk.semantic.root.findByText("Avg", "RadioButton") != nil, "Avg radio not found"
  assert sk.semantic.root.findByText("Max", "RadioButton") != nil, "Max radio not found"
  assert sk.semantic.root.findByText("Min", "RadioButton") != nil, "Min radio not found"

  # Check checkbox.
  assert sk.semantic.root.findByText("Cumulative", "CheckBox") != nil, "Cumulative checkbox not found"

  echo "  PASS"

proc testCloseButton() =
  echo "Testing close button..."
  resetState()
  window.pumpFrame(sk)
  assert showWindow == true, "showWindow should start true"

  # Click Close Me button.
  window.clickButton(sk, "Close Me")

  # Verify the window is now closed.
  assert showWindow == false, "showWindow should be false after clicking Close Me"

  echo "  PASS"

proc testRadioButtons() =
  echo "Testing radio buttons..."
  resetState()
  window.pumpFrame(sk)
  assert option == 1, "Option should start at 1"

  # Click Max radio button.
  window.clickText(sk, "Max", "RadioButton")
  assert option == 2, "Option should be 2 after clicking Max, got " & $option

  # Click Min radio button.
  window.clickText(sk, "Min", "RadioButton")
  assert option == 3, "Option should be 3 after clicking Min, got " & $option

  # Click back to Avg.
  window.clickText(sk, "Avg", "RadioButton")
  assert option == 1, "Option should be 1 after clicking Avg, got " & $option

  echo "  PASS"

proc testCheckBox() =
  echo "Testing checkbox..."
  resetState()
  window.pumpFrame(sk)
  assert cumulative == false, "Cumulative should start false"

  # Click Cumulative checkbox.
  window.clickText(sk, "Cumulative", "CheckBox")
  assert cumulative == true, "Cumulative should be true after click"

  # Click again to uncheck.
  window.clickText(sk, "Cumulative", "CheckBox")
  assert cumulative == false, "Cumulative should be false after second click"

  echo "  PASS"

proc testDropDownsExist() =
  echo "Testing dropdowns exist..."
  resetState()
  window.pumpFrame(sk)

  # Check dropdown for element shows Fire initially.
  let elementDropdown = sk.semantic.root.findByText("Fire", "DropDown")
  assert elementDropdown != nil, "Element dropdown with 'Fire' not found"

  # Check dropdown for power shows Medium initially.
  let powerDropdown = sk.semantic.root.findByText("Medium", "DropDown")
  assert powerDropdown != nil, "Power dropdown with 'Medium' not found"

  echo "  PASS"

proc testProgressBarExists() =
  echo "Testing progress bar exists..."
  resetState()
  window.pumpFrame(sk)

  # Find Progress Bar label.
  let progressLabel = sk.semantic.root.findByText("Progress Bar:")
  assert progressLabel != nil, "Progress Bar label not found"

  echo "  PASS"

proc testScrubberExists() =
  echo "Testing scrubber exists..."
  resetState()
  window.pumpFrame(sk)

  # Find the scrubber label text.
  let scrubberLabel = sk.semantic.root.findByText("How much: 30.00")
  assert scrubberLabel != nil, "Scrubber label not found"

  echo "  PASS"

proc testIconsAndGroupLayout() =
  echo "Testing icons and group layout..."
  resetState()
  window.pumpFrame(sk)

  # Check for Heart text next to icon.
  let heartText = sk.semantic.root.findByText("Heart")
  assert heartText != nil, "Heart text not found"

  # Check for Cloud text next to icon.
  let cloudText = sk.semantic.root.findByText("Cloud")
  assert cloudText != nil, "Cloud text not found"

  echo "  PASS"

when isMainModule:
  echo "=== Basic Window UI Tests ==="
  echo ""
  testInitialState()
  testCloseButton()
  testRadioButtons()
  testCheckBox()
  testDropDownsExist()
  testProgressBarExists()
  testScrubberExists()
  testIconsAndGroupLayout()
  echo ""
  echo "=== All tests passed! ==="
