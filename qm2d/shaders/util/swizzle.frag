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
uniform int c0;
uniform int c1;
uniform int c2;
uniform int c3;

void main() {
    vec4 val = texture2D(tex, UV);
    float x = (c0 < 4 && c0 >= 0)? val[c0]: 0.0;
    float y = (c1 < 4 && c1 >= 0)? val[c1]: 0.0;
    float z = (c2 < 4 && c2 >= 0)? val[c2]: 0.0;
    float w = (c3 < 4 && c3 >= 0)? val[c3]: 0.0;
    fragColor = vec4(x, y, z, w);
}