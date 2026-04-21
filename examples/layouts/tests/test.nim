## Layout window UI tests using semantic capture.
## Run with: nim r tests/test.nim (from layouts folder)

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import std/unittest
import silky, vmath, bumpy
import ../layouts {.all.}

proc resetState() =
  showOverlapWindow = true

suite "Layouts - Overlap Test":
  setup:
    resetState()
    window.pumpFrame(sk)

  test "buttons overlap - rects intersect":
    let
      behind = sk.semantic.root.findByText("Behind", "Button")
      inFront = sk.semantic.root.findByText("In Front", "Button")
    check inFront.rect.x < behind.rect.x + behind.rect.w
    check inFront.rect.x + inFront.rect.w > behind.rect.x
    check inFront.rect.y < behind.rect.y + behind.rect.h
    check inFront.rect.y + inFront.rect.h > behind.rect.y

  test "In Front button is rendered after Behind":
    let
      behind = sk.semantic.root.findByText("Behind", "Button")
      inFront = sk.semantic.root.findByText("In Front", "Button")
    check inFront.childIndex > behind.childIndex

  test "clicking in the overlapped zone triggers only In Front":
    window.pumpFrame(sk)

    let
      behind = sk.semantic.root.findByText("Behind", "Button")
      inFront = sk.semantic.root.findByText("In Front", "Button")
      intersection = behind.rect and inFront.rect
      overlapCenter = intersection.xy + intersection.wh * 0.5'f

    window.moveMouse(overlapCenter.x.int, overlapCenter.y.int)
    window.pressButton(MouseLeft)
    window.pumpFrame(sk)
    window.releaseButton(MouseLeft)
    window.pumpFrame(sk)

    check behindClicked == false
    check inFrontClicked == true
