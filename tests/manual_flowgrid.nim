## Demonstrates element wrapping and scrolling in a resizable frame.

import
  std/[strformat],
  opengl, windy, bumpy, vmath, chroma,
  silky

let builder = newAtlasBuilder(1024, 4)
builder.addDir("tests/data/", "tests/data/")
builder.addFont("tests/data/IBMPlexSans-Regular.ttf", "H1", 32.0)
builder.addFont("tests/data/IBMPlexSans-Regular.ttf", "Default", 18.0)
builder.write("tests/dist/atlas.png")

let window = newWindow(
  "Flow Grid Example",
  ivec2(900, 600),
  vsync = false
)
makeContextCurrent(window)
loadExtensions()

const
  BackgroundColor = parseHtmlColor("#1a1a2e").rgbx
  NumItems = 50

let sk = newSilky("tests/dist/atlas.png")

# Track which items have been clicked.
var
  clickedItems: array[NumItems, bool]
  frameWidth = 400.0f
  frameHeight = 300.0f

window.onFrame = proc() =
  sk.beginUI(window, window.size)
  sk.clearScreen(BackgroundColor)

  const
    Margin = 20.0f
    SliderLabelWidth = 60.0f
    SliderWidth = 300.0f

  # Title.
  sk.at = vec2(Margin, Margin)
  text("Flow Grid Example - Resize the frame to see elements reflow")

  # Instructions.
  sk.at = vec2(Margin, 50)
  text("Drag the sliders to resize the frame. Elements wrap automatically.")

  # Width slider with fixed width frame.
  sk.at = vec2(Margin, 80)
  text("Width:")
  sk.pushLayout(vec2(Margin + SliderLabelWidth, 80), vec2(SliderWidth, 24))
  scrubber("width", frameWidth, 200.0, 600.0)
  sk.popLayout()

  # Height slider with fixed width frame.
  sk.at = vec2(Margin, 110)
  text("Height:")
  sk.pushLayout(vec2(Margin + SliderLabelWidth, 110), vec2(SliderWidth, 24))
  scrubber("height", frameHeight, 100.0, 500.0)
  sk.popLayout()

  # Scrollable frame with flowing icon buttons.
  let framePos = vec2(Margin, 150)
  let frameSize = vec2(frameWidth, frameHeight)

  frame("flowFrame", framePos, frameSize):
    let
      buttonWidth = 32.0f + sk.padding
      margin = 12.0f
      scrollbarWidth = 16.0f
      startX = sk.at.x

    for i in 0 ..< NumItems:
      # Check if we need to wrap to the next line, accounting for scrollbar.
      if sk.at.x + buttonWidth > sk.pos.x + sk.size.x - margin - scrollbarWidth:
        sk.at.x = startX
        sk.at.y += 32 + margin

      let icon =
        if i mod 2 == 0:
          "heart"
        else:
          "cloud"
      iconButton(icon):
        clickedItems[i] = not clickedItems[i]
        echo "Clicked item ", i

  # Show click status.
  sk.at = vec2(framePos.x + frameWidth + 20, 150)
  text("Click status:")
  sk.at.y += 24
  var clickCount = 0
  for i in 0 ..< NumItems:
    if clickedItems[i]:
      inc clickCount
  text(&"{clickCount} / {NumItems} items clicked")

  # Frame time display.
  let ms = sk.avgFrameTime * 1000
  sk.at = sk.pos + vec2(sk.size.x - 250, 20)
  text(&"frame time: {ms:>7.3f}ms")

  sk.endUi()
  window.swapBuffers()

while not window.closeRequested:
  pollEvents()
