## Manual test for drawImage with mask support.

import
  windy, vmath, chroma,
  silky

let builder = newAtlasBuilder(1024, 4)
builder.addDir("tests/data/", "tests/data/")
builder.addFont("tests/data/IBMPlexSans-Regular.ttf", "Default", 18.0)
builder.write("tests/dist/atlas.png")

let window = newWindow(
  "Masking Test",
  ivec2(600, 400),
  vsync = false
)
makeContextCurrent(window)
loadExtensions()

let sk = newSilky(window, "tests/dist/atlas.png")

let tintColor = rgbx(255, 80, 80, 255)

window.onFrame = proc() =
  sk.beginUI(window, window.size)
  sk.clearScreen(rgbx(40, 40, 40, 255))

  const
    Left = 20.0f
    LabelX = 70.0f
    Spacing = 50.0f
  var y = 20.0f

  sk.drawImage("heart", vec2(Left, y))
  sk.at = vec2(LabelX, y + 6)
  text("Base image (no mask, no tint)")
  y += Spacing

  sk.drawImage("heart.mask", vec2(Left, y))
  sk.at = vec2(LabelX, y + 6)
  text("Mask image")
  y += Spacing

  sk.drawImage("heart", vec2(Left, y), tintColor, "heart.mask")
  sk.at = vec2(LabelX, y + 6)
  text("Masked + tinted")
  y += Spacing

  sk.drawImage("heart", vec2(Left, y), tintColor)
  sk.at = vec2(LabelX, y + 6)
  text("Tinted without mask")

  sk.endUi()
  window.swapBuffers()

while not window.closeRequested:
  pollEvents()
