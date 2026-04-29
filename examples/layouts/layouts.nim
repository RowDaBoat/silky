import
  vmath, chroma,
  silky

let builder = newAtlasBuilder(1024, 4)
builder.addDir("data/", "data/")
builder.addFont("data/IBMPlexSans-Regular.ttf", "H1", 32.0)
builder.addFont("data/IBMPlexSans-Regular.ttf", "Default", 18.0)
builder.write("dist/atlas.png")

let window = newWindow(
  "Layouts",
  ivec2(800, 600),
  vsync = false
)
makeContextCurrent(window)
loadExtensions()

let sk = newSilky(window, "dist/atlas.png")

let overlap* = vec2(15, -35)

var
  showOverlapWindow = true
  behindClicked = false
  inFrontClicked = false

window.onFrame = proc() =
  sk.beginUI(window, window.size)

  # Draw tiled test texture as the background.
  for x in 0 ..< 16:
    for y in 0 ..< 10:
      sk.at = vec2(x.float32 * 256, y.float32 * 256)
      image("testTexture", rgbx(30, 30, 30, 255))

  subWindow("Layouts", showOverlapWindow, vec2(520, 100), vec2(250, 200)):
    text("Two overlapping buttons:")

    var clicked = false

    button("Behind"):
      clicked = true

    behindClicked = clicked
    sk.at = sk.at + overlap

    button("In Front"):
      clicked = true

    inFrontClicked = clicked

  if not showOverlapWindow:
    if window.buttonPressed[MouseLeft]:
      showOverlapWindow = true
    sk.at = vec2(100, 100)
    text("Click anywhere to show the window")

  sk.endUi()
  window.swapBuffers()

while not window.closeRequested:
  pollEvents()
