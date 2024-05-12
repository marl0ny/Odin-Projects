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

uniform sampler2D tex;
uniform int size;

void main() {
    vec4 v = texture2D(tex, UV);
    float res = 0.0;
    if (size >= 1)
        res += v.r*v.r;
    if (size >= 2)
        res += v.g*v.g;
    if (size >= 3)
        res += v.b*v.b;
    if (size >= 4)
        res += v.a*v.a;
    fragColor = vec4(res, res, res, res);
}