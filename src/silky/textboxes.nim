## Multi-line text box widget with selection, cursor navigation, clipboard,
## undo/redo, and scroll. Modeled after fidget2's textboxes.nim but adapted
## for silky's atlas-based font rendering.
import
  std/[tables, unicode, times],
  vmath, bumpy, chroma,
  silky/atlas

when defined(silkyTesting):
  import silky/semantic, silky/testing
  proc setClipboardString(value: string) =
    ## Stub for setting clipboard in test mode.
    discard
else:
  import silky/drawing, windy

const
  LF = Rune(10)
  CR = Rune(13)
  CursorWidth* = 2.0f
  DoubleClickTime = 0.4
  SelectionColor = rgbx(30, 60, 130, 128)

when defined(macos):
  const TextBoxScrollSpeed = 10.0f
else:
  const TextBoxScrollSpeed = -10.0f

type
  TextBoxState* = ref object
    ## State for a multi-line text box widget.
    runes*: seq[Rune]
    cursor*: int
    selector*: int
    scrollPos*: Vec2
    savedX*: float32
    focused*: bool
    layout*: seq[Rect]
    dirty*: bool
    undoStack*: seq[(seq[Rune], int)]
    redoStack*: seq[(seq[Rune], int)]
    clickCount*: int
    lastClickTime*: float64
    dragging*: bool
    lineHeight*: float32
    boxSize*: Vec2
    lastMaxWidth*: float32
    blinkTime*: float64

var
  textBoxStates*: Table[string, TextBoxState]

proc vec2(v: SomeNumber): Vec2 =
  ## Create a Vec2 from a single number.
  vec2(v.float32, v.float32)

proc vec2[A, B](x: A, y: B): Vec2 =
  ## Create a Vec2 from two numbers.
  vec2(x.float32, y.float32)

proc resetBlink*(state: TextBoxState) =
  ## Resets the cursor blink timer so the cursor is immediately visible.
  state.blinkTime = epochTime()

proc cursorVisible*(state: TextBoxState): bool =
  ## Returns true when the blinking cursor should be drawn.
  ## Blinks 0.5s on, 0.5s off, always starting visible after a reset.
  ((epochTime() - state.blinkTime) * 2).int mod 2 == 0

proc getText*(state: TextBoxState): string =
  ## Returns the current text content.
  $state.runes

proc setText*(state: TextBoxState, text: string) =
  ## Sets the text content and resets cursor to end.
  state.runes = text.toRunes
  state.cursor = state.runes.len
  state.selector = state.cursor
  state.dirty = true

proc selection*(state: TextBoxState): HSlice[int, int] =
  ## Returns the ordered selection range.
  min(state.cursor, state.selector) .. max(state.cursor, state.selector)

proc computeLayout*(state: TextBoxState, fontData: FontAtlas, maxWidth: float32) =
  ## Computes per-character selection rectangles in local coordinates.
  ## Mirrors the glyph-walking logic from drawText but stores positions
  ## instead of emitting GPU vertices.
  state.layout.setLen(0)
  state.lineHeight = fontData.lineHeight
  state.lastMaxWidth = maxWidth
  var currentPos = vec2(0, 0)
  var i = 0
  while i < state.runes.len:
    let rune = state.runes[i]
    if rune == LF:
      # Newline gets a zero-width rect at line end.
      state.layout.add rect(currentPos.x, currentPos.y, 0, fontData.lineHeight)
      currentPos.x = 0
      currentPos.y += fontData.lineHeight
      inc i
      continue
    # Word wrap: at the start of a word check if it fits on this line.
    if maxWidth < float32.high and currentPos.x > 0 and rune != Rune(32):
      let isWordStart = (i == 0) or
        state.runes[i - 1] == Rune(32) or
        state.runes[i - 1] == LF
      if isWordStart:
        var wordW = 0.0f
        var j = i
        while j < state.runes.len and
            state.runes[j] != Rune(32) and
            state.runes[j] != LF:
          let gs = $state.runes[j]
          if gs in fontData.entries:
            wordW += fontData.entries[gs][0].advance
          elif "?" in fontData.entries:
            wordW += fontData.entries["?"][0].advance
          inc j
        if currentPos.x + wordW > maxWidth:
          currentPos.x = 0
          currentPos.y += fontData.lineHeight
    let glyphStr = $rune
    var entry: LetterEntry
    if glyphStr in fontData.entries:
      entry = fontData.entries[glyphStr][0]
    elif "?" in fontData.entries:
      entry = fontData.entries["?"][0]
    else:
      state.layout.add rect(currentPos.x, currentPos.y, 0, fontData.lineHeight)
      inc i
      continue
    # Character-level wrap fallback for words wider than maxWidth.
    if maxWidth < float32.high and currentPos.x >= maxWidth:
      currentPos.x = 0
      currentPos.y += fontData.lineHeight
    state.layout.add rect(
      currentPos.x, currentPos.y, entry.advance, fontData.lineHeight
    )
    currentPos.x += entry.advance
    # Kerning.
    if i < state.runes.len - 1:
      let nextGlyphStr = $state.runes[i + 1]
      if glyphStr in fontData.entries and
          nextGlyphStr in fontData.entries[glyphStr][0].kerning:
        currentPos.x += fontData.entries[glyphStr][0].kerning[nextGlyphStr]
    inc i
  state.dirty = false

proc pickGlyphAt*(state: TextBoxState, pos: Vec2): int =
  ## Finds the character index closest to the given position.
  ## Returns -1 if no character found on that line.
  var minGlyph = -1
  var minDistance = -1.0f
  for i, selectRect in state.layout:
    if selectRect.y <= pos.y and pos.y < selectRect.y + selectRect.h:
      let dist = abs(pos.x - selectRect.x)
      if minDistance < 0 or dist < minDistance:
        minDistance = dist
        minGlyph = i
  return minGlyph

proc getSelectionRects*(layout: seq[Rect], start, stop: int): seq[Rect] =
  ## Computes merged selection highlight rectangles for a range.
  if start == stop:
    return
  for i, selectRect in layout:
    if i >= start and i < stop:
      if result.len > 0:
        let onSameLine = result[^1].y == selectRect.y and
          result[^1].h == selectRect.h
        let notTooFar = selectRect.x - result[^1].x < result[^1].w * 2
        if onSameLine and notTooFar:
          result[^1].w = selectRect.x - result[^1].x + selectRect.w
          continue
      result.add selectRect

proc innerHeight*(state: TextBoxState): float32 =
  ## Returns the total content height.
  if state.layout.len > 0:
    let lastPos = state.layout[^1]
    return lastPos.y + lastPos.h
  return state.lineHeight

proc locationRect*(state: TextBoxState, loc: int): Rect =
  ## Returns the rectangle where the cursor should be drawn.
  if state.layout.len > 0:
    if loc >= state.layout.len:
      let selectRect = state.layout[^1]
      if state.runes.len > 0 and state.runes[^1] == LF:
        result.x = 0
        result.y = selectRect.y + state.lineHeight
      else:
        result = selectRect
        result.x += selectRect.w
    else:
      result = state.layout[loc]
  result.w = CursorWidth
  result.h = state.lineHeight

proc cursorPos*(state: TextBoxState): Vec2 =
  ## Returns the position of the text cursor.
  state.locationRect(state.cursor).xy

proc undoSave*(state: TextBoxState) =
  ## Saves current state for undo.
  state.undoStack.add((state.runes, state.cursor))
  state.redoStack.setLen(0)

proc undo*(state: TextBoxState) =
  ## Goes back in history.
  if state.undoStack.len > 0:
    state.redoStack.add((state.runes, state.cursor))
    (state.runes, state.cursor) = state.undoStack.pop()
    state.selector = state.cursor
    state.dirty = true
    state.resetBlink()
proc redo*(state: TextBoxState) =
  ## Goes forward in history.
  if state.redoStack.len > 0:
    state.undoStack.add((state.runes, state.cursor))
    (state.runes, state.cursor) = state.redoStack.pop()
    state.selector = state.cursor
    state.dirty = true
    state.resetBlink()

proc removedSelection*(state: TextBoxState): bool =
  ## Removes selected runes and returns true if anything was removed.
  let sel = state.selection
  if sel.a != sel.b:
    for i in countdown(sel.b - 1, sel.a):
      state.runes.delete(i)
    state.cursor = sel.a
    state.selector = state.cursor
    state.dirty = true
    return true
  return false

proc removeSelection*(state: TextBoxState) =
  ## Removes selected runes.
  discard state.removedSelection()

proc scrollToCursor*(state: TextBoxState) =
  ## Adjusts scroll so the cursor stays visible.
  let r = state.locationRect(state.cursor)
  if r.y < state.scrollPos.y:
    state.scrollPos.y = r.y
  if r.y + r.h > state.scrollPos.y + state.boxSize.y:
    state.scrollPos.y = r.y + r.h - state.boxSize.y
  if r.x < state.scrollPos.x:
    state.scrollPos.x = r.x
  if r.x + CursorWidth > state.scrollPos.x + state.boxSize.x:
    state.scrollPos.x = r.x + CursorWidth - state.boxSize.x

proc typeCharacter*(state: TextBoxState, rune: Rune) =
  ## Adds a character at the cursor position.
  state.removeSelection()
  state.undoSave()
  if state.cursor >= state.runes.len:
    state.runes.add(rune)
  else:
    state.runes.insert(rune, state.cursor)
  inc state.cursor
  state.selector = state.cursor
  state.dirty = true
  state.scrollToCursor()
  state.resetBlink()
proc typeCharacters*(state: TextBoxState, s: string) =
  ## Adds multiple characters at the cursor position.
  state.removeSelection()
  state.undoSave()
  for rune in runes(s):
    if rune == CR:
      continue
    if state.cursor >= state.runes.len:
      state.runes.add(rune)
    else:
      state.runes.insert(rune, state.cursor)
    inc state.cursor
  state.selector = state.cursor
  state.dirty = true
  state.scrollToCursor()
  state.resetBlink()

proc copyText*(state: TextBoxState): string =
  ## Returns the text in the current selection.
  let sel = state.selection
  if sel.a != sel.b:
    return $state.runes[sel.a ..< sel.b]

proc pasteText*(state: TextBoxState, s: string) =
  ## Pastes a string at the cursor.
  state.typeCharacters(s)
  state.savedX = state.cursorPos.x

proc cutText*(state: TextBoxState): string =
  ## Cuts selected text and returns it.
  result = state.copyText()
  if result == "":
    return
  state.removeSelection()
  state.savedX = state.cursorPos.x
  state.resetBlink()

proc backspace*(state: TextBoxState) =
  ## Deletes the character before the cursor.
  if state.removedSelection():
    state.resetBlink()
    return
  if state.cursor > 0:
    state.runes.delete(state.cursor - 1)
    dec state.cursor
    state.selector = state.cursor
    state.dirty = true
  state.scrollToCursor()
  state.resetBlink()
proc delete*(state: TextBoxState) =
  ## Deletes the character after the cursor.
  if state.removedSelection():
    state.resetBlink()
    return
  if state.cursor < state.runes.len:
    state.runes.delete(state.cursor)
    state.dirty = true
  state.scrollToCursor()
  state.resetBlink()
proc backspaceWord*(state: TextBoxState) =
  ## Deletes the word before the cursor.
  if state.removedSelection():
    state.resetBlink()
    return
  if state.cursor > 0:
    while state.cursor > 0 and
        not state.runes[state.cursor - 1].isWhiteSpace():
      state.runes.delete(state.cursor - 1)
      dec state.cursor
    state.selector = state.cursor
    state.dirty = true
  state.scrollToCursor()
  state.resetBlink()
proc deleteWord*(state: TextBoxState) =
  ## Deletes the word after the cursor.
  if state.removedSelection():
    state.resetBlink()
    return
  if state.cursor < state.runes.len:
    while state.cursor < state.runes.len and
        not state.runes[state.cursor].isWhiteSpace():
      state.runes.delete(state.cursor)
    state.dirty = true
  state.scrollToCursor()
  state.resetBlink()

proc left*(state: TextBoxState, shift = false) =
  ## Moves the cursor left by one character.
  if state.cursor > 0:
    dec state.cursor
    if not shift:
      state.selector = state.cursor
    state.savedX = state.cursorPos.x
  state.scrollToCursor()
  state.resetBlink()
proc right*(state: TextBoxState, shift = false) =
  ## Moves the cursor right by one character.
  if state.cursor < state.runes.len:
    inc state.cursor
    if not shift:
      state.selector = state.cursor
    state.savedX = state.cursorPos.x
  state.scrollToCursor()
  state.resetBlink()
proc down*(state: TextBoxState, shift = false) =
  ## Moves the cursor down one line.
  if state.layout.len > 0:
    let curPos = state.cursorPos
    let index = state.pickGlyphAt(
      vec2(state.savedX, curPos.y + state.lineHeight * 1.5))
    if index != -1:
      state.cursor = index
      if not shift:
        state.selector = state.cursor
    elif curPos.y >= state.layout[^1].y:
      state.cursor = state.runes.len
      if not shift:
        state.selector = state.cursor
  state.scrollToCursor()
  state.resetBlink()
proc up*(state: TextBoxState, shift = false) =
  ## Moves the cursor up one line.
  if state.layout.len > 0:
    let curPos = state.cursorPos
    let index = state.pickGlyphAt(
      vec2(state.savedX, curPos.y - state.lineHeight * 0.5))
    if index != -1:
      state.cursor = index
      if not shift:
        state.selector = state.cursor
    elif curPos.y <= state.layout[0].y:
      state.cursor = 0
      if not shift:
        state.selector = state.cursor
  state.scrollToCursor()
  state.resetBlink()
proc leftWord*(state: TextBoxState, shift = false) =
  ## Moves the cursor left by one word.
  if state.cursor > 0:
    dec state.cursor
  while state.cursor > 0 and
      not state.runes[state.cursor - 1].isWhiteSpace():
    dec state.cursor
  if not shift:
    state.selector = state.cursor
  state.savedX = state.cursorPos.x
  state.scrollToCursor()
  state.resetBlink()
proc rightWord*(state: TextBoxState, shift = false) =
  ## Moves the cursor right by one word.
  if state.cursor < state.runes.len:
    inc state.cursor
  while state.cursor < state.runes.len and
      not state.runes[state.cursor].isWhiteSpace():
    inc state.cursor
  if not shift:
    state.selector = state.cursor
  state.savedX = state.cursorPos.x
  state.scrollToCursor()
  state.resetBlink()
proc startOfLine*(state: TextBoxState, shift = false) =
  ## Moves the cursor to the start of the current line.
  while state.cursor > 0 and state.runes[state.cursor - 1] != LF:
    dec state.cursor
  if not shift:
    state.selector = state.cursor
  state.savedX = state.cursorPos.x
  state.scrollToCursor()
  state.resetBlink()
proc endOfLine*(state: TextBoxState, shift = false) =
  ## Moves the cursor to the end of the current line.
  while state.cursor < state.runes.len and state.runes[state.cursor] != LF:
    inc state.cursor
  if not shift:
    state.selector = state.cursor
  state.savedX = state.cursorPos.x
  state.scrollToCursor()
  state.resetBlink()
proc pageUp*(state: TextBoxState, shift = false) =
  ## Moves the cursor up by half the box height.
  if state.layout.len == 0:
    return
  let
    curPos = state.cursorPos
    pos = vec2(state.savedX, curPos.y - state.boxSize.y * 0.5)
    index = state.pickGlyphAt(pos)
  if index != -1:
    state.cursor = index
    if not shift:
      state.selector = state.cursor
  elif pos.y <= state.layout[0].y:
    state.cursor = 0
    if not shift:
      state.selector = state.cursor
  state.scrollToCursor()
  state.resetBlink()
proc pageDown*(state: TextBoxState, shift = false) =
  ## Moves the cursor down by half the box height.
  if state.layout.len == 0:
    return
  let
    curPos = state.cursorPos
    pos = vec2(state.savedX, curPos.y + state.boxSize.y * 0.5)
    index = state.pickGlyphAt(pos)
  if index != -1:
    state.cursor = index
    if not shift:
      state.selector = state.cursor
  elif pos.y > state.layout[^1].y:
    state.cursor = state.runes.len
    if not shift:
      state.selector = state.cursor
  state.scrollToCursor()
  state.resetBlink()

proc mouseAction*(state: TextBoxState, mousePos: Vec2, click = true,
    shift = false) =
  ## Handles a mouse click or drag action on the text.
  let index = state.pickGlyphAt(mousePos)
  if index != -1 and index < state.runes.len:
    state.cursor = index
    if state.runes[index] != LF:
      let selectRect = state.layout[index]
      let pickOffset = mousePos.x - selectRect.x
      if pickOffset > selectRect.w / 2:
        inc state.cursor
  else:
    if mousePos.y < 0:
      state.cursor = 0
    elif mousePos.y >= state.innerHeight:
      state.cursor = state.runes.len
  state.savedX = mousePos.x
  if not shift and click:
    state.selector = state.cursor
  state.scrollToCursor()
  state.resetBlink()

proc selectAll*(state: TextBoxState) =
  ## Selects all text.
  state.cursor = 0
  state.selector = state.runes.len

proc selectWord*(state: TextBoxState, mousePos: Vec2) =
  ## Selects the word under the mouse position (double click).
  state.mouseAction(mousePos, click = true)
  while state.cursor > 0 and
      not state.runes[state.cursor - 1].isWhiteSpace():
    dec state.cursor
  while state.selector < state.runes.len and
      not state.runes[state.selector].isWhiteSpace():
    inc state.selector

proc selectParagraph*(state: TextBoxState, mousePos: Vec2) =
  ## Selects the paragraph under the mouse position (triple click).
  state.mouseAction(mousePos, click = true)
  while state.cursor > 0 and state.runes[state.cursor - 1] != LF:
    dec state.cursor
  while state.selector < state.runes.len and
      state.runes[state.selector] != LF:
    inc state.selector

proc scrollBy*(state: TextBoxState, amount, viewportHeight: float32) =
  ## Scrolls the text box vertically by the given amount.
  state.scrollPos.y += amount
  let maxScroll = max(0.0f, state.innerHeight - viewportHeight)
  state.scrollPos.y = clamp(state.scrollPos.y, 0.0f, maxScroll)

template textBox*(id: string, t: var string, boxWidth, boxHeight: float32) =
  ## Multi-line text box widget with editing, selection, and scroll.
  ## Expects `sk: Silky` and `window: Window` in scope.
  block:
    # State management.
    if id notin textBoxStates:
      let newState = TextBoxState(dirty: true)
      newState.setText(t)
      textBoxStates[id] = newState
    let tbState = textBoxStates[id]
    # Sync external changes when not focused.
    if not tbState.focused and tbState.getText() != t:
      tbState.setText(t)
    # Dimensions.
    let tbFontData = sk.atlas.fonts[sk.textStyle]
    let tbPadding = sk.theme.padding.float32
    let tbOuterRect = rect(sk.at, vec2(boxWidth, boxHeight))
    let tbInnerRect = rect(
      sk.at.x + tbPadding,
      sk.at.y + tbPadding,
      boxWidth - tbPadding * 2,
      boxHeight - tbPadding * 2
    )
    tbState.boxSize = vec2(tbInnerRect.w, tbInnerRect.h)
    # Recompute layout when dirty or width changed.
    if tbState.dirty or tbState.layout.len == 0 or
        tbState.lastMaxWidth != tbInnerRect.w:
      tbState.computeLayout(tbFontData, tbInnerRect.w)
    # Modifier key state.
    let tbCtrl = window.buttonDown[KeyLeftControl] or
      window.buttonDown[KeyRightControl] or
      window.buttonDown[KeyLeftSuper] or
      window.buttonDown[KeyRightSuper]
    let tbShift = window.buttonDown[KeyLeftShift] or
      window.buttonDown[KeyRightShift]
    # Focus and mouse click handling.
    let tbMouseVec = vec2(window.mousePos.x.float32, window.mousePos.y.float32)
    let tbMouseInside = tbMouseVec.overlaps(tbOuterRect) and
      tbMouseVec.overlaps(sk.clipRect)
    if window.buttonPressed[MouseLeft]:
      if tbMouseInside:
        tbState.focused = true
        let tbLocalMouse = tbMouseVec - tbInnerRect.xy + tbState.scrollPos
        let tbNow = epochTime()
        if tbNow - tbState.lastClickTime < DoubleClickTime:
          inc tbState.clickCount
        else:
          tbState.clickCount = 1
        tbState.lastClickTime = tbNow
        case tbState.clickCount:
        of 1:
          tbState.mouseAction(tbLocalMouse, click = true, shift = tbShift)
        of 2:
          tbState.selectWord(tbLocalMouse)
        of 3:
          tbState.selectParagraph(tbLocalMouse)
        else:
          tbState.selectAll()
        tbState.dragging = true
      else:
        tbState.focused = false
    # Mouse drag.
    if tbState.dragging:
      if window.buttonDown[MouseLeft] and not window.buttonPressed[MouseLeft]:
        let tbLocalMouse = tbMouseVec - tbInnerRect.xy + tbState.scrollPos
        tbState.mouseAction(tbLocalMouse, click = false, shift = true)
      if window.buttonReleased[MouseLeft] or not window.buttonDown[MouseLeft]:
        tbState.dragging = false
    # Keyboard input when focused.
    if tbState.focused:
      for tbRune in sk.inputRunes:
        tbState.typeCharacter(tbRune)
      if window.buttonPressed[KeyBackspace]:
        if tbCtrl:
          tbState.backspaceWord()
        else:
          tbState.backspace()
      elif window.buttonPressed[KeyDelete]:
        if tbCtrl:
          tbState.deleteWord()
        else:
          tbState.delete()
      elif window.buttonPressed[KeyLeft]:
        if tbCtrl: tbState.leftWord(tbShift)
        else: tbState.left(tbShift)
      elif window.buttonPressed[KeyRight]:
        if tbCtrl: tbState.rightWord(tbShift)
        else: tbState.right(tbShift)
      elif window.buttonPressed[KeyUp]:
        tbState.up(tbShift)
      elif window.buttonPressed[KeyDown]:
        tbState.down(tbShift)
      elif window.buttonPressed[KeyHome]:
        tbState.startOfLine(tbShift)
      elif window.buttonPressed[KeyEnd]:
        tbState.endOfLine(tbShift)
      elif window.buttonPressed[KeyPageUp]:
        tbState.pageUp(tbShift)
      elif window.buttonPressed[KeyPageDown]:
        tbState.pageDown(tbShift)
      elif window.buttonPressed[KeyEnter]:
        tbState.typeCharacter(LF)
      elif tbCtrl:
        if window.buttonPressed[KeyA]:
          tbState.selectAll()
        elif window.buttonPressed[KeyC]:
          let tbCopied = tbState.copyText()
          if tbCopied.len > 0:
            setClipboardString(tbCopied)
        elif window.buttonPressed[KeyX]:
          let tbCut = tbState.cutText()
          if tbCut.len > 0:
            setClipboardString(tbCut)
        elif window.buttonPressed[KeyV]:
          let tbClip = getClipboardString()
          if tbClip.len > 0:
            tbState.pasteText(tbClip)
        elif window.buttonPressed[KeyZ]:
          if tbShift:
            tbState.redo()
          else:
            tbState.undo()
        elif window.buttonPressed[KeyY]:
          tbState.redo()
      # Sync text back to caller variable.
      t = tbState.getText()
    # Recompute layout after edits.
    if tbState.dirty:
      tbState.computeLayout(tbFontData, tbInnerRect.w)
    # Clamp scroll position.
    let tbMaxScrollY = max(0.0f, tbState.innerHeight - tbInnerRect.h)
    tbState.scrollPos.y = clamp(tbState.scrollPos.y, 0.0f, tbMaxScrollY)
    tbState.scrollPos.x = max(0.0f, tbState.scrollPos.x)
    # Draw background.
    if tbState.focused:
      sk.draw9Patch("input.9patch", 6, tbOuterRect.xy, tbOuterRect.wh,
        sk.theme.frameFocusColor)
    else:
      sk.draw9Patch("input.9patch", 6, tbOuterRect.xy, tbOuterRect.wh)
    # Clip to inner area.
    sk.pushClipRect(tbInnerRect)
    let tbTextOrigin = tbInnerRect.xy - tbState.scrollPos
    # Draw selection highlight.
    if tbState.cursor != tbState.selector:
      let tbSel = tbState.selection
      let tbSelRects = getSelectionRects(tbState.layout, tbSel.a, tbSel.b)
      for tbR in tbSelRects:
        sk.drawRect(
          vec2(tbTextOrigin.x + tbR.x, tbTextOrigin.y + tbR.y),
          vec2(tbR.w, tbR.h),
          SelectionColor
        )
    # Draw text.
    let tbText = $tbState.runes
    discard sk.drawText(sk.textStyle, tbText, tbTextOrigin, sk.theme.textColor,
      maxWidth = tbInnerRect.w, wordWrap = true, clip = false)
    # Draw cursor when focused and blink is on.
    if tbState.focused and tbState.cursorVisible:
      let tbCursorRect = tbState.locationRect(tbState.cursor)
      sk.drawRect(
        vec2(tbTextOrigin.x + tbCursorRect.x,
          tbTextOrigin.y + tbCursorRect.y),
        vec2(CursorWidth, tbCursorRect.h),
        sk.theme.textColor
      )
    sk.popClipRect()
    # Scroll wheel handling.
    if tbMouseInside:
      if window.scrollDelta.y != 0:
        tbState.scrollBy(
          window.scrollDelta.y * TextBoxScrollSpeed, tbInnerRect.h)
    # Advance layout.
    sk.advance(vec2(boxWidth, boxHeight))
