## Basic Window UI tests using semantic capture.
## Run with: nim r tests/test.nim (from basicwindow folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import std/[strutils, strformat]
import vmath, bumpy, chroma
import silky
import ../basicwindow {.all.}

# Use basicwindow's own window and sk directly
# Enable semantic capture on the existing silky instance
sk.semantic.enabled = true

# Reset all state to initial values
proc resetState() =
  showWindow = true
  inputText = "Type here!"
  option = 1
  cumulative = false
  element = "Fire"
  power = "Medium"
  progress = 0.0
  howMuch = 30.0

# Run a frame using basicwindow's onFrame
proc pumpFrame() =
  window.resetInputState()
  sk.semantic.reset()
  window.onFrame()

# Helper to click a widget by text and kind
proc clickWidget(text: string, kind: string) =
  let node = sk.semantic.root.findByText(text, kind)
  if node != nil and node.rect.w > 0:
    let centerX = (node.rect.x + node.rect.w / 2).int
    let centerY = (node.rect.y + node.rect.h / 2).int
    window.moveMouse(centerX, centerY)
  
  window.pressButton(MouseLeft)
  pumpFrame()
  window.releaseButton(MouseLeft)
  pumpFrame()
  pumpFrame()

proc clickButton(label: string) =
  clickWidget(label, "Button")

proc clickRadioButton(label: string) =
  clickWidget(label, "RadioButton")

proc clickCheckBox(label: string) =
  clickWidget(label, "CheckBox")

proc testInitialState() =
  echo "Testing initial state..."
  resetState()
  pumpFrame()
  
  # Check the window title is present
  let windowNode = sk.semantic.root.findByText("A SubWindow", "SubWindow")
  assert windowNode != nil, "SubWindow not found"
  
  # Check Hello world text is present
  let helloNode = sk.semantic.root.findByText("Hello world!")
  assert helloNode != nil, "Hello world text not found"
  
  # Check Close Me button is present
  let closeBtn = sk.semantic.root.findByText("Close Me", "Button")
  assert closeBtn != nil, "Close Me button not found"
  
  # Check radio buttons
  assert sk.semantic.root.findByText("Avg", "RadioButton") != nil, "Avg radio not found"
  assert sk.semantic.root.findByText("Max", "RadioButton") != nil, "Max radio not found"
  assert sk.semantic.root.findByText("Min", "RadioButton") != nil, "Min radio not found"
  
  # Check checkbox
  assert sk.semantic.root.findByText("Cumulative", "CheckBox") != nil, "Cumulative checkbox not found"
  
  echo "  PASS"

proc testCloseButton() =
  echo "Testing close button..."
  resetState()
  pumpFrame()
  assert showWindow == true, "showWindow should start true"
  
  # Click Close Me button
  clickButton("Close Me")
  
  # Verify the window is now closed
  assert showWindow == false, "showWindow should be false after clicking Close Me"
  
  echo "  PASS"

proc testRadioButtons() =
  echo "Testing radio buttons..."
  resetState()
  pumpFrame()
  assert option == 1, "Option should start at 1"
  
  # Click Max radio button
  clickRadioButton("Max")
  assert option == 2, "Option should be 2 after clicking Max, got " & $option
  
  # Click Min radio button
  clickRadioButton("Min")
  assert option == 3, "Option should be 3 after clicking Min, got " & $option
  
  # Click back to Avg
  clickRadioButton("Avg")
  assert option == 1, "Option should be 1 after clicking Avg, got " & $option
  
  echo "  PASS"

proc testCheckBox() =
  echo "Testing checkbox..."
  resetState()
  pumpFrame()
  assert cumulative == false, "Cumulative should start false"
  
  # Click Cumulative checkbox
  clickCheckBox("Cumulative")
  assert cumulative == true, "Cumulative should be true after click"
  
  # Click again to uncheck
  clickCheckBox("Cumulative")
  assert cumulative == false, "Cumulative should be false after second click"
  
  echo "  PASS"

proc testDropDownsExist() =
  echo "Testing dropdowns exist..."
  resetState()
  pumpFrame()
  
  # Check dropdown for element (should show "Fire" initially)
  let elementDropdown = sk.semantic.root.findByText("Fire", "DropDown")
  assert elementDropdown != nil, "Element dropdown with 'Fire' not found"
  
  # Check dropdown for power (should show "Medium" initially)
  let powerDropdown = sk.semantic.root.findByText("Medium", "DropDown")
  assert powerDropdown != nil, "Power dropdown with 'Medium' not found"
  
  echo "  PASS"

proc testProgressBarExists() =
  echo "Testing progress bar exists..."
  resetState()
  pumpFrame()
  
  # Find Progress Bar label
  let progressLabel = sk.semantic.root.findByText("Progress Bar:")
  assert progressLabel != nil, "Progress Bar label not found"
  
  echo "  PASS"

proc testScrubberExists() =
  echo "Testing scrubber exists..."
  resetState()
  pumpFrame()
  
  # Find the scrubber label text
  let scrubberLabel = sk.semantic.root.findByText("How much: 30.00")
  assert scrubberLabel != nil, "Scrubber label not found"
  
  echo "  PASS"

proc testIconsAndGroupLayout() =
  echo "Testing icons and group layout..."
  resetState()
  pumpFrame()
  
  # Check for Heart text next to icon
  let heartText = sk.semantic.root.findByText("Heart")
  assert heartText != nil, "Heart text not found"
  
  # Check for Cloud text next to icon
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
