extends Node


func array_sum(array: Array) -> float:
	var sum: float = 0.0
	for number: float in array: sum += number
	return sum


func array_average_mean(array: Array) -> float:
	if array.is_empty(): return 0.0
	return array_sum(array) / array.size()


func array_standard_deviation(array: Array) -> float:
	var mean: float = array_average_mean(array)
	var sum: float = 0.0
	for el: float in array: sum += pow(el - mean, 2.0)
	sum /= array.size()
	return sqrt(sum)


func covariance(array_1: Array, array_2: Array) -> float:
	var mininum_size: int = mini(array_1.size(), array_2.size())
	var mean_1: float = array_average_mean(array_1)
	var mean_2: float = array_average_mean(array_2)
	var sum: float = 0.0
	for i: int in range(mininum_size): sum += (array_1[i] - mean_1) * (array_2[i] - mean_2)
	sum /= maxi(1, mininum_size)
	return sum


func correlation_coefficient(array_1: Array, array_2: Array) -> float:
	var covariance_value: float = covariance(array_1, array_2)
	var standard_deviation_1: float = array_standard_deviation(array_1)
	var standard_deviation_2: float = array_standard_deviation(array_2)
	return covariance_value / maxi(1, standard_deviation_1 * standard_deviation_2)


func dot_product(array_1: Array, array_2: Array) -> float:
	var minimum_size: int = min(array_1.size(), array_2.size())
	var sum: float = 0.0
	for i: int in range(minimum_size): sum += array_1[i] * array_2[i]
	return sum


func vector_magnitude(array: Array) -> float:
	var sum: float = 0.0
	for el: float in array: sum += pow(el, 2.0)
	return sqrt(sum)




func similarity_cosine(array_1: Array, array_2: Array) -> float:
	var dot_product_value: float = dot_product(array_1, array_2)
	var vector_1: float = vector_magnitude(array_1)
	var vector_2: float = vector_magnitude(array_2)
	return dot_product_value / maxf(1.0, (vector_1 * vector_2))


func similarity_jaccard(array_1: Array, array_2: Array) -> float:
	var minimum_size: int = mini(array_1.size(), array_2.size())
	var sum_minimum: float = 0.0
	var sum_maximum: float = 0.0
	for i: int in range(minimum_size):
		sum_minimum += min(array_1[i], array_2[i])
		sum_maximum += max(array_1[i], array_2[i])
	return sum_minimum / maxf(1.0, sum_maximum)


func similarity_jaccard_binary(array_1: Array, array_2: Array, margin: float = 0.1) -> float:
	var minimum_size: float = mini(array_1.size(), array_2.size())
	var sum: float = 0.0
	for i: int in range(minimum_size):
		var v1: float = array_1[i]
		var m1: float = v1 * margin
		if array_2[i] in range(v1 - m1, v1 + m1): sum += 1.0
	return sum / maxi(1, minimum_size)


func similarity_ellenberg(array_1: Array, array_2: Array) -> float:
	var minimum_size: float = mini(array_1.size(), array_2.size())
	var sum_numerator: float = 0.0
	var sum_denominator: float = 0.0
	for i: int in range(minimum_size):
		var xy: float = array_1[i] * array_2[i]
		var sum: float = array_1[i] + array_2[i]
		var nz: float = 1.0 if xy != 0.0 else 0.0
		sum_numerator += nz * sum
		sum_denominator += (2 - nz) * sum
	return sum_numerator / sum_denominator


func similarity_ratio(array_1: Array, array_2: Array) -> float:
	var minimum_size: float = mini(array_1.size(), array_2.size())
	var sum_a: float = 0.0
	var sum_b: float = 0.0
	for i: int in range(minimum_size):
		sum_a += array_1[i] * array_2[i]
		sum_b += pow(array_1[i] - array_2[i], 2.0)
	return sum_a / maxf(1.0, sum_a + sum_b)


func similarity_fairweather(array_1: Array, array_2: Array, exclude_zero: bool = true) -> float:




















	var minimum_size: int = mini(array_1.size(), array_2.size())
	var weight: int = minimum_size
	var sum: float = 0.0

	if exclude_zero:
		for i: int in range(minimum_size):
			if array_1[i] == 0 and array_1[i] == 0: weight -= 1
			else: sum += fairweather(array_1[i], array_2[i])
	else: for i: int in range(minimum_size): sum += fairweather(array_1[i], array_2[i])
	return sum / maxf(1.0, weight)

func fairweather(i: int, j: int) -> float:
	var a: float = - tanh((i - j - 40.0) / 16.0)
	var b: float = tanh((i - j + 40.0) / 16.0)
	return min(a, b)




func array_smoothed(array: Array, width: int, type: String = "") -> Array:
	var output: Array = []
	for i: int in range(maxi(0, array.size() - width)):
		var slice: Array = array.slice(i, i + width)
		match type:
			"max": output.append(slice.max())
			"min": output.append(slice.min())
			_: output.append(array_average_mean(slice))
	return output







const CC_STDEV: float = 0.047;const CS_STDEV: float = 0.0192;const JC_STDEV: float = 0.0285
const CC_STAGE0: float = 0.32;const CC_STAGE1: float = 0.5;const CC_STAGE2: float = 0.75
const CS_STAGE0: float = 0.8;const CS_STAGE1: float = 0.84;const CS_STAGE2: float = 0.89
const JC_STAGE0: float = 0.5;const JC_STAGE1: float = 0.56;const JC_STAGE2: float = 0.65

const FW_STDEV: float = 0.03
const FW_STAGE0: float = 0.0
const FW_STAGE1: float = 0.6
const FW_STAGE2: float = 0.8


func gastro_score(array_1: PackedFloat32Array, array_2: PackedFloat32Array, handicap: float = 0.0, clamp_score: bool = true, handicap_top: float = 0.0) -> int:
	var score_sum: int = 0
	var correlation_coefficient_value: float = correlation_coefficient(array_1, array_2)
	var cosine_similarity_value: float = similarity_cosine(array_1, array_2)
	var jaccard_similarity_value: float = similarity_jaccard(array_1, array_2)
	if correlation_coefficient_value < CC_STAGE0: score_sum -= 1
	if correlation_coefficient_value >= CC_STAGE1 - CC_STDEV * handicap: score_sum += 1
	if correlation_coefficient_value >= CC_STAGE2 - CC_STDEV * handicap_top: score_sum += 1
	if cosine_similarity_value < CS_STAGE0: score_sum -= 1
	if cosine_similarity_value >= CS_STAGE1 - CS_STDEV * handicap: score_sum += 1
	if cosine_similarity_value >= CS_STAGE2 - CS_STDEV * handicap_top: score_sum += 1
	if jaccard_similarity_value < JC_STAGE0: score_sum -= 1
	if jaccard_similarity_value >= JC_STAGE1 - JC_STDEV * handicap: score_sum += 1
	if jaccard_similarity_value >= JC_STAGE2 - JC_STDEV * handicap_top: score_sum += 1
	if score_sum == 6:
		var fairweather_similarity_value = similarity_fairweather(array_1, array_2)
		if fairweather_similarity_value < FW_STAGE0: score_sum -= 1
		if fairweather_similarity_value >= FW_STAGE1 - FW_STDEV * handicap: score_sum += 1
		if fairweather_similarity_value >= FW_STAGE2 - FW_STDEV * handicap: score_sum += 1
		print("Mathematics | FW included due to initial score of 6. FW = %s from %1.3f" % [score_sum - 6, fairweather_similarity_value])
	print("Mathematics | Unclamped score: %s | via %1.3f, %1.3f, %1.3f" % [score_sum, correlation_coefficient_value, cosine_similarity_value, jaccard_similarity_value])

	if score_sum == 8: return 6
	else: return clampi(score_sum, 0, 5)


func gastro_filler(array_1: Array, array_2: Array, handicap: float = 0.0, clamp_score: bool = false, handicap_top: float = 0.0) -> int:
	var brr1: Array = []
	var brr2: Array = []
	var shift: float = abs(array_average_mean(array_1) - array_average_mean(array_2)) / 2.0
	for el in array_1: brr1.append(el + shift)
	for el in array_2: brr2.append(el + shift)
	return gastro_score(brr1, brr2, handicap, clamp_score, handicap_top)


func tri_score_dict(v: Dictionary, p: Dictionary, handicap: float = 0.0, a_weight: float = 1.5, b_weight: float = 3.0, c_weight: float = 2.0) -> float:
	var score1: float = max(0, gastro_filler(array_smoothed(v.average, 3, "average"), array_smoothed(p.average, 3, "average"), handicap - 0.4, false, handicap - 0.25))
	var score2: float = max(0, gastro_score(array_smoothed(v.max, 2, "average"), array_smoothed(p.max, 2, "average"), handicap - 0.4, false, handicap - 0.25))
	var score3: float = max(0, gastro_filler(array_smoothed(v.pitch, 6, "average"), array_smoothed(p.pitch, 6, "average"), handicap - 0.4, false, handicap - 0.25))
	var weighted_score: float = (score1 * a_weight + score2 * b_weight + score3 * c_weight) / (a_weight + b_weight + c_weight)
	return weighted_score



func dynamic_time_warp_path(arr1: Array, arr2: Array) -> Array:
	var distance_matrix: Array = []
	for i in arr1.size():
		distance_matrix.append([])
		for j in arr2.size(): distance_matrix[i].append(abs(arr1[i] - arr2[j]))

	var accumulated_cost: Array = []
	var initialized_fill: Array = []
	initialized_fill.resize(arr2.size())
	initialized_fill.fill(0)
	for i in arr1.size():
		accumulated_cost.append(initialized_fill.duplicate())

	for i in arr1.size():
		for j in arr2.size():
			if (i == 0) and (j == 0): accumulated_cost[i][j] = distance_matrix[i][j]
			elif (i == 0): accumulated_cost[i][j] = distance_matrix[i][j] + accumulated_cost[i][j - 1]
			elif (j == 0): accumulated_cost[i][j] = distance_matrix[i][j] + accumulated_cost[i - 1][j]
			else: accumulated_cost[i][j] = distance_matrix[i][j] + min(
					accumulated_cost[i - 1][j], 
					accumulated_cost[i][j - 1], 
					accumulated_cost[i - 1][j - 1]
				)

	var path: Array = []
	var i = arr1.size() - 1
	var j = arr2.size() - 1
	while (i > 0) or (j > 0):
		path.append([i, j])
		if i == 0: j -= 1
		elif j == 0: i -= 1
		else:
			var min_neighbor = min(
				accumulated_cost[i - 1][j], 
				accumulated_cost[i][j - 1], 
				accumulated_cost[i - 1][j - 1]
			)
			if min_neighbor == accumulated_cost[i - 1][j]: i -= 1
			elif min_neighbor == accumulated_cost[i][j - 1]: j -= 1
			else: i -= 1;j -= 1
	path.append([0, 0])
	var path_conversion: Array = [[], []]
	for h in range(path.size() - 1, -1, -1):
		path_conversion[0].append(path[h][0])
		path_conversion[1].append(path[h][1])
	return path_conversion


func warp_from_path(array: Array, tuple_idx: int, path: Array):
	var new_array: Array = []
	for idx: int in path[tuple_idx]:
		new_array.append(array[idx])
	return new_array


func gen_3_scorer(base_average: PackedByteArray, base_maximum: PackedByteArray, base_pitch: PackedByteArray, 
		comparator_average: PackedByteArray, comparator_maximum: PackedByteArray, comparator_pitch: PackedByteArray, 
		main_weight: float = 0.8) -> float:
	var normal_score: float = tri_score_dict(
		{"average": base_average, "max": base_maximum, "pitch": base_pitch}, 
		{"average": comparator_average, "max": comparator_maximum, "pitch": comparator_pitch})

	var path_average: Array = dynamic_time_warp_path(base_average, comparator_average)
	var path_pitch: Array = dynamic_time_warp_path(base_pitch, comparator_pitch)

	var warp_base: Dictionary = {"average": [], "max": [], "pitch": []}
	var warp_comparator: Dictionary = {"average": [], "max": [], "pitch": []}
	warp_base.average = warp_from_path(base_average, 0, path_average)
	warp_comparator.average = warp_from_path(comparator_average, 1, path_average)
	warp_base.pitch = warp_from_path(base_pitch, 0, path_pitch)
	warp_comparator.pitch = warp_from_path(comparator_pitch, 1, path_pitch)

	var score_warp_average: float = clampf(gastro_filler(warp_base.average, warp_comparator.average, -4.5, false, -3.3), 0.0, 5.5)
	var score_warp_pitch: float = clampf(gastro_filler(warp_base.pitch, warp_comparator.pitch, -4.5, false, -3.3), 0.0, 5.5)
	var score_warp: float = 0.0
	if score_warp_average > score_warp_pitch: score_warp = score_warp_average * 2.0 / 3.0 + score_warp_pitch * 1.0 / 3.0
	else: score_warp = score_warp_average * 1.0 / 3.0 + score_warp_pitch * 2.0 / 3.0
	return normal_score * main_weight + score_warp * (1.0 - main_weight) - 0.4
