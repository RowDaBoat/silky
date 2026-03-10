## Demonstrates low-level raw triangle drawing.

import
  std/[strformat],
  windy, bumpy, vmath, chroma,
  silky

when not defined(windyDirectX):
  import opengl

let builder = newAtlasBuilder(1024, 4)
builder.addDir("tests/data/", "tests/data/")
builder.addFont("tests/data/IBMPlexSans-Regular.ttf", "H1", 32.0)
builder.addFont("tests/data/IBMPlexSans-Regular.ttf", "Default", 18.0)
builder.write("tests/dist/atlas.png")

let window = newWindow(
  "Geometry Example",
  ivec2(900, 700),
  vsync = false
)
makeContextCurrent(window)
when not defined(windyDirectX):
  loadExtensions()

const
  BackgroundColor = parseHtmlColor("#1a1a2e").rgbx
  PanelColor = parseHtmlColor("#2a2a3e").rgbx

let sk = newSilky(window, "tests/dist/atlas.png")

window.onFrame = proc() =
  sk.beginUI(window, window.size)
  sk.clearScreen(BackgroundColor)

  const Margin = 24.0f

  sk.at = vec2(Margin, Margin)
  h1text("Manual Geometry")

  sk.at = vec2(Margin, 72)
  text("The triangle below uses raw positions, UVs, and per-vertex colors.")

  let
    panelPos = vec2(120, 160)
    panelSize = vec2(660, 420)
    tri = [
      vec2(450, 200),
      vec2(260, 500),
      vec2(640, 500)
    ]
    uv = [
      vec2(8, 8),
      vec2(8, 8),
      vec2(8, 8)
    ]
    colors = [
      rgbx(255, 90, 90, 255),
      rgbx(90, 255, 160, 255),
      rgbx(90, 140, 255, 255)
    ]

  sk.drawRect(panelPos, panelSize, PanelColor)
  sk.drawTriangle(tri, uv, colors)

  let ms = sk.avgFrameTime * 1000
  sk.at = vec2(sk.size.x - 250, Margin)
  text(&"frame time: {ms:>7.3f}ms")

  sk.endUi()
  window.swapBuffers()

while not window.closeRequested:
  pollEvents()
