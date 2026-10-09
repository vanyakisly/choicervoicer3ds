class_name FFT
extends Resource



func fft(arr: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = arr.size()
	if n <= 1: return arr
	var even: = PackedFloat32Array()
	var odd: = PackedFloat32Array()
	for i in range(n):
		if i % 2 == 0:
			even.append(arr[i])
		else: odd.append(arr[i])

	even = fft(even)
	odd = fft(odd)

	var combined: = PackedFloat32Array()
	for i in range(n):
		combined.append(0.0)
	for k in range(n / 2):
		var t: float = exp(-2.0 * PI * k / n) * odd[k]
		combined[k] = even[k] + t
		combined[k + n / 2] = even[k] - t

	return combined
