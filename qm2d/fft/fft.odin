/* Procedures for taking the FFT of array and manipulating the results.

References:

Wikipedia - Cooley–Tukey FFT algorithm
https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm

MathWorld Wolfram - Fast Fourier Transform:
http://mathworld.wolfram.com/FastFourierTransform.html 

William Press et al.
12.2 Fast Fourier Transform (FFT) - Numerical Recipes
https://websites.pmc.ucsc.edu/~fnimmo/eart290c_17/NumericalRecipesinF77.pdf

*/
package fft

import "core:math"
import "core:fmt"
import "core:thread"
import "core:math/cmplx"

@(private)
PI: f32: 3.141592653589793

@(private)
INVSQRT2: f32: 0.7071067811865476


@(private)
transpose::proc(arr: []complex64, n: u32) {
	for i in 0..< n {
		for j in i+1..<n {
			tmp: complex64 = arr[i*n + j]
			arr[i*n + j] = arr[j*n + i]
			arr[j*n + i] = tmp
		}
	}
}

@(private)
reverse_bit_sort::proc(arr: [] complex64, n: u32) {
	u : u32
	d : u32
	rev : u32
	for i : u32 = 0; i < n; i += 1 {
		u = 1
		d = n >> 1
		rev = 0
		for u < n {
			rev += d*((i&u)/u)
			u <<= 1
			d >>= 1
		}
		if rev >= i {
			arr[i], arr[rev] = arr[rev], arr[i]
		}
	}
}

/* Perform the FFT or IFFT in place on a complex-valued array with n
elements. Note that n must be a power of two, or else bad things will
happen.

References:

Wikipedia - Cooley–Tukey FFT algorithm
https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm

MathWorld Wolfram - Fast Fourier Transform:
http://mathworld.wolfram.com/FastFourierTransform.html 

William Press et al.
12.2 Fast Fourier Transform (FFT) - Numerical Recipes
https://websites.pmc.ucsc.edu/~fnimmo/eart290c_17/NumericalRecipesinF77.pdf

*/
@(private)
fft_in_place::proc(arr: []complex64, n: u32, is_inverse: b32) {
	using cmplx
	reverse_bit_sort(arr, n)
	for block_size: u32 = 2; block_size <= n; block_size *= 2 {
		sgn: f32 = 1.0 if is_inverse else -1.0
		e1 := exp(1i*complex64(sgn*2.0*PI/f32(block_size)))
		for j: u32 = 0; j < n; j += block_size {
			e := complex64(1.0)
			for i in 0..< block_size/2 {
				even, odd := arr[j + i], arr[j + i + block_size/2]
				s: f32 = 1.0/f32(n) if is_inverse && block_size == n else 1.0
				arr[j + i] = complex64(s)*(even + odd*e)
				arr[j + i + block_size/2] = complex64(s)*(even - odd*e)
				e *= e1
			}
		}
	}
}

@(private)
ThreadData::struct {
	data: []complex64,
	row_count: u32,
	row_size: u32,
	is_inverse: b32,
}

/* Perform the 1D FFT or IFFT on each row of a square array, where
arr is the row-major square array, n is the dimensions of the array,
th_total is the number of threads, and is_inverse is a bool value
for controlling whether to perform an FFT or IFFT. Note that arr
must have a total size of n*n, n must be a power of two, and n must
be divisible by th_total.
*/
@(private)
parallel_horizontal_square_fft::proc(arr: []complex64,
									 n: u32, th_total: u32,
									 is_inverse: b32) {

	thread_func::proc(t: ^thread.Thread) {
		// For casting pointers of one type to a different type,
		// look at the second example for the Transmute operator
		// from here: https://odin-lang.org/docs/overview/
		thread_data: ThreadData = (^ThreadData)(t.data)^
		data: []complex64 = thread_data.data
		row_count: u32 = thread_data.row_count
		row_size: u32 = thread_data.row_size
		is_inverse: b32 = thread_data.is_inverse
		// fmt.println(row_count)
		// fmt.println(row_size)
		for i in 0..<row_count {
			fft_in_place(data[i*row_size:(i+1)*row_size], 
						 row_size, is_inverse)
		}
	}

	// This is an adaptation of the threading_example procedure from the
	// demo.odin file in the official repository
	// https://github.com/odin-lang/Odin/blob/master/examples/demo/demo.odin
	// The thread.Thread documentation was consulted as well:
	// https://pkg.odin-lang.org/core/thread/#Thread
	threads := make([dynamic]^thread.Thread, 0, th_total)
	defer delete(threads)
	thread_data_arr := make([dynamic]ThreadData, th_total)
	for th_index in 0..<th_total {
		if t := thread.create(thread_func); t != nil {
			thread_data_arr[th_index].data \
				= arr[th_index*n*n/th_total:(th_index+1)*n*n/th_total]
			thread_data_arr[th_index].row_count = n/th_total
			thread_data_arr[th_index].row_size = n
			thread_data_arr[th_index].is_inverse = is_inverse
			t.init_context = context
			t.user_index = int(th_index)
			append(&threads, t)
			t.data = &thread_data_arr[th_index] // raw pointer
			thread.start(t)
		}
	}
	for len(threads) > 0 {
		for i := 0; i < len(threads); {
			if t := threads[i]; thread.is_done(t) {
				thread.destroy(t)
				ordered_remove(&threads, i)
			} else {
				i += 1
			}
		}
	}
}

parallel_square_fft::proc(arr: []complex64,
					      n: u32, th_total: u32,
						  is_inverse: b32) {
	parallel_horizontal_square_fft(arr, n, th_total, is_inverse)
	transpose(arr, n)
	parallel_horizontal_square_fft(arr, n, th_total, is_inverse)
	transpose(arr, n)
}
