import
  std/strutils,
  bumpy, vmath

when defined(silkyTesting):
  import testwindow
else:
  import windy

type Interaction* = enum
  None,
  Pressed,
  Held,
  Released,
  Hovered,
  Disabled

type Interactor* = object
  ## Solve which widget the mouse is interacting with.
  currentId: int = -1
  warmId: int = -1
  hotId: int = -1

proc mouseHover*(
  self: var Interactor,
  mousePos: Vec2,
  clipRect: Rect,
  widgetRect: Rect
): bool =
  ## Resolve mouse hovering by taking information from the last frame.
  inc self.currentId

  let hovering = mousePos.overlaps(widgetRect) and mousePos.overlaps(clipRect)

  if hovering:
    self.warmId = self.currentId

  return self.hotId == self.currentId and hovering

proc interact*(
  self: var Interactor,
  window: Window,
  mousePos: Vec2,
  clipRect: Rect,
  widgetRect: Rect,
  isEnabled: bool
): Interaction =
  ## Determine the interaction given mouse and widget states.
  let
    hover = self.mouseHover(mousePos, clipRect, widgetRect)
    pressed = window.buttonPressed[MouseLeft]
    down = window.buttonDown[MouseLeft]
    released = window.buttonReleased[MouseLeft]

  if not isEnabled:
    return Disabled
  if not hover:
    return None
  if pressed:
    return Pressed
  if down:
    return Held
  if released:
    return Released
  return Hovered

proc endFrame*(self: var Interactor) =
  ## Commit warm state and resets per-frame counters.
  self.hotId = self.warmId
  self.warmId = -1
  self.currentId = -1

proc reset*(self: var Interactor) =
  ## Clear all interaction state.
  ## This should be called after executing user code that can alter the widgets displayed.
  self.hotId = -1
