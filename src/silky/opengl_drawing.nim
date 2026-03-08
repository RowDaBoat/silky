import
  pixie, opengl, shady, vmath, windy,
  silky/[atlas, drawing_common, shaders]

export drawing_common

var
  mvp: Uniform[Mat4]
  atlasSize: Uniform[Vec2]
  atlasSampler: Uniform[Sampler2D]

proc SilkyVert*(
  pos: Vec2,
  size: Vec2,
  uvPos: array[2, uint16],
  uvSize: array[2, uint16],
  color: ColorRGBX,
  clipPos: Vec2,
  clipSize: Vec2,
  fragmentUv: var Vec2,
  fragmentColor: var Vec4,
  fragmentClipPos: var Vec2,
  fragmentClipSize: var Vec2,
  fragmentPos: var Vec2
) =
  ## Vertex shader for Silky's OpenGL renderer.
  let corner = uvec2(
    uint32(gl_VertexID mod 2),
    uint32(gl_VertexID div 2)
  )

  let
    dx = pos.x + corner.x.float32 * size.x
    dy = pos.y + corner.y.float32 * size.y
  gl_Position = mvp * vec4(dx, dy, 0.0, 1.0)

  let
    sx = float32(uvPos[0]) + float32(corner.x) * float32(uvSize[0])
    sy = float32(uvPos[1]) + float32(corner.y) * float32(uvSize[1])
  fragmentUv = vec2(sx, sy) / atlasSize
  fragmentColor = color.vec4
  fragmentClipPos = clipPos
  fragmentClipSize = clipSize
  fragmentPos = vec2(dx, dy)

proc SilkyFrag*(
  fragmentUv: Vec2,
  fragmentColor: Vec4,
  fragmentClipPos: Vec2,
  fragmentClipSize: Vec2,
  fragmentPos: Vec2,
  fragColor: var Vec4
) =
  ## Fragment shader for Silky's OpenGL renderer.
  if fragmentPos.x < fragmentClipPos.x or
    fragmentPos.y < fragmentClipPos.y or
    fragmentPos.x > fragmentClipPos.x + fragmentClipSize.x or
    fragmentPos.y > fragmentClipPos.y + fragmentClipSize.y:
    discardFragment()
  else:
    fragColor = texture(atlasSampler, fragmentUv) * fragmentColor

proc beginUi*(sk: Silky, window: Window, size: IVec2) =
  ## Begins a new UI frame for the OpenGL backend.
  sk.beginUiShared(window, size)
  glViewport(0, 0, sk.size.x.int32, sk.size.y.int32)

proc clearScreen*(sk: Silky, color: ColorRGBX) {.measure.} =
  ## Clears the current OpenGL framebuffer.
  let c = color.color
  glClearColor(c.r, c.g, c.b, c.a)
  glClear(GL_COLOR_BUFFER_BIT)

proc newSilky*(image: Image, atlas: SilkyAtlas): Silky {.measure.} =
  ## Creates a new Silky with the OpenGL backend initialized.
  result = initSilky(image, atlas)

  when defined(emscripten):
    result.gl.shader = newShader(
      ("SilkyVert", toGLSL(SilkyVert, glslES3)),
      ("SilkyFrag", toGLSL(SilkyFrag, glslES3))
    )
  else:
    result.gl.shader = newShader(
      ("SilkyVert", toGLSL(SilkyVert, glslDesktop)),
      ("SilkyFrag", toGLSL(SilkyFrag, glslDesktop))
    )

  glGenTextures(1, result.gl.atlasTexture.addr)
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, result.gl.atlasTexture)
  glTexImage2D(
    GL_TEXTURE_2D,
    0,
    GL_RGBA8.GLint,
    result.image.width.GLint,
    result.image.height.GLint,
    0,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    cast[pointer](result.image.data[0].addr)
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_MIN_FILTER,
    GL_LINEAR_MIPMAP_LINEAR.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_MAG_FILTER,
    GL_LINEAR.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_S,
    GL_CLAMP_TO_EDGE.GLint
  )
  glTexParameteri(
    GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_T,
    GL_CLAMP_TO_EDGE.GLint
  )
  glGenerateMipmap(GL_TEXTURE_2D)

  glGenVertexArrays(1, result.gl.vao.addr)
  glBindVertexArray(result.gl.vao)
  let program = result.gl.shader.programId

  glGenBuffers(1, result.gl.instanceVbo.addr)
  glBindBuffer(GL_ARRAY_BUFFER, result.gl.instanceVbo)
  glBufferData(GL_ARRAY_BUFFER, 0, nil, GL_STREAM_DRAW)

  let stride = sizeof(SilkyVertex).GLsizei

  template setAttr(
    name: string,
    size: GLint,
    xtype: GLenum,
    normalized: GLboolean,
    offset: int
  ) =
    let loc = glGetAttribLocation(program, name)
    if loc != -1:
      glEnableVertexAttribArray(loc.GLuint)
      glVertexAttribPointer(
        loc.GLuint,
        size,
        xtype,
        normalized,
        stride,
        cast[pointer](offset)
      )
      glVertexAttribDivisor(loc.GLuint, 1)
    else:
      echo "[Warning] Attribute not found: ", name

  setAttr("pos", 2, cGL_FLOAT, GL_FALSE, offsetof(SilkyVertex, pos))
  setAttr("size", 2, cGL_FLOAT, GL_FALSE, offsetof(SilkyVertex, size))
  setAttr(
    "uvPos",
    2,
    GL_UNSIGNED_SHORT,
    GL_FALSE,
    offsetof(SilkyVertex, uvPos)
  )
  setAttr(
    "uvSize",
    2,
    GL_UNSIGNED_SHORT,
    GL_FALSE,
    offsetof(SilkyVertex, uvSize)
  )
  setAttr(
    "color",
    4,
    GL_UNSIGNED_BYTE,
    GL_TRUE,
    offsetof(SilkyVertex, color)
  )
  setAttr(
    "clipPos",
    2,
    cGL_FLOAT,
    GL_FALSE,
    offsetof(SilkyVertex, clipPos)
  )
  setAttr(
    "clipSize",
    2,
    cGL_FLOAT,
    GL_FALSE,
    offsetof(SilkyVertex, clipSize)
  )

  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindVertexArray(0)

proc newSilky*(atlasPngPath: string): Silky {.measure.} =
  ## Creates a new Silky from one atlas PNG file.
  let atlasData = readAtlas(atlasPngPath)
  newSilky(atlasData.image, atlasData.atlas)

proc atlasTextureId*(sk: Silky): GLuint =
  ## Returns the OpenGL texture id of the atlas.
  sk.gl.atlasTexture

proc endUi*(sk: Silky) {.measure.} =
  ## Flushes the queued draws through OpenGL.
  for i in 1 ..< sk.layers.len:
    sk.layers[NormalLayer].add(sk.layers[i])

  let instanceCount = sk.layers[NormalLayer].len
  if instanceCount == 0:
    sk.endUiShared()
    return

  glEnable(GL_BLEND)
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

  glBindBuffer(GL_ARRAY_BUFFER, sk.gl.instanceVbo)
  glBufferData(
    GL_ARRAY_BUFFER,
    sk.layers[NormalLayer].len * sizeof(SilkyVertex),
    sk.layers[NormalLayer][0].addr,
    GL_STREAM_DRAW
  )

  glUseProgram(sk.gl.shader.programId)
  mvp = ortho(0.0'f, sk.size.x, sk.size.y, 0.0'f, -1000.0, 1000.0)
  sk.gl.shader.setUniform("mvp", mvp)
  sk.gl.shader.setUniform(
    "atlasSize",
    vec2(sk.image.width.float32, sk.image.height.float32)
  )
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, sk.gl.atlasTexture)
  sk.gl.shader.setUniform("atlasSampler", 0)
  sk.gl.shader.bindUniforms()

  glBindVertexArray(sk.gl.vao)
  glDrawArraysInstanced(
    GL_TRIANGLE_STRIP,
    0,
    4,
    instanceCount.GLsizei
  )

  glBindVertexArray(0)
  glUseProgram(0)
  glBindTexture(GL_TEXTURE_2D, 0)
  glDisable(GL_BLEND)

  sk.endUiShared()
