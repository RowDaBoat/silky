when not defined(windyDirectX):
  {.error: "Build this example with -d:windyDirectX.".}

import
  vmath, chroma,
  silky

let builder = newAtlasBuilder(256, 4)
builder.write("dist/dx12_smoke.png")

let window = newWindow(
  "Silky DX12 Smoke",
  ivec2(800, 600),
  vsync = false
)
let sk = newSilky(window, "dist/dx12_smoke.png")

window.onFrame = proc() =
  ## Draws a small DX12-backed Silky frame.
  sk.clearScreen(rgbx(24, 28, 38, 255))
  sk.beginUI(window, window.size)

  sk.drawRect(vec2(80, 80), vec2(240, 120), rgbx(70, 140, 220, 255))
  sk.drawRect(vec2(140, 140), vec2(180, 90), rgbx(255, 180, 60, 220))

  sk.endUi()

when isMainModule:
  while not window.closeRequested:
    pollEvents()
