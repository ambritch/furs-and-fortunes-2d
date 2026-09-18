extends ProgressBar

@onready var progress_bar: ProgressBar = $"."
@export_file("*.tscn") var next_scene_path: String = "res://scenes/main.tscn"

var progress: Array = []

func _ready() -> void:
	# Request Godot to start loading the scene in the background
	ResourceLoader.load_threaded_request(next_scene_path)

func _process(_delta: float) -> void:
	# Query the current loading status and pass 'progress' array to store percentage
	var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				progress_bar.value = progress[0] * 100
				
		ResourceLoader.THREAD_LOAD_LOADED:
			progress_bar.value = 100
			set_process(false) # Stop processing once loaded
			
			var packed_scene = ResourceLoader.load_threaded_get(next_scene_path)
			get_tree().change_scene_to_packed(packed_scene)
			
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + next_scene_path)
			set_process(false)
