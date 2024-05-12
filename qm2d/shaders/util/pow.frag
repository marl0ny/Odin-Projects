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
uniform float n;

void main() {
    vec4 val = texture2D(tex, UV);
    fragColor = vec4(pow(abs(val.x), n), pow(abs(val.y), n),
                     pow(abs(val.z), n), pow(abs(val.w), n));
}