class_name LakeProfile
extends Resource
## Visual settings only: no weather progression or fishing depth control.

@export_range(1.0, 150.0, 1.0, "or_greater") var displayed_depth_m: float = 15.0
@export_range(0.35, 0.40) var surface_ratio: float = 0.38
@export var sky_top: Color = Color("86bfd5")
@export var sky_bottom: Color = Color("e0eee0")
@export var mountain_far: Color = Color("aac6c4")
@export var mountain_middle: Color = Color("829fa1")
@export var mountain_near: Color = Color("577f7b")
@export var surface_color: Color = Color("79b6b7")
@export var water_upper: Color = Color("4d989b")
@export var water_middle: Color = Color("306879")
@export var water_deep: Color = Color("1c4057")
