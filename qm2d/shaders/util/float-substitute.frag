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
uniform float oldVal;
uniform float newVal;


void main() {
    vec4 originalTexVal = texture2D(tex, UV);
    if (originalTexVal.r == oldVal)
        fragColor = vec4(newVal, newVal, newVal, newVal);
    else
        fragColor = originalTexVal;

}