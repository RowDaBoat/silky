## 7GUIs UI tests using semantic capture.
## Run with: nim r tests/test.nim (from the7gui folder)
## Skips: Circle Drawer and Cells (incomplete).

when not defined(silkyTesting):
  {.error: "Must compile with -d:silkyTesting".}

import
  std/unittest,
  silky,
  ../the7gui {.all.}

proc resetState() =
  showChallenges = true
  showCounter = false
  showTemperature = false
  showFlightBooker = false
  showTimer = false
  showCRUD = false
  showCircleDrawer = false
  showCells = false
  counter = 0
  celsius = "0"
  fahrenheit = "32"
  flightType = "one-way flight"
  startDateStr = "24.12.2025"
  returnDateStr = "24.12.2025"
  bookedMessage = ""
  timerDuration = 10.0
  timerElapsed = 0.0
  crudPrefix = ""
  crudName = ""
  crudSurname = ""
  crudDatabase = @["Emil, Hans", "Mustermann, Max", "Tisch, Roman"]
  crudSelected = -1
  oldCrudSelected = -1

suite "7GUIs - Challenges Menu":

  setup:
    resetState()
    window.pumpFrame(sk)

  test "challenges SubWindow present":
    let node = sk.semantic.root.findByName("Challenges", "SubWindow")
    check node != nil
    check node.rect.w > 0
    check node.rect.h > 0

  test "all challenge buttons present":
    for name in ["Counter", "Temperature Converter", "Flight Booker",
                 "Timer", "CRUD", "Circle Drawer", "Cells"]:
      let btn = sk.semantic.root.findByText(name, "Button")
      check btn != nil

  test "incomplete challenges are disabled":
    let circle = sk.semantic.root.findByText("Circle Drawer", "Button")
    let cells = sk.semantic.root.findByText("Cells", "Button")
    check circle != nil
    check cells != nil
    check circle.state.enabled == false
    check cells.state.enabled == false

suite "7GUIs - Counter":

  setup:
    resetState()
    showCounter = true
    window.pumpFrame(sk)

  test "counter SubWindow present":
    let node = sk.semantic.root.findByName("Counter", "SubWindow")
    check node != nil

  test "initial count is 0":
    let node = sk.semantic.root.findByText("0")
    check node != nil

  test "count button increments":
    window.clickButton(sk, "Count")
    window.pumpFrame(sk)
    check counter == 1
    let node = sk.semantic.root.findByText("1")
    check node != nil

  test "multiple increments":
    for i in 1 .. 5:
      window.clickButton(sk, "Count")
    window.pumpFrame(sk)
    check counter == 5

suite "7GUIs - Temperature Converter":

  setup:
    resetState()
    showTemperature = true
    window.pumpFrame(sk)

  test "temperature SubWindow present":
    let node = sk.semantic.root.findByName("Temperature Converter", "SubWindow")
    check node != nil

  test "celsius and fahrenheit labels present":
    check sk.semantic.root.findByText("Celsius") != nil
    check sk.semantic.root.findByText("Fahrenheit") != nil

  test "initial values are 0C and 32F":
    check celsius == "0"
    check fahrenheit == "32"

  test "isValidFloat accepts valid numbers":
    check isValidFloat("0") == true
    check isValidFloat("3.14") == true
    check isValidFloat("-10") == true

  test "isValidFloat rejects invalid input":
    check isValidFloat("abc") == false
    check isValidFloat("") == false

suite "7GUIs - Flight Booker":

  setup:
    resetState()
    showFlightBooker = true
    window.pumpFrame(sk)

  test "flight booker SubWindow present":
    let node = sk.semantic.root.findByName("Flight Booker", "SubWindow")
    check node != nil

  test "start date label present":
    check sk.semantic.root.findByText("Start Date") != nil

  test "isValidDate accepts valid dates":
    check isValidDate("24.12.2025") == true
    check isValidDate("01.01.2000") == true

  test "isValidDate rejects invalid dates":
    check isValidDate("not-a-date") == false
    check isValidDate("") == false
    check isValidDate("32.13.2025") == false

  test "book button present and enabled for valid one-way":
    let btn = sk.semantic.root.findByText("Book", "Button")
    check btn != nil
    check btn.state.enabled == true

suite "7GUIs - Timer":

  setup:
    resetState()
    showTimer = true
    window.pumpFrame(sk)

  test "timer SubWindow present":
    let node = sk.semantic.root.findByName("Timer", "SubWindow")
    check node != nil

  test "duration label present":
    check sk.semantic.root.findByText("Duration:") != nil

  test "reset button present":
    let btn = sk.semantic.root.findByText("Reset", "Button")
    check btn != nil
    check btn.state.enabled == true

  test "reset sets elapsed to near 0":
    timerElapsed = 5.0
    window.clickButton(sk, "Reset")
    window.pumpFrame(sk)
    check timerElapsed < 0.1

suite "7GUIs - CRUD":

  setup:
    resetState()
    showCRUD = true
    window.pumpFrame(sk)

  test "CRUD SubWindow present":
    let node = sk.semantic.root.findByName("CRUD", "SubWindow")
    check node != nil

  test "filter prefix label present":
    check sk.semantic.root.findByText("Filter prefix:") != nil

  test "name and surname labels present":
    check sk.semantic.root.findByText("Name:") != nil
    check sk.semantic.root.findByText("Surname:") != nil

  test "CRUD buttons present":
    check sk.semantic.root.findByText("Create", "Button") != nil
    check sk.semantic.root.findByText("Update", "Button") != nil
    check sk.semantic.root.findByText("Delete", "Button") != nil

  test "update and delete disabled with no selection":
    let update = sk.semantic.root.findByText("Update", "Button")
    let delete = sk.semantic.root.findByText("Delete", "Button")
    check update.state.enabled == false
    check delete.state.enabled == false

  test "initial database has 3 entries":
    check crudDatabase.len == 3
    check crudDatabase[0] == "Emil, Hans"
    check crudDatabase[1] == "Mustermann, Max"
    check crudDatabase[2] == "Tisch, Roman"
