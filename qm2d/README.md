# Split Step Implementation in Odin

Use the [split operator method](https://www.algorithm-archive.org/contents/split-operator_method/split-operator_method.html) to numerically solve quantum mechanics problems in 2D. To build and run this program, `cd` into the directory that contains this file and type and enter `odin run .`. By default, this opens the OpenGL and GLFW implementation. Invoke `./qm2d bmp` instead to use the CPU only implementation, where the simulation output is saved as BMP files.

This is a re-implementation of an [older Rust project](https://github.com/marl0ny/Rust-Sims/tree/main/qm2d_split_op).

## References:

### Split-Operator Method:

 - James Schloss. [The Split Operator Method - Arcane Algorithm Archive.](https://www.algorithm-archive.org/contents/split-operator_method/split-operator_method.html)

### Fast Fourier Transform (Used in the Split-Operator method):

 - [Wikipedia - Cooley–Tukey FFT algorithm](https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm)

 - [MathWorld Wolfram - Fast Fourier Transform](http://mathworld.wolfram.com/FastFourierTransform.html)

 - William Press et al. [12.2 Fast Fourier Transform (FFT) - in Numerical Recipes](https://websites.pmc.ucsc.edu/~fnimmo/eart290c_17/NumericalRecipesinF77.pdf)

### Domain coloring method for visualizing complex-valued functions:

 - [Wikipedia - Domain coloring](https://en.wikipedia.org/wiki/Domain_coloring)

 - [Wikipedia - Hue](https://en.wikipedia.org/wiki/Hue)

 - [https://en.wikipedia.org/wiki/Hue#/media/File:HSV-RGB-comparison.svg](https://en.wikipedia.org/wiki/Hue#/media/File:HSV-RGB-comparison.svg)

### Bitmap file format:

 - [Wikipedia - BMP file format](https://en.wikipedia.org/wiki/BMP_file_format)