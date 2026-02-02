## Test harness for Silky UI testing without a real window or GPU.

import std/unicode
import vmath, bumpy, jsony
import silky/[semantic, atlas]

type
  Button* = enum
    ## Mouse and special button types.
    MouseLeft
    MouseRight
    MouseMiddle
    MouseButton4
    MouseButton5
    DoubleClick
    TripleClick
    QuadrupleClick
    KeyUnknown
    # Keyboard keys for text input.
    KeyBackspace
    KeyDelete
    KeyLeft
    KeyRight
    KeyHome
    KeyEnd
    KeyA
    KeyC
    KeyV
    KeyLeftShift
    KeyRightShift
    KeyLeftControl
    KeyRightControl
    KeyLeftSuper
    KeyRightSuper

export Button, unicode

type
  Window* = ref object
    ## Test window that simulates a windy Window.
    size*: IVec2
    mousePos*: IVec2
    buttonDown*: array[Button, bool]
    buttonPressed*: array[Button, bool]
    buttonReleased*: array[Button, bool]
    scrollDelta*: Vec2
    closeRequested*: bool
    runeInputEnabled*: bool
    onRune*: proc(rune: Rune)
    onFrame*: proc()

  TestHarness* = object
    ## Test harness for running Silky UI tests.
    sk*: Silky
    window*: Window
    lastSnapshot*: string
    frameCount*: int

proc newWindow*(width = 800, height = 600): Window =
  ## Creates a new test window with the given dimensions.
  Window(
    size: ivec2(width.int32, height.int32),
    mousePos: ivec2(0, 0)
  )

proc newWindow*(title: string, size: IVec2, vsync = true): Window =
  ## Creates a new test window with windy-compatible signature.
  Window(
    size: size,
    mousePos: ivec2(0, 0)
  )

proc swapBuffers*(window: Window) {.inline.} =
  ## Stub for swapping buffers.
  discard

proc pollEvents*() {.inline.} =
  ## Stub for polling events.
  discard

proc getClipboardString*(): string =
  ## Stub for getting clipboard content.
  ""

proc makeContextCurrent*(window: Window) {.inline.} =
  ## Stub for OpenGL context creation.
  discard

proc loadExtensions*() {.inline.} =
  ## Stub for loading OpenGL extensions.
  discard

proc resetInputState*(w: Window) =
  ## Resets button pressed and released states for a new frame.
  for i in Button:
    w.buttonPressed[i] = false
    w.buttonReleased[i] = false
  w.scrollDelta = vec2(0, 0)

proc pressButton*(w: Window, button: Button) =
  ## Simulates pressing a mouse button.
  w.buttonDown[button] = true
  w.buttonPressed[button] = true

proc releaseButton*(w: Window, button: Button) =
  ## Simulates releasing a mouse button.
  w.buttonDown[button] = false
  w.buttonReleased[button] = true

proc moveMouse*(w: Window, x, y: int) =
  ## Moves the simulated mouse cursor to the given position.
  w.mousePos = ivec2(x.int32, y.int32)

proc newTestHarness*(atlasImg, atlasJson: string, width = 800, height = 600): TestHarness =
  ## Creates a new test harness with the given atlas files.
  result.window = newWindow(width, height)
  result.frameCount = 0
  result.sk = Silky()
  result.sk.atlas = readFile(atlasJson).fromJson(SilkyAtlas)
  result.sk.layers[NormalLayer] = @[]
  result.sk.layers[PopupsLayer] = @[]
  result.sk.currentLayer = NormalLayer
  result.sk.layerStack = @[]
  result.sk.semantic.enabled = true

proc beginFrame*(h: var TestHarness) =
  ## Begins a new test frame.
  h.sk.pushLayout(vec2(0, 0), h.window.size.vec2)
  h.sk.pushClipRect(rect(0, 0, h.window.size.x.float32, h.window.size.y.float32))
  h.sk.semantic.reset()

proc endFrame*(h: var TestHarness) =
  ## Ends the current test frame and captures the snapshot.
  h.sk.popClipRect()
  h.sk.popLayout()
  h.sk.clear()
  inc h.frameCount
  h.lastSnapshot = h.sk.semantic.toSnapshot()

proc pumpFrame*(h: var TestHarness, onFrame: proc(sk: Silky, window: Window), count = 1): string =
  ## Runs one or more frames and returns the diff from the previous snapshot.
  let previousSnapshot = h.lastSnapshot
  
  for i in 0 ..< count:
    h.beginFrame()
    onFrame(h.sk, h.window)
    h.endFrame()
    h.window.resetInputState()
  
  result = diff(previousSnapshot, h.lastSnapshot)

proc snapshot*(h: TestHarness): string =
  ## Returns the last captured snapshot.
  h.lastSnapshot

proc findByPath*(h: TestHarness, path: string): SemanticNode =
  ## Finds a node by its dot-separated path.
  h.sk.semantic.root.findByPath(path)

proc findByText*(h: TestHarness, text: string, kind = ""): SemanticNode =
  ## Finds a node by its text content and optional kind.
  h.sk.semantic.root.findByText(text, kind)

proc clickPath*(h: var TestHarness, path: string, onFrame: proc(sk: Silky, window: Window)): string =
  ## Clicks a widget by its path and returns the resulting diff.
  let node = h.findByPath(path)
  if node != nil and node.rect.w > 0:
    let centerX = (node.rect.x + node.rect.w / 2).int
    let centerY = (node.rect.y + node.rect.h / 2).int
    h.window.moveMouse(centerX, centerY)
  h.window.pressButton(MouseLeft)
  discard h.pumpFrame(onFrame)
  h.window.releaseButton(MouseLeft)
  return h.pumpFrame(onFrame)

proc clickLabel*(h: var TestHarness, label: string, onFrame: proc(sk: Silky, window: Window)): string =
  ## Clicks a widget by its text label and returns the resulting diff.
  let node = h.findByText(label)
  if node != nil and node.rect.w > 0:
    let centerX = (node.rect.x + node.rect.w / 2).int
    let centerY = (node.rect.y + node.rect.h / 2).int
    h.window.moveMouse(centerX, centerY)
  h.window.pressButton(MouseLeft)
  discard h.pumpFrame(onFrame)
  h.window.releaseButton(MouseLeft)
  return h.pumpFrame(onFrame)

template mousePos*(w: Window): Vec2 =
  ## Returns the mouse position as a Vec2.
  w.mousePos.vec2

template buttonDown*(w: Window, btn: Button): bool =
  ## Returns true if the button is currently held down.
  w.buttonDown[btn]

template buttonPressed*(w: Window, btn: Button): bool =
  ## Returns true if the button was just pressed this frame.
  w.buttonPressed[btn]

template buttonReleased*(w: Window, btn: Button): bool =
  ## Returns true if the button was just released this frame.
  w.buttonReleased[btn]
