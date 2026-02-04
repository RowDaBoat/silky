## Demonstrates subpixel text positioning.
##
## Subpixel rendering allows text to be positioned at fractional pixel offsets.
## This is useful for smooth scrolling, animations, and precise text placement.
## Drag the slider to move the text by 0.1 pixel increments and observe how
## the text rendering changes at different subpixel positions.

import
  std/[strformat],
  opengl, windy, bumpy, vmath, chroma,
  silky

let builder = newAtlasBuilder(1024, 4)
builder.addDir("data/", "data/")
builder.addFont("data/IBMPlexSans-Regular.ttf", "H1", 48.0)
builder.addFont("data/IBMPlexSans-Regular.ttf", "Default", 18.0)
builder.write("dist/atlas.png", "dist/atlas.json")

let window = newWindow(
  "Subpixel Text Example",
  ivec2(800, 400),
  vsync = false
)
makeContextCurrent(window)
loadExtensions()

const
  BackgroundColor = parseHtmlColor("#1a1a2e").rgbx

let sk = newSilky("dist/atlas.png", "dist/atlas.json")

var textOffset = 0.0f

window.onFrame = proc() =
  sk.beginUI(window, window.size)
  sk.clearScreen(BackgroundColor)

  const
    Margin = 30.0f
    SliderWidth = 600.0f

  # Title.
  sk.at = vec2(Margin, Margin)
  text("Subpixel Text Positioning")

  # Explanation.
  sk.at = vec2(Margin, 70)
  text("Drag the slider to move the text by 0.1 pixel increments.")
  sk.at = vec2(Margin, 95)
  text("Notice how subpixel positioning affects text rendering clarity.")

  # Big slider.
  sk.at = vec2(Margin, 140)
  text(&"Offset: {textOffset:>6.1f} px")
  sk.pushLayout(vec2(Margin, 170), vec2(SliderWidth, 32))
  scrubber("offset", textOffset, 0.0, 20.0)
  sk.popLayout()

  # Display current offset rounded to nearest 0.1.
  sk.at = vec2(Margin + SliderWidth + 20, 175)
  let snappedOffset = (textOffset * 10).round / 10
  text(&"Snapped: {snappedOffset:>4.1f}")

  # Text sample with subpixel offset.
  sk.at = vec2(Margin + textOffset, 250)
  text("The quick brown fox jumps over the lazy dog.")

  # Frame time display.
  let ms = sk.avgFrameTime * 1000
  sk.at = vec2(sk.size.x - 200, Margin)
  text(&"frame time: {ms:>7.3f}ms")

  sk.endUi()
  window.swapBuffers()

when defined(emscripten):
  window.run()
else:
  while not window.closeRequested:
    pollEvents()
