## Panels data model tests.
## Run with: nim r tests/test.nim (from panels folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import
  std/unittest,
  ../panels {.all.}

suite "Panels - Initial Layout":

  setup:
    initRootArea()

  test "root area splits into two":
    check rootArea != nil
    check rootArea.areas.len == 2
    check rootArea.layout == Vertical
    check rootArea.split == 0.20'f32

  test "left area has two panels":
    let left = rootArea.areas[0]
    check left.panels.len == 2
    check left.panels[0].name == "Super Panel 1"
    check left.panels[1].name == "Cool Panel 2"

  test "right area splits horizontally":
    let right = rootArea.areas[1]
    check right.areas.len == 2
    check right.layout == Horizontal
    check right.split == 0.5'f32

  test "right sub-areas have three panels each":
    let
      topRight = rootArea.areas[1].areas[0]
      botRight = rootArea.areas[1].areas[1]
    check topRight.panels.len == 3
    check topRight.panels[0].name == "Nice Panel 3"
    check topRight.panels[1].name == "The Other Panel 4"
    check topRight.panels[2].name == "Panel 5"
    check botRight.panels.len == 3
    check botRight.panels[0].name == "World Class Panel 6"
    check botRight.panels[1].name == "FUN Panel 7"
    check botRight.panels[2].name == "Amazing Panel 8"

suite "Panels - Panel Operations":

  setup:
    initRootArea()

  test "add panel increases count":
    let area = rootArea.areas[0]
    let before = area.panels.len
    area.addPanel("Test Panel")
    check area.panels.len == before + 1
    check area.panels[^1].name == "Test Panel"
    check area.panels[^1].parentArea == area

  test "move panel between areas":
    let
      src = rootArea.areas[0]
      dst = rootArea.areas[1].areas[0]
      panel = src.panels[0]
      name = panel.name
      srcBefore = src.panels.len
      dstBefore = dst.panels.len
    dst.movePanel(panel)
    check src.panels.len == srcBefore - 1
    check dst.panels.len == dstBefore + 1
    check dst.panels[^1].name == name
    check panel.parentArea == dst

  test "insert panel at specific index":
    let area = rootArea.areas[1].areas[0]
    let panel = rootArea.areas[0].panels[0]
    area.insertPanel(panel, 1)
    check area.panels[1].name == "Super Panel 1"
    check area.selectedPanelNum == 1

  test "split area creates two sub-areas":
    let area = rootArea.areas[0]
    check area.areas.len == 0
    area.split(Horizontal)
    check area.areas.len == 2
    check area.split == 0.5'f32
    check area.layout == Horizontal

  test "clear removes all panels and sub-areas":
    rootArea.clear()
    check rootArea.panels.len == 0
    check rootArea.areas.len == 0

  test "remove blank areas collapses empty branches":
    let right = rootArea.areas[1]
    # Clear all panels from top-right, making it blank.
    for panel in right.areas[0].panels:
      panel.parentArea = nil
    right.areas[0].panels.setLen(0)
    rootArea.removeBlankAreas()
    # The blank area should be collapsed.
    check right.areas.len == 0
    check right.panels.len == 3
