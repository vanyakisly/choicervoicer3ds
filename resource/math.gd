extends Resource
class_name Math


func array_sum(arr: Array) -> float:
	var sum: float = 0.0
	for el in arr:
		sum += el
	return sum


func array_mean(arr: Array) -> float:
	if arr.is_empty(): return 0
	return array_sum(arr) / arr.size()


func st_dev(arr: Array) -> float:
	var mean_value: float = array_mean(arr)
	var sum: float = 0.0
	for el in arr:
		sum += pow(el - mean_value, 2.0)
	sum /= arr.size()
	return sqrt(sum)


func covariance(arr1: Array, arr2: Array) -> float:
	var min_size: int = min(arr1.size(), arr2.size())
	var mean1: float = array_mean(arr1)
	var mean2: float = array_mean(arr2)
	var sum: float = 0.0
	for i in range(min_size):
		sum += (arr1[i] - mean1) * (arr2[i] - mean2)
	sum /= max(1, min_size)
	return sum


func correlation_coefficient(arr1: Array, arr2: Array) -> float:
	var covar: float = covariance(arr1, arr2)
	var stdev1: float = st_dev(arr1)
	var stdev2: float = st_dev(arr2)
	return covar / max(1, stdev1 * stdev2)


func dot_product(arr1: Array, arr2: Array) -> float:
	var min_size: int = min(arr1.size(), arr2.size())
	var sum: float = 0.0
	for i in range(min_size):
		sum += arr1[i] * arr2[i]
	return sum


func vector_magnitude(arr: Array) -> float:
	var sum: float = 0.0
	for el in arr:
		sum += pow(el, 2.0)
	return sqrt(sum)


func cosine_similarity(arr1: Array, arr2: Array) -> float:
	var dot_p: float = dot_product(arr1, arr2)
	var vec1: float = vector_magnitude(arr1)
	var vec2: float = vector_magnitude(arr2)
	return dot_p / max(1, (vec1 * vec2))


func jaccard_similarity(arr1: Array, arr2: Array) -> float:
	var min_size: float = min(arr1.size(), arr2.size())
	var sum_min: float = 0.0
	var sum_max: float = 0.0
	for i in range(min_size):
		sum_min += min(arr1[i], arr2[i])
		sum_max += max(arr1[i], arr2[i])
	return sum_min / max(1, sum_max)


func jaccard_binary(arr1: Array, arr2: Array, margin: float = 0.1) -> float:
	var min_size: float = min(arr1.size(), arr2.size())
	var sum: float = 0.0
	for i in range(min_size):
		var v1: float = arr1[i]
		var m1: float = v1 * margin
		if arr2[i] in range(v1 - m1, v1 + m1):
			sum += 1.0
	return sum / max(1, min_size)


func ellenberg_similarity(arr1: Array, arr2: Array) -> float:
	var min_size: float = min(arr1.size(), arr2.size())
	var sum_numerator: float = 0.0
	var sum_denominator: float = 0.0
	for i in range(min_size):
		var xy: float = arr1[i] * arr2[i]
		var sum: float = arr1[i] + arr2[i]
		var nz: float = 1.0 if xy != 0.0 else 0.0
		sum_numerator += nz * sum
		sum_denominator += (2 - nz) * sum
	return sum_numerator / sum_denominator


func similarity_ratio(arr1: Array, arr2: Array) -> float:
	var min_size: float = min(arr1.size(), arr2.size())
	var sum_a: float = 0.0
	var sum_b: float = 0.0
	for i in range(min_size):
		sum_a += arr1[i] * arr2[i]
		sum_b += pow(arr1[i] - arr2[i], 2.0)
	return sum_a / max(1, sum_a + sum_b)


func dynamic_time_warp_path(arr1: Array, arr2: Array) -> Array:
	var distance_matrix: Array = []
	for i in arr1.size():
		distance_matrix.append([])
		for j in arr2.size():
			distance_matrix[i].append(abs(arr1[i] - arr2[j]))

	var accumulated_cost: Array = []
	var initialized_fill: Array = []
	initialized_fill.resize(arr2.size())
	initialized_fill.fill(0)
	for i in arr1.size():
		accumulated_cost.append(initialized_fill.duplicate())

	for i in arr1.size():
		for j in arr2.size():









			if (i == 0) and (j == 0):
				accumulated_cost[i][j] = distance_matrix[i][j]
			elif (i == 0):
				accumulated_cost[i][j] = distance_matrix[i][j] + accumulated_cost[i][j - 1]
			elif (j == 0):
				accumulated_cost[i][j] = distance_matrix[i][j] + accumulated_cost[i - 1][j]
			else:
				accumulated_cost[i][j] = distance_matrix[i][j] + min(
					accumulated_cost[i - 1][j], 
					accumulated_cost[i][j - 1], 
					accumulated_cost[i - 1][j - 1]
				)

	var path: Array = []
	var i = arr1.size() - 1
	var j = arr2.size() - 1
	while (i > 0) or (j > 0):
		path.append([i, j])
		if i == 0:
			j -= 1
		elif j == 0:
			i -= 1
		else:
			var min_neighbor = min(
				accumulated_cost[i - 1][j], 
				accumulated_cost[i][j - 1], 
				accumulated_cost[i - 1][j - 1]
			)
			if min_neighbor == accumulated_cost[i - 1][j]:
				i -= 1
			elif min_neighbor == accumulated_cost[i][j - 1]:
				j -= 1
			else:
				i -= 1
				j -= 1
	path.append([0, 0])






	var path_conversion: Array = [[], []]
	for h in range(path.size() - 1, -1, -1):
		path_conversion[0].append(path[h][0])
		path_conversion[1].append(path[h][1])














	return path_conversion


func warp_from_path(arr: Array, tuple_idx: int, path: Array):
	var new_array: Array = []
	for idx in path[tuple_idx]:
		new_array.append(arr[idx])
	return new_array


func fairweather_similarity(arr1, arr2, exclude_zero: bool = true, _maximum: int = 255):





















	var min_size: float = min(arr1.size(), arr2.size())
	var weight: float = min_size
	var sum: float = 0.0

	if exclude_zero:
		for i in range(min_size):
			if arr1[i] == 0 and arr2[i] == 0:
				weight -= 1
			else:

				sum += fairweather(arr1[i], arr2[i])
	else:
		for i in range(min_size):
			sum += fairweather(arr1[i], arr2[i])

	return sum / max(1, weight)

func fairweather(i, j) -> float:
	var a: float = - tanh((i - j - 40.0) / 16.0)
	var b: float = tanh((i - j + 40.0) / 16.0)
	return min(a, b)


func array_smoothing(arr: Array, width: int, type: String = "average") -> Array:
	var output: Array = []
	match type:
		"max":
			for i in range(arr.size() - width):
				var slice = arr.slice(i, i + width)
				output.append(slice.max())
		"min":
			for i in range(arr.size() - width):
				var slice = arr.slice(i, i + width)
				output.append(slice.min())
		_:
			for i in range(arr.size() - width):
				var slice = arr.slice(i, i + width)
				output.append(array_mean(slice))
	return output
