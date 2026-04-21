## Manual test for draw9Patch with adjustable border sliders.

import
  std/[strformat],
  opengl, windy, vmath, chroma,
  silky

let builder = newAtlasBuilder(1024, 4)
builder.addDir("tests/data/", "tests/data/")
builder.addFont("tests/data/IBMPlexSans-Regular.ttf", "H1", 32.0)
builder.addFont("tests/data/IBMPlexSans-Regular.ttf", "Default", 18.0)
builder.write("tests/dist/atlas.png")

let window = newWindow(
  "9-Patch Test",
  ivec2(900, 700),
  vsync = false
)
makeContextCurrent(window)
loadExtensions()

let sk = newSilky(window, "tests/dist/atlas.png")

var
  use4Patch = false
  patchTop = 8.0f
  patchRight = 20.0f
  patchBottom = 16.0f
  patchLeft = 4.0f
  drawWidth = 300.0f
  drawHeight = 200.0f

window.onFrame = proc() =
  sk.beginUI(window, window.size)
  sk.clearScreen(rgbx(40, 40, 40, 255))

  const
    Margin = 20.0f
    LabelWidth = 80.0f
    SliderWidth = 300.0f

  sk.at = vec2(Margin, Margin)
  text("9-Patch Manual Test")

  # Original image for reference, drawn to the right of controls.
  let refX = Margin + LabelWidth + SliderWidth + Margin
  sk.at = vec2(refX, 55)
  text("Original:")
  sk.drawImage("debug.9patch", vec2(refX, 80))

  # Toggle between single-int and independent border modes.
  sk.at = vec2(Margin, 55)
  checkBox("4-patch (independent borders)", use4Patch)

  # Size and patch border sliders.
  var y = 90.0f

  sk.at = vec2(Margin, y)
  text("Width:")
  sk.pushLayout(vec2(Margin + LabelWidth, y), vec2(SliderWidth, 24))
  scrubber("width", drawWidth, 32.0, 600.0, &"{drawWidth:.0f}")
  sk.popLayout()
  y += 35

  sk.at = vec2(Margin, y)
  text("Height:")
  sk.pushLayout(vec2(Margin + LabelWidth, y), vec2(SliderWidth, 24))
  scrubber("height", drawHeight, 32.0, 600.0, &"{drawHeight:.0f}")
  sk.popLayout()
  y += 45

  if use4Patch:
    sk.at = vec2(Margin, y)
    text("Top:")
    sk.pushLayout(vec2(Margin + LabelWidth, y), vec2(SliderWidth, 24))
    scrubber("top", patchTop, 0.0, 32.0, &"{patchTop:.0f}")
    sk.popLayout()
    y += 35

    sk.at = vec2(Margin, y)
    text("Right:")
    sk.pushLayout(vec2(Margin + LabelWidth, y), vec2(SliderWidth, 24))
    scrubber("right", patchRight, 0.0, 32.0, &"{patchRight:.0f}")
    sk.popLayout()
    y += 35

    sk.at = vec2(Margin, y)
    text("Bottom:")
    sk.pushLayout(vec2(Margin + LabelWidth, y), vec2(SliderWidth, 24))
    scrubber("bottom", patchBottom, 0.0, 32.0, &"{patchBottom:.0f}")
    sk.popLayout()
    y += 35

    sk.at = vec2(Margin, y)
    text("Left:")
    sk.pushLayout(vec2(Margin + LabelWidth, y), vec2(SliderWidth, 24))
    scrubber("left", patchLeft, 0.0, 32.0, &"{patchLeft:.0f}")
    sk.popLayout()
    y += 45
  else:
    sk.at = vec2(Margin, y)
    text("Patch:")
    sk.pushLayout(vec2(Margin + LabelWidth, y), vec2(SliderWidth, 24))
    scrubber("patch", patchTop, 0.0, 32.0, &"{patchTop:.0f}")
    sk.popLayout()
    y += 45

  # Draw the 9-patch with current settings.
  let
    drawPos = vec2(Margin, y)
    drawSize = vec2(drawWidth, drawHeight)

  if use4Patch:
    sk.draw9Patch(
      "debug.9patch",
      patchTop.int, patchRight.int, patchBottom.int, patchLeft.int,
      drawPos, drawSize
    )
  else:
    sk.draw9Patch("debug.9patch", patchTop.int, drawPos, drawSize)

  # Frame time display.
  let ms = sk.avgFrameTime * 1000
  sk.at = vec2(sk.pos.x + sk.size.x - 250, 20)
  text(&"frame time: {ms:>7.3f}ms")

  sk.endUi()
  window.swapBuffers()

while not window.closeRequested:
  pollEvents()
