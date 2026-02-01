## Test harness for Silky UI testing.
## 
## Provides a Window type and TestHarness for running UI tests without
## a real window or GPU.

import vmath, bumpy, jsony
import silky/[semantic, atlas]

# Re-export Button enum for input handling
type
  Button* = enum
    MouseLeft
    MouseRight
    MouseMiddle
    MouseButton4
    MouseButton5
    DoubleClick
    TripleClick
    QuadrupleClick
    KeyUnknown

export Button

type
  Window* = object
    ## A test window that simulates windy Window for testing.
    size*: IVec2
    mousePos*: IVec2
    buttonDown*: array[Button, bool]
    buttonPressed*: array[Button, bool]
    buttonReleased*: array[Button, bool]
    scrollDelta*: Vec2
    closeRequested*: bool

  TestHarness* = object
    ## Test harness for running Silky UI tests.
    sk*: Silky
    window*: Window
    lastSnapshot*: string
    frameCount*: int

proc newWindow*(width = 800, height = 600): Window =
  Window(
    size: ivec2(width.int32, height.int32),
    mousePos: ivec2(0, 0)
  )

proc resetInputState*(w: var Window) =
  for i in Button:
    w.buttonPressed[i] = false
    w.buttonReleased[i] = false
  w.scrollDelta = vec2(0, 0)

proc pressButton*(w: var Window, button: Button) =
  w.buttonDown[button] = true
  w.buttonPressed[button] = true

proc releaseButton*(w: var Window, button: Button) =
  w.buttonDown[button] = false
  w.buttonReleased[button] = true

proc moveMouse*(w: var Window, x, y: int) =
  w.mousePos = ivec2(x.int32, y.int32)

proc newTestHarness*(atlasImg, atlasJson: string, width = 800, height = 600): TestHarness =
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
  h.sk.pushLayout(vec2(0, 0), h.window.size.vec2)
  h.sk.pushClipRect(rect(0, 0, h.window.size.x.float32, h.window.size.y.float32))
  h.sk.semantic.reset()

proc endFrame*(h: var TestHarness) =
  h.sk.popClipRect()
  h.sk.popLayout()
  h.sk.clear()
  inc h.frameCount
  h.lastSnapshot = h.sk.semantic.toSnapshot()

proc pumpFrame*(h: var TestHarness, onFrame: proc(sk: Silky, window: Window), count = 1): string =
  let previousSnapshot = h.lastSnapshot
  
  for i in 0 ..< count:
    h.beginFrame()
    onFrame(h.sk, h.window)
    h.endFrame()
    # Reset input state AFTER the frame so pressed/released are seen
    h.window.resetInputState()
  
  result = diff(previousSnapshot, h.lastSnapshot)

proc snapshot*(h: TestHarness): string =
  h.lastSnapshot

proc findByPath*(h: TestHarness, path: string): SemanticNode =
  h.sk.semantic.root.findByPath(path)

proc findByText*(h: TestHarness, text: string, kind = ""): SemanticNode =
  h.sk.semantic.root.findByText(text, kind)

proc clickPath*(h: var TestHarness, path: string, onFrame: proc(sk: Silky, window: Window)): string =
  let node = h.findByPath(path)
  if node != nil and node.rect.w > 0:
    let centerX = (node.rect.x + node.rect.w / 2).int
    let centerY = (node.rect.y + node.rect.h / 2).int
    h.window.moveMouse(centerX, centerY)
  
  h.window.pressButton(MouseLeft)
  discard h.pumpFrame(onFrame, 1)
  h.window.releaseButton(MouseLeft)
  result = h.pumpFrame(onFrame, 1)

proc clickLabel*(h: var TestHarness, label: string, onFrame: proc(sk: Silky, window: Window)): string =
  let node = h.findByText(label)
  if node != nil and node.rect.w > 0:
    let centerX = (node.rect.x + node.rect.w / 2).int
    let centerY = (node.rect.y + node.rect.h / 2).int
    h.window.moveMouse(centerX, centerY)
  
  h.window.pressButton(MouseLeft)
  discard h.pumpFrame(onFrame, 1)
  h.window.releaseButton(MouseLeft)
  result = h.pumpFrame(onFrame, 1)

# Compatibility templates for windy-like access
template mousePos*(w: Window): Vec2 =
  w.mousePos.vec2

template buttonDown*(w: Window, btn: Button): bool =
  w.buttonDown[btn]

template buttonPressed*(w: Window, btn: Button): bool =
  w.buttonPressed[btn]

template buttonReleased*(w: Window, btn: Button): bool =
  w.buttonReleased[btn]
