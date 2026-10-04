extends Panel
## Always processes so the short reward also animates during the shop pause.
var remaining: float = 0.0

func show_unlock(previous: float, next: float) -> void:
	$Label.text = "DEPTH UNLOCKED\n%dm → %dm" % [int(previous), int(next)]
	remaining = 1.2
	visible = true

func show_upgrade(category: String, level: int) -> void:
	$Label.text = "UPGRADE!\n%s Lv.%d" % [category.to_upper(), level]
	remaining = 0.8
	visible = true

func _process(delta: float) -> void:
	if not visible:
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.0:
		visible = false
