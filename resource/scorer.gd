extends Resource
class_name Scorer

var math: = Math.new()


const CC_STDEV: float = 0.047
const CS_STDEV: float = 0.0192
const JC_STDEV: float = 0.0285

const CC_STAGE0: float = 0.32
const CC_STAGE1: float = 0.5
const CC_STAGE2: float = 0.75

const CS_STAGE0: float = 0.8
const CS_STAGE1: float = 0.84
const CS_STAGE2: float = 0.89

const JC_STAGE0: float = 0.5
const JC_STAGE1: float = 0.56
const JC_STAGE2: float = 0.65


const FW_STDEV: float = 0.03
const FW_STAGE0: float = 0.0
const FW_STAGE1: float = 0.6
const FW_STAGE2: float = 0.8

func gastro_score(arr1: Array, arr2: Array, handicap: float = 0.0, clamp_score: bool = true, handicap_top: float = 0.0) -> int:
	var score_sum: int = 0
	var correlation_coefficient = math.correlation_coefficient(arr1, arr2)
	var cosine_similarity = math.cosine_similarity(arr1, arr2)
	var jaccard_similarity = math.jaccard_similarity(arr1, arr2)

	if correlation_coefficient < CC_STAGE0:
		score_sum -= 1
	if correlation_coefficient >= CC_STAGE1 - CC_STDEV * handicap:
		score_sum += 1
	if correlation_coefficient >= CC_STAGE2 - CC_STDEV * handicap_top:
		score_sum += 1

	if cosine_similarity < CS_STAGE0:
		score_sum -= 1
	if cosine_similarity >= CS_STAGE1 - CS_STDEV * handicap:
		score_sum += 1
	if cosine_similarity >= CS_STAGE2 - CS_STDEV * handicap_top:
		score_sum += 1

	if jaccard_similarity < JC_STAGE0:
		score_sum -= 1
	if jaccard_similarity >= JC_STAGE1 - JC_STDEV * handicap:
		score_sum += 1
	if jaccard_similarity >= JC_STAGE2 - JC_STDEV * handicap_top:
		score_sum += 1

	if score_sum == 6:
		var fairweather_similarity = math.fairweather_similarity(arr1, arr2)
		if fairweather_similarity < FW_STAGE0: score_sum -= 1
		if fairweather_similarity >= FW_STAGE1 - FW_STDEV * handicap: score_sum += 1
		if fairweather_similarity >= FW_STAGE2 - FW_STDEV * handicap: score_sum += 1
		print("Scorer | FW included due to initial score of 6. FW = %s from %1.3f" % [score_sum - 6, fairweather_similarity])


	print("Math | Unclamped score: %s | via %1.3f, %1.3f, %1.3f" % [score_sum, correlation_coefficient, cosine_similarity, jaccard_similarity])





	if score_sum == 8:
		return 6
	else:
		return clampi(score_sum, 0, 5)


func tri_score(a1: Array, a2: Array, b1: Array, b2: Array, c1: Array, c2: Array, handicap: float = 0.0, a_weight: float = 4.0, b_weight: float = 2.0, c_weight: float = 2.0) -> int:
	var score1: float = max(gastro_filler(a1, a2, handicap, false), 0)
	var score2: float = max(gastro_score(b1, b2, handicap, false), 0)
	var score3: float = max(gastro_filler(c1, c2, handicap, false), 0)

	var fuse_score: float = (score1 * a_weight + score2 * b_weight + score3 * c_weight) / (a_weight + b_weight + c_weight)
	return roundi(fuse_score)


func gastro_filler(arr1: Array, arr2: Array, handicap: float = 0.0, clamp_score: bool = false, handicap_top: float = 0.0) -> int:
	var brr1: Array = []
	var brr2: Array = []
	var shift: float = abs(math.array_mean(arr1) - math.array_mean(arr2)) / 2.0
	for el in arr1:
		brr1.append(el + shift)
	for el in arr2:
		brr2.append(el + shift)
	return gastro_score(brr1, brr2, handicap, clamp_score, handicap_top)


func range_data(array: Array):
	print("Scorer |     Array avg/max: %1.1f / %1.1f" % [math.array_mean(array), array.max()])




func tri_score_dict(v: Dictionary, p: Dictionary, handicap: float = 0.0, a_weight: float = 1.5, b_weight: float = 3.0, c_weight: float = 2.0) -> float:
	var score1: float = max(0, gastro_filler(math.array_smoothing(v.average, 3, "average"), math.array_smoothing(p.average, 3, "average"), handicap - 0.4, false, handicap - 0.25))
	var score2: float = max(0, gastro_score(math.array_smoothing(v.max, 2, "average"), math.array_smoothing(p.max, 2, "average"), handicap - 0.4, false, handicap - 0.25))
	var score3: float = max(0, gastro_filler(math.array_smoothing(v.pitch, 6, "average"), math.array_smoothing(p.pitch, 6, "average"), handicap - 0.4, false, handicap - 0.25))
	var weighted_score: float = (score1 * a_weight + score2 * b_weight + score3 * c_weight) / \
	(a_weight + b_weight + c_weight)

	return weighted_score


func tweaker_freaker(v: Dictionary, p: Dictionary, main_weight: float = 0.8):





	var normal_score: float
	if M.data.settings.match_settings.easier_scoring:
		normal_score = tri_score_dict(v, p, 0.0)
		print("non-easy: %s" % tri_score_dict(v, p, 0.0, 4.0, 2.0, 2.0))
	else:
		print("easy: %s" % tri_score_dict(v, p, 0.0))
		normal_score = tri_score_dict(v, p, 0.0, 4.0, 2.0, 2.0)

	print("Scorer | weighted_score %1.3f" % normal_score)

	var warp_v: Dictionary = {
		"average": [], "max": [], "pitch": []}
	var warp_p: Dictionary = {
		"average": [], "max": [], "pitch": []}

	var path_average: Array = math.dynamic_time_warp_path(v.average, p.average)

	var path_pitch: Array = math.dynamic_time_warp_path(v.pitch, p.pitch)

	warp_v.average = math.warp_from_path(v.average, 0, path_average)
	warp_p.average = math.warp_from_path(p.average, 1, path_average)

	warp_v.pitch = math.warp_from_path(v.pitch, 0, path_pitch)
	warp_p.pitch = math.warp_from_path(p.pitch, 1, path_pitch)



	var score_warp_average: float = clampf(gastro_filler(warp_v.average, warp_p.average, -4.5, false, -3.3), 0.0, 5.5)
	var score_warp_pitch: float = clampf(gastro_filler(warp_v.pitch, warp_p.pitch, -4.5, false, -3.3), 0.0, 5.5)
	var score_warp: float = 0.0
	if score_warp_average > score_warp_pitch:
		score_warp = score_warp_average * 2.0 / 3.0 + score_warp_pitch * 1.0 / 3.0
	else:
		score_warp = score_warp_average * 1.0 / 3.0 + score_warp_pitch * 2.0 / 3.0
	print("Scorer | warp scores: %s, %s" % [score_warp_average, score_warp_pitch])
	print("Scorer | Weights applied: %1.2f, %1.2f" % [normal_score * main_weight, score_warp * (1.0 - main_weight)])
	return normal_score * main_weight + score_warp * (1.0 - main_weight) - 0.4




















func diamond_region(v: PackedByteArray, p: PackedByteArray, x_interval: int = 3, y_interval: int = 8) -> float:
	const RETRYTHRESHOLD: float = 8.5
	var control: PackedByteArray = v.duplicate()
	var inspect: PackedByteArray = p.duplicate()
	var array_size: int = mini(control.size(), inspect.size())
	control.resize(array_size)
	inspect.resize(array_size)
	var region_numbers: PackedByteArray = []

	var has_region_overlap: Callable = func(sample: int, i: int, x: int, y: int) -> bool:
		var v_region: Array = [sample - y_interval * y, sample + y_interval * y]
		var p_cut: Array = Array(inspect.slice(
			max(i - x_interval * x, 0), 
			min(i + 1 + x_interval * x, array_size)
		))
		var p_region: Array = [p_cut.min(), p_cut.max()]
		return max(v_region[0], p_region[0]) <= min(v_region[1], p_region[1])

	for i in range(array_size):
		var vclip_sample = control[i]
		if has_region_overlap.call(vclip_sample, i, 0, 0): region_numbers.append(10)
		elif has_region_overlap.call(vclip_sample, i, 0, 1): region_numbers.append(9)
		elif has_region_overlap.call(vclip_sample, i, 1, 0): region_numbers.append(9)
		elif has_region_overlap.call(vclip_sample, i, 1, 1): region_numbers.append(8)
		elif has_region_overlap.call(vclip_sample, i, 2, 1): region_numbers.append(7)
		elif has_region_overlap.call(vclip_sample, i, 2, 2): region_numbers.append(5)
		elif has_region_overlap.call(vclip_sample, i, 3, 2): region_numbers.append(4)
		elif has_region_overlap.call(vclip_sample, i, 3, 3): region_numbers.append(2)
		elif has_region_overlap.call(vclip_sample, i, 4, 3): region_numbers.append(1)
		else: region_numbers.append(0)
	var result_natural: float = math.array_mean(region_numbers)
	if result_natural < RETRYTHRESHOLD:
		region_numbers.clear()
		var v_mean_average: float = math.array_mean(v)
		var p_mean_average: float = math.array_mean(p)
		for sample_index in range(array_size):
			inspect[sample_index] = inspect[sample_index] * v_mean_average / p_mean_average
		for i in range(array_size):
			var vclip_sample = control[i]
			if has_region_overlap.call(vclip_sample, i, 0, 0): region_numbers.append(9)
			elif has_region_overlap.call(vclip_sample, i, 0, 1): region_numbers.append(8)
			elif has_region_overlap.call(vclip_sample, i, 1, 0): region_numbers.append(8)
			elif has_region_overlap.call(vclip_sample, i, 1, 1): region_numbers.append(8)
			elif has_region_overlap.call(vclip_sample, i, 2, 1): region_numbers.append(7)
			elif has_region_overlap.call(vclip_sample, i, 2, 2): region_numbers.append(5)
			elif has_region_overlap.call(vclip_sample, i, 3, 2): region_numbers.append(4)
			elif has_region_overlap.call(vclip_sample, i, 3, 3): region_numbers.append(2)
			elif has_region_overlap.call(vclip_sample, i, 4, 3): region_numbers.append(1)
			else: region_numbers.append(0)
		var result_redo: float = math.array_mean(region_numbers)
		print("Natural: %1.3f, Redo: %1.3f" % [result_natural, result_redo])
		return max(result_natural, result_redo)
	else:
		print("Natural: %1.3f" % result_natural)
		return result_natural









func test_analyzer(v: Array, p: Array):
	var cc: float = math.correlation_coefficient(v, p)
	var cs: float = math.cosine_similarity(v, p)
	var jc: float = math.jaccard_similarity(v, p)

	var eb: float = math.ellenberg_similarity(v, p)
	var sr: float = math.similarity_ratio(v, p)

	var fw: float = math.fairweather_similarity(v, p, true)

	print("PreDTW || CorrCoeff: %1.3f | CosSim: %1.3f | Jacc: %1.3f | Ellen: %1.3f | Simrat: %1.3f | FairWth: %1.3f" % [
		cc, cs, jc, eb, sr, fw
	])

	var path: Array = math.dynamic_time_warp_path(v, p)

	var vd: Array = math.warp_from_path(v, 0, path)
	var pd: Array = math.warp_from_path(p, 1, path)

	cc = math.correlation_coefficient(vd, pd)
	cs = math.cosine_similarity(vd, pd)
	jc = math.jaccard_similarity(vd, pd)

	eb = math.ellenberg_similarity(vd, pd)
	sr = math.similarity_ratio(vd, pd)

	fw = math.fairweather_similarity(vd, pd, true)

	print("PreDTW || CorrCoeff: %1.3f | CosSim: %1.3f | Jacc: %1.3f | Ellen: %1.3f | Simrat: %1.3f | FairWth: %1.3f" % [
		cc, cs, jc, eb, sr, fw
	])
	print("")


func placeholder_scoring(v: Array, p: Array) -> int:
	var path: Array = math.dynamic_time_warp_path(v, p)

	v = math.warp_from_path(v, 0, path)
	p = math.warp_from_path(p, 1, path)

	var collective: float = 0.0

	var cc: float = math.correlation_coefficient(v, p)
	var cs: float = math.cosine_similarity(v, p)


	var eb: float = math.ellenberg_similarity(v, p)
	var sr: float = math.similarity_ratio(v, p)

	var fw: float = math.fairweather_similarity(v, p, true)

	if cc > 0.8: collective += 1.0
	if cc > 0.92: collective += 1.0

	if cs > 0.9: collective += 1.0
	if cs > 0.95: collective += 1.0

	if eb > 0.92: collective += 1.0
	if eb > 0.96: collective += 1.0

	if sr > 0.7: collective += 1.0
	if sr > 0.88: collective += 1.0

	if fw > 0.78: collective += 1.0
	if fw > 0.91: collective += 1.0

	return clampi(int(collective * 5.0 / 9.0), 0, 5)









func self_score(arr: Array, width: int, d: Dictionary, type: String = "average") -> int:
	return TEST_prescore(arr, math.array_smoothing(arr, width, type), d)


func TEST_postscore(v: Array, p: Array, d: Dictionary) -> int:
	var path: Array = math.dynamic_time_warp_path(v, p)

	v = math.warp_from_path(v, 0, path)
	p = math.warp_from_path(p, 1, path)

	var collective: float = 0.0

	var cc: float = math.correlation_coefficient(v, p)
	var cs: float = math.cosine_similarity(v, p)


	var eb: float = math.ellenberg_similarity(v, p)
	var sr: float = math.similarity_ratio(v, p)

	var fw: float = math.fairweather_similarity(v, p, true)

	if cc > d.spin_cc_1.value: collective += 1.0
	if cc > d.spin_cc_2.value: collective += 1.0

	if cs > d.spin_cs_1.value: collective += 1.0
	if cs > d.spin_cs_2.value: collective += 1.0

	if eb > d.spin_el_1.value: collective += 1.0
	if eb > d.spin_el_2.value: collective += 1.0

	if sr > d.spin_sr_1.value: collective += 1.0
	if sr > d.spin_sr_2.value: collective += 1.0

	if fw > d.spin_fw_1.value: collective += 1.0
	if fw > d.spin_fw_2.value: collective += 1.0

	return roundi(collective * 5.0 / 9.0)


func TEST_prescore(v: Array, p: Array, d: Dictionary) -> int:
	var collective: float = 0.0

	var cc: float = math.correlation_coefficient(v, p)
	var cs: float = math.cosine_similarity(v, p)


	var eb: float = math.ellenberg_similarity(v, p)
	var sr: float = math.similarity_ratio(v, p)

	var fw: float = math.fairweather_similarity(v, p, true)

	if cc > d.spin_cc_1.value: collective += 1.0
	if cc > d.spin_cc_2.value: collective += 1.0

	if cs > d.spin_cs_1.value: collective += 1.0
	if cs > d.spin_cs_2.value: collective += 1.0

	if eb > d.spin_el_1.value: collective += 1.0
	if eb > d.spin_el_2.value: collective += 1.0

	if sr > d.spin_sr_1.value: collective += 1.0
	if sr > d.spin_sr_2.value: collective += 1.0

	if fw > d.spin_fw_1.value: collective += 1.0
	if fw > d.spin_fw_2.value: collective += 1.0

	return roundi(collective * 5.0 / 9.0)





func score_from_linear_regression(vclip_data: Dictionary, plmic_data: Dictionary) -> float:
	var simis_: Array = grand_slam_data_get2(vclip_data, plmic_data)
	var score: float = linear_regression_model_FT2(simis_)
	return score


func grand_slam_data_get(vclip_data: Dictionary, plmic_data: Dictionary) -> Array:
	var input_simis: Array = []

	var ori_vclip_avg: Array = []
	var ori_vclip_max: Array = []
	var ori_vclip_pch: Array = []

	var war_vclip_avg: Array = []
	var war_vclip_max: Array = []
	var war_vclip_pch: Array = []

	var smt_vclip_avg: Array = []
	var smt_vclip_max: Array = []
	var smt_vclip_pch: Array = []

	var ori_plmic_avg: Array = []
	var ori_plmic_max: Array = []
	var ori_plmic_pch: Array = []

	var war_plmic_avg: Array = []
	var war_plmic_max: Array = []
	var war_plmic_pch: Array = []

	var smt_plmic_avg: Array = []
	var smt_plmic_max: Array = []
	var smt_plmic_pch: Array = []

	ori_vclip_avg = vclip_data.average
	ori_vclip_max = vclip_data.max
	ori_vclip_pch = vclip_data.pitch

	var warp_pair: Dictionary = get_warps(vclip_data, plmic_data)
	war_vclip_avg = warp_pair.warp_vclip_data.average
	war_vclip_max = warp_pair.warp_vclip_data.max
	war_vclip_pch = warp_pair.warp_vclip_data.pitch

	smt_vclip_avg = math.array_smoothing(ori_vclip_avg, 6)
	smt_vclip_max = math.array_smoothing(ori_vclip_max, 6)
	smt_vclip_pch = math.array_smoothing(ori_vclip_pch, 6)

	ori_plmic_avg = plmic_data.average
	ori_plmic_max = plmic_data.max
	ori_plmic_pch = plmic_data.pitch

	war_plmic_avg = warp_pair.warp_plmic_data.average
	war_plmic_max = warp_pair.warp_plmic_data.max
	war_plmic_pch = warp_pair.warp_plmic_data.pitch

	smt_plmic_avg = math.array_smoothing(ori_plmic_avg, 6)
	smt_plmic_max = math.array_smoothing(ori_plmic_max, 6)
	smt_plmic_pch = math.array_smoothing(ori_plmic_pch, 6)

	var iterate: Array = [
		ori_vclip_avg, 
		ori_vclip_max, 
		ori_vclip_pch, 
		war_vclip_avg, 
		war_vclip_max, 
		war_vclip_pch, 
		smt_vclip_avg, 
		smt_vclip_max, 
		smt_vclip_pch, 
		ori_plmic_avg, 
		ori_plmic_max, 
		ori_plmic_pch, 
		war_plmic_avg, 
		war_plmic_max, 
		war_plmic_pch, 
		smt_plmic_avg, 
		smt_plmic_max, 
		smt_plmic_pch]

	for waveset in iterate:
		input_simis.append(math.array_mean(waveset))
		input_simis.append(math.st_dev(waveset))
		input_simis.append(waveset.max())



	input_simis.append_array(simis(ori_vclip_avg, ori_plmic_avg))
	input_simis.append_array(simis(ori_vclip_max, ori_plmic_max))
	input_simis.append_array(simis(ori_vclip_pch, ori_plmic_pch))

	input_simis.append_array(simis(ori_vclip_avg, smt_vclip_avg))
	input_simis.append_array(simis(ori_vclip_max, smt_vclip_max))
	input_simis.append_array(simis(ori_vclip_pch, smt_vclip_pch))

	input_simis.append_array(simis(ori_plmic_avg, smt_plmic_avg))
	input_simis.append_array(simis(ori_plmic_max, smt_plmic_max))
	input_simis.append_array(simis(ori_plmic_pch, smt_plmic_pch))

	input_simis.append_array(simis(war_vclip_avg, war_plmic_avg))
	input_simis.append_array(simis(war_vclip_max, war_plmic_max))
	input_simis.append_array(simis(war_vclip_pch, war_plmic_pch))

	input_simis.append_array(simis(smt_vclip_avg, smt_plmic_avg))
	input_simis.append_array(simis(smt_vclip_max, smt_plmic_max))
	input_simis.append_array(simis(smt_vclip_pch, smt_plmic_pch))
	return input_simis

func get_warps(vclip_data: Dictionary, plmic_data) -> Dictionary:
	var warp_pair: Dictionary = {"warp_vclip_data": {}, "warp_plmic_data": {}}
	for waveform in ["average", "max", "pitch"]:
		var path: Array = math.dynamic_time_warp_path(vclip_data[waveform], plmic_data[waveform])
		warp_pair.warp_vclip_data[waveform] = math.warp_from_path(vclip_data[waveform], 0, path)
		warp_pair.warp_plmic_data[waveform] = math.warp_from_path(plmic_data[waveform], 1, path)
	return warp_pair

func simis(arr1, arr2) -> Array:
	var array_of_simis: Array = []
	array_of_simis.append(math.correlation_coefficient(arr1, arr2))
	array_of_simis.append(math.cosine_similarity(arr1, arr2))
	array_of_simis.append(math.jaccard_similarity(arr1, arr2))
	array_of_simis.append(math.ellenberg_similarity(arr1, arr2))
	array_of_simis.append(math.similarity_ratio(arr1, arr2))
	array_of_simis.append(math.fairweather_similarity(arr1, arr2))
	return array_of_simis

func abs_difference(arr1: Array, arr2: Array) -> Array:
	var output: Array = []
	for i in range(min(arr1.size(), arr2.size())):
		output.append(abs(arr1[i] - arr2[i]))
	return output

func white_array(arr1: Array, arr2: Array) -> Array:
	var output: Array = []
	for i in range(min(arr1.size(), arr2.size())):
		output.append(min(arr1[i], arr2[i]))
	return output

func power_couple_half_divy(arr1: Array, arr2: Array) -> Array:
	var length_in_seconds = arr1.size() / 60.0
	var section_count: int = maxi(1, ceili(length_in_seconds / 0.5))
	var section_lengthi = int(length_in_seconds / section_count * 60.0)
	var ccs: Array = []
	var fws: Array = []
	for sli in range(0, arr1.size(), section_lengthi):
		var slice1: Array = arr1.slice(sli, sli + section_lengthi)
		var slice2: Array = arr2.slice(sli, sli + section_lengthi)
		var min_size: int = mini(slice1.size(), slice2.size())
		if min_size > 0:
			slice1.resize(min_size)
			slice2.resize(min_size)
			ccs.append(math.correlation_coefficient(slice1, slice2))
			fws.append(math.fairweather_similarity(slice1, slice2))
	var cc_sum: float = clampf(math.array_sum(ccs) / max(1.0, section_count - 1), 0.0, 1.0)
	var fw_sum: float = clampf(math.array_sum(fws) / max(1.0, section_count - 1), 0.0, 1.0)
	return [cc_sum, fw_sum]


func linear_regression_model_FT(simis_: Array) -> float:
	var score: float = MODEL_FT_INTERCEPT
	for i in range(MODEL_FT_COEF.size()):
		score += MODEL_FT_COEF[i] * simis_[i]
	return score

const MODEL_FT_INTERCEPT: float = -21.508957333541467
const MODEL_FT_COEF: Array = [
	-0.129925785, -0.138091926, 0.0360295876, -0.127065633, 
		0.20594595500000001, -0.00938887981, -0.0453971544, 0.152556108, 
	-0.0204859752, 0.0940726118, -0.228647448, -0.00735312196, 
	-0.126492955, -0.0149893401, -0.0145764587, -0.106963422, 
	-0.124791526, -0.0241243393, -0.0875316366, 0.177481598, 
	-0.025915403, 0.131141823, -0.225158864, 0.127682983, 
		0.215593697, 0.131639421, 0.00269141846, 0.266468064, 
		0.481455401, -0.0049450605, -0.411897095, -0.24986122, 
		0.0292578604, -0.190909307, -0.509005124, -0.00697453137, 
	-0.321549516, -0.339150892, -0.00580698206, 0.422882188, 
		0.153740677, 0.0291223198, 0.14730114, 0.400759752, 
	-0.00708968437, -0.136519693, -0.144039187, 0.0220575923, 
		0.189048287, -0.0152221416, -0.0140656519, 0.0708444907, 
		0.421057908, 0.018451758, 0.2702505, 0.0779647332, 
		0.110230118, -0.00552598704, 0.130062807, 0.417751911, 
		0.0968205979, 0.000665170944, 0.036338261, 0.00847011388, 
		0.0228281472, 0.183901107, 0.103807558, 0.00571713442, 
		0.0412708707, 0.0251979303, 0.0514241174, 0.146977129, 
		0.000308598845, -0.0125825025, -0.0173361548, 0.00339963124, 
	-0.0154953988, -0.0172813044, -0.0279106944, 0.00114403657, 
	-0.010007345, 0.0141504856, -0.00255120747, -0.041025666, 
	-0.0539468061, -0.00204233904, -0.00954639735, 0.0146362281, 
	-0.00769176887, 0.000939147477, -0.0574222791, -0.025015418, 
	-0.0320766807, -0.00248318983, -0.0290616135, -0.145939653, 
	-0.0291932204, -0.00274454201, -0.0159929155, -0.00839316562, 
	-0.0178827, -0.0830207501, -0.0246346643, 0.00676424679, 
	-0.0457206599, -0.0131233887, -0.032704163, 0.0490428192, 
	-0.13046328, -0.0507750919, -0.0580829841, -0.0505573905, 
	-0.0881964477, -0.0667608535, -0.0497513575, -0.0103984339, 
	-0.0225935904, -0.00410952142, -0.0155401427, -0.0515806837, 
		0.00697546762, -0.00152287574, 0.0170918705, 0.024724627, 
		0.0186828917, 0.0952756184, 0.367026419, 0.0972600481, 
		0.166352911, 0.0465498843, 0.179357005, 0.499375224, 
		0.158443308, 0.0162016681, 0.0570907855, -0.00462343121, 
		0.0485051228, 0.276162597, 0.125993277, 0.00873304984, 
		0.0478136896, -0.008676916, 0.0620625976, 0.0770331469, ]








func grand_slam_data_get2(vclip_data: Dictionary, plmic_data: Dictionary) -> Array:
	var input_simis: Array = []

	var ori_vclip_avg: Array = []
	var ori_vclip_max: Array = []
	var ori_vclip_pch: Array = []

	var war_vclip_avg: Array = []
	var war_vclip_max: Array = []
	var war_vclip_pch: Array = []

	var smt_vclip_avg: Array = []
	var smt_vclip_max: Array = []
	var smt_vclip_pch: Array = []

	var ori_plmic_avg: Array = []
	var ori_plmic_max: Array = []
	var ori_plmic_pch: Array = []

	var war_plmic_avg: Array = []
	var war_plmic_max: Array = []
	var war_plmic_pch: Array = []

	var smt_plmic_avg: Array = []
	var smt_plmic_max: Array = []
	var smt_plmic_pch: Array = []

	var bth_white_avg: Array = []
	var bth_white_max: Array = []
	var bth_white_pch: Array = []

	var bth_absdi_avg: Array = []
	var bth_absdi_max: Array = []
	var bth_absdi_pch: Array = []

	ori_vclip_avg = vclip_data.average
	ori_vclip_max = vclip_data.max
	ori_vclip_pch = vclip_data.pitch

	var warp_pair: Dictionary = get_warps(vclip_data, plmic_data)
	war_vclip_avg = warp_pair.warp_vclip_data.average
	war_vclip_max = warp_pair.warp_vclip_data.max
	war_vclip_pch = warp_pair.warp_vclip_data.pitch

	smt_vclip_avg = math.array_smoothing(ori_vclip_avg, 6)
	smt_vclip_max = math.array_smoothing(ori_vclip_max, 6)
	smt_vclip_pch = math.array_smoothing(ori_vclip_pch, 6)

	ori_plmic_avg = plmic_data.average
	ori_plmic_max = plmic_data.max
	ori_plmic_pch = plmic_data.pitch

	war_plmic_avg = warp_pair.warp_plmic_data.average
	war_plmic_max = warp_pair.warp_plmic_data.max
	war_plmic_pch = warp_pair.warp_plmic_data.pitch

	smt_plmic_avg = math.array_smoothing(ori_plmic_avg, 6)
	smt_plmic_max = math.array_smoothing(ori_plmic_max, 6)
	smt_plmic_pch = math.array_smoothing(ori_plmic_pch, 6)

	bth_white_avg = white_array(ori_vclip_avg, ori_plmic_avg)
	bth_white_max = white_array(ori_vclip_max, ori_plmic_max)
	bth_white_pch = white_array(ori_vclip_pch, ori_plmic_pch)

	bth_absdi_avg = abs_difference(ori_vclip_avg, ori_plmic_avg)
	bth_absdi_max = abs_difference(ori_vclip_max, ori_plmic_max)
	bth_absdi_pch = abs_difference(ori_vclip_pch, ori_plmic_pch)

	input_simis.append(log(max(1, ori_vclip_avg.size())))
	var pchd: Array = power_couple_half_divy(ori_vclip_avg, ori_plmic_avg)
	input_simis.append(pchd[0])
	input_simis.append(pchd[1])
	var white_sum: float = math.array_sum(bth_white_avg)
	var vclip_sum: float = math.array_sum(ori_vclip_avg)
	var plmic_sum: float = math.array_sum(ori_plmic_avg)
	input_simis.append(vclip_sum / plmic_sum)
	input_simis.append(white_sum / vclip_sum)
	input_simis.append(white_sum / plmic_sum)

	input_simis.append(math.array_mean(bth_absdi_avg))
	input_simis.append(math.st_dev(bth_absdi_avg))
	input_simis.append(bth_absdi_avg.max())
	input_simis.append(math.array_mean(bth_absdi_max))
	input_simis.append(math.st_dev(bth_absdi_max))
	input_simis.append(bth_absdi_max.max())


	var iterate: Array = [
		[ori_vclip_avg, ori_plmic_avg], 
		[ori_vclip_max, ori_plmic_max], 
		[ori_vclip_pch, ori_plmic_pch], 

		[smt_vclip_avg, smt_plmic_avg], 
		[smt_vclip_max, smt_plmic_max], 
		[smt_vclip_pch, smt_plmic_pch], 






















		]

	for waveset in iterate:
		var wave0mean: float = math.array_mean(waveset[0])
		var wave0stdv: float = math.st_dev(waveset[0])
		var wave0max: float = waveset[0].max()

		input_simis.append(wave0mean)
		input_simis.append(wave0mean - math.array_mean(waveset[1]))
		input_simis.append(wave0stdv)
		input_simis.append(wave0stdv - math.st_dev(waveset[1]))
		input_simis.append(wave0max)
		input_simis.append(wave0max - waveset[1].max())



	input_simis.append_array(simis(ori_vclip_avg, ori_plmic_avg))
	input_simis.append_array(simis(ori_vclip_max, ori_plmic_max))
	input_simis.append_array(simis(ori_vclip_pch, ori_plmic_pch))

	input_simis.append_array(simis(ori_vclip_avg, smt_vclip_avg))
	input_simis.append_array(simis(ori_vclip_max, smt_vclip_max))
	input_simis.append_array(simis(ori_vclip_pch, smt_vclip_pch))





	input_simis.append_array(simis(war_vclip_avg, war_plmic_avg))
	input_simis.append_array(simis(war_vclip_max, war_plmic_max))
	input_simis.append_array(simis(war_vclip_pch, war_plmic_pch))

	input_simis.append_array(simis(smt_vclip_avg, smt_plmic_avg))
	input_simis.append_array(simis(smt_vclip_max, smt_plmic_max))
	input_simis.append_array(simis(smt_vclip_pch, smt_plmic_pch))
	return input_simis


func linear_regression_model_FT2(simis_: Array) -> float:
	var score: float = MODEL_FT_INTERCEPT2
	for i in range(MODEL_FT_COEF2.size()):
		score += MODEL_FT_COEF2[i] * simis_[i]
	return score

const MODEL_FT_INTERCEPT2: float = -62.09410150798755
const MODEL_FT_COEF2: Array = [
	0.798673, 1.781916, 2.194961, -0.277839, 11.452499, 8.622742, 
	-0.005349, 0.095933, -0.006216, -0.072565, -0.087269, -0.00876, 
	-1.150739, 0.605684, -0.637243, 0.084189, 0.116111, -0.034485, 
	0.449671, -0.20989, 0.426267, -0.046567, -0.007546, -0.01817, 
	0.002755, -0.066932, -0.631527, 0.03717, 0.035192, -0.01703, 
	1.30175, -0.625912, 0.36444, 0.016948, -0.141742, 0.024985, 
	-0.432864, 0.211812, -0.383365, -0.029986, -0.023866, 0.032425, 
	0.073326, 0.035738, 0.757926, -0.09311, -0.061997, 0.022124, 
	-13.521667, -2.160453, -34.536806, 12.770888, 15.516445, -0.146528, 
	3.007844, 68.881905, 91.212473, 27.628185, -115.550348, -5.713904, 
	3.864385, -31.688059, -1.322773, -30.700105, 13.251835, -1.422145, 
	17.863439, -180.347017, -11.070587, -21.074472, 114.29459, -7.050328, 
	-0.60707, 361.074586, -21.528242, -56.534911, -153.183841, -3.239036, 
	-9.208166, -33.518305, -19.754484, 83.009517, 39.006946, -7.261303, 
	-6.332966, 78.406298, -8.557857, -13.951762, -7.244664, -3.796628, 
	0.316467, -43.464988, -68.664125, 15.4206, 40.648622, 11.720256, 
	4.483561, 1.646715, -26.400799, -10.949953, 12.285133, 6.579955, 
	8.972439, -21.990638, 2.934527, -1.293368, 0.646101, 3.701066, 
	-0.971491, -49.421688, -30.952059, -89.621509, 56.358478, 0.009685, 
	-1.800819, 51.865625, 28.595584, 45.200298, -36.183706, 0.136413, 
]
