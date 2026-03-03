## Tests for atlas JSON embedded inside PNG files.

import
  std/[os, tables],
  pixie,
  silky/atlas

proc assertRaisesMissingChunk(path: string) =
  ## Asserts that reading metadata fails when chunk is missing.
  var raised = false
  try:
    discard readAtlasJsonFromPng(path)
  except SilkyAtlasError:
    raised = true
  doAssert raised, "Expected missing atlas metadata exception"

block:
  echo "Testing atlas builder single-file PNG output"
  let
    outputPath = "tests/dist/atlas_embedded.png"
    builder = newAtlasBuilder(64, 2)
  builder.write(outputPath)
  let loadedAtlas = readAtlasFromPng(outputPath)
  doAssert loadedAtlas != nil
  doAssert WhiteTileKey in loadedAtlas.entries
  let loadedImage = readImage(outputPath)
  doAssert loadedImage.width == builder.size
  doAssert loadedImage.height == builder.size

block:
  echo "Testing direct writePng and metadata roundtrip"
  let
    path = "tests/dist/atlas_custom_chunk.png"
    json = """{"tag":"hello","count":3}"""
    image = newImage(8, 8)
  image.fill(color(1, 0, 0, 1))
  writePng(path, json, image)
  let extracted = readAtlasJsonFromPng(path)
  doAssert extracted == json
  let decoded = readImage(path)
  doAssert decoded.width == 8
  doAssert decoded.height == 8

block:
  echo "Testing failure when metadata chunk is missing"
  let
    path = "tests/dist/plain.png"
    image = newImage(4, 4)
  image.fill(color(0, 1, 0, 1))
  createDir(path.splitPath().head)
  image.writeFile(path)
  assertRaisesMissingChunk(path)

echo "All atlas PNG tests passed."
