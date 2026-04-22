#version 450

layout(set = 0, binding = 0) uniform sampler2D tex0;

layout(location = 0) in vec2 fragUv;
layout(location = 1) in vec4 fragColor;
layout(location = 2) in vec2 fragClipPos;
layout(location = 3) in vec2 fragClipSize;
layout(location = 4) in vec2 fragPos;
layout(location = 5) in vec2 fragMaskUv;

layout(location = 0) out vec4 outColor;

void main() {
  if (fragPos.x < fragClipPos.x ||
      fragPos.y < fragClipPos.y ||
      fragPos.x > fragClipPos.x + fragClipSize.x ||
      fragPos.y > fragClipPos.y + fragClipSize.y) {
    discard;
  }
  vec4 base = texture(tex0, fragUv);
  if (fragMaskUv.x >= 0.0) {
    float maskR = texture(tex0, fragMaskUv).r;
    outColor = vec4(base.rgb * mix(vec3(1.0), fragColor.rgb, maskR), base.a * fragColor.a);
  } else {
    outColor = base * fragColor;
  }
}
