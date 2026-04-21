import
  vmath, chroma,
  silky

let builder = newAtlasBuilder(1024, 4)
builder.addDir("data/", "data/")
builder.addFont("data/IBMPlexSans-Regular.ttf", "H1", 32.0)
builder.addFont("data/IBMPlexSans-Regular.ttf", "Default", 18.0)
builder.write("dist/atlas.png")

let window = newWindow(
  "Basic Window",
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

  sk.endUi()
  window.swapBuffers()

while not window.closeRequested:
  pollEvents()
