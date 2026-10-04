class_name LakeProfile
extends Resource
## Visual settings only: no weather progression or fishing depth control.

@export_range(1.0, 150.0, 1.0, "or_greater") var displayed_depth_m: float = 15.0
@export_range(0.35, 0.40) var surface_ratio: float = 0.38
@export var sky_top: Color = Color("a7d4d5")
@export var sky_bottom: Color = Color("e3e8c3")
@export var mountain_far: Color = Color("7ba5a1")
@export var mountain_near: Color = Color("557f79")
@export var surface_color: Color = Color("76b7aa")
@export var water_upper: Color = Color("377f80")
@export var water_middle: Color = Color("245b68")
@export var water_deep: Color = Color("153b4c")
