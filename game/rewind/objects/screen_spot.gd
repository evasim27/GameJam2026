class_name ScreenSpot
extends GlitchSpot
## The boss's second window, on the CRT: it only tears while the TV shows its empty frame
## and the static wave rolls through at the same moment. See TapeEater.

var eater: TapeEater


func window_open(run: RoomRun) -> bool:
	return eater.empty_frame(run) and eater.static_wave(run)


## The wave is timed from the jam, so it can't be marked on the timeline in advance.
func timeline_marks(_length: float) -> Array:
	return []
