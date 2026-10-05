class_name DepthBands
extends RefCounted
## Fixed lake top, a bounded underwater window, and data-driven depth-valid pools.
const STARTS := [0.0, 15.0, 30.0]
const ENDS := [15.0, 30.0, 50.0]
const MAX_PLAYABLE_DEPTH := 50.0

static func available(band: int, line_depth: float) -> bool:
	return band >= 0 and band < STARTS.size() and line_depth > STARTS[band]

static func pool(band: int, line_depth: float) -> Array[FishFightProfile]:
	var result: Array[FishFightProfile] = []
	if not available(band, line_depth):
		return result
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		if fish.max_depth > STARTS[band] and fish.min_depth < minf(ENDS[band], line_depth):
			for weight in range(maxi(1, 6 - fish.rarity)):
				result.append(fish)
	return result

static func seek_depth(band: int, cast_number: int, line_depth: float) -> float:
	if band == 0:
		return 0
	var choices: Array = [20.0, 25.0, 28.0] if band == 1 else [35.0, 40.0, 50.0]
	return minf(choices[posmod(cast_number - 1, choices.size())], line_depth)
