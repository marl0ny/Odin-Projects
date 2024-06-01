#VERSION_NUMBER_PLACEHOLDER

#if (__VERSION__ >= 330) || (defined(GL_ES) && __VERSION__ >= 300)
#define texture2D texture
#else
#define texture texture2D
#endif

#if (__VERSION__ > 120) || defined(GL_ES)
precision highp float;
#endif
 
#if __VERSION__ <= 120
varying vec2 UV;
#define fragColor gl_FragColor
#else
in vec2 UV;
out vec4 fragColor;
#endif

uniform float dx;
uniform float dy;
uniform float width;
uniform float height;
uniform int index;
uniform int staggeredMode;
uniform int orderOfAccuracy;

uniform sampler2D tex;


/*
 tex - texture
 uv - centre point
 s - sample step in texture coordinates
 d - absolute value of the step size in the coordinates of the application.

*/
vec4 centredDiff2ndOrder(sampler2D tex, vec2 uv, vec2 s, float d) {
    vec4 valL = texture2D(tex, uv - s);
    vec4 valR = texture2D(tex, uv + s);
    return 0.5*(valR - valL)/d;
}

vec4 centredDiff4thOrder(sampler2D tex, vec2 uv, vec2 s, float d) {
    vec4 b2 = texture2D(tex, uv - 2.0*s);
    vec4 b1 = texture2D(tex, uv - s);
    vec4 f1 = texture2D(tex, uv + s);
    vec4 f2 = texture2D(tex, uv + 2.0*s);
    return (-(f2 - b2)/12.0 + 2.0*(f1 - b1)/3.0)/d;
}

vec4 fowardDiff2ndOrder(sampler2D tex, vec2 uv, vec2 s, float d) {
   vec4 f = texture2D(tex, uv + s);
   vec4 c = texture2D(tex, uv);
   return (f - c)/d;
}

vec4 backwardDiff2ndOrder(sampler2D tex, vec2 uv, vec2 s, float d) {
   vec4 b = texture2D(tex, uv - s);
   vec4 c = texture2D(tex, uv);
   return (c - b)/d;
}

vec4 fowardDiff4thOrder(sampler2D tex, vec2 uv, vec2 s, float d) {
   vec4 f2 = texture2D(tex, uv + 2.0*s);
   vec4 f1 = texture2D(tex, uv + s);
   vec4 c0 = texture2D(tex, uv);
   vec4 b1 = texture2D(tex, uv - s);
   return (-f2/24.0 + 9.0*f1/8.0 - 9.0*c0/8.0 + b1/24.0)/d;
}

vec4 backwardDiff4thOrder(sampler2D tex, vec2 uv, vec2 s, float d) {
   vec4 b2 = texture2D(tex, uv - 2.0*s);
   vec4 b1 = texture2D(tex, uv - s);
   vec4 c0 = texture2D(tex, uv);
   vec4 f1 = texture2D(tex, uv + s);
   return (b2/24.0 - 9.0*b1/8.0 + 9.0*c0/8.0 - f1/24.0)/d;
}

void main() {
    float d = (index == 0)? dx: dy;
    vec2 s = (index == 0)? vec2(dx/width, 0.0): vec2(0.0, dy/height);
    // The destination texture is staggered foward relative to the source
    // texture
    if (staggeredMode >= 1) {
        vec2 uv = (index == 0)?
             (UV + 0.5*vec2(0.0, dy/height)): (UV + 0.5*vec2(dx/width, 0.0));
        if (orderOfAccuracy >= 4)
            fragColor = fowardDiff4thOrder(tex, uv, s, d);
        else
            fragColor = fowardDiff2ndOrder(tex, uv, s, d);
    }
    if (staggeredMode == 0) {
        if (orderOfAccuracy >= 4)
            fragColor = centredDiff4thOrder(tex, UV, s, d);
        else
            fragColor = centredDiff2ndOrder(tex, UV, s, d);
    }
    // The destination texture is staggered backwards relative to the source
    // texture
    if (staggeredMode <= -1) {
        vec2 uv = (index == 0)?
             (UV - 0.5*vec2(0.0, dy/height)): (UV - 0.5*vec2(dx/width, 0.0));
        if (orderOfAccuracy >= 4)
            fragColor = backwardDiff4thOrder(tex, uv, s, d);
        else
            fragColor = backwardDiff2ndOrder(tex, uv, s, d);
    }
}