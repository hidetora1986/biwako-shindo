class_name BossPixelArt
extends RefCounted
## No.15 presentation only. Offline raster art; original frame geometry, timing and gameplay remain unchanged.
const FRAMES: Array[Texture2D] = [
	preload("res://assets/visual/boss/no15/frame-0.tres"),
	preload("res://assets/visual/boss/no15/frame-1.tres"),
	preload("res://assets/visual/boss/no15/frame-2.tres"),
]

static func texture(phase: int) -> Texture2D:
	return FRAMES[posmod(phase,3)]
