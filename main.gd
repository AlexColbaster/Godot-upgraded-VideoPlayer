extends Control


var stdout = []
var duration
var video
func _ready():
	# загрузка видео
	video = VideoStreamWebm.new()
	video.set_file('normal.webm')
	$videoplayer.stream = video
	# расчёт длины видео в секундах
	OS.execute("ffprobe", ['-i', 'normal.webm', 
	'-show_entries', 'format=duration', '-v', 'quiet', '-of', 'csv="p=0"'], true, stdout)
	duration = int(stdout[0])

func _on_pause_pressed():
	$videoplayer.paused = !$videoplayer.paused
	if $videoplayer.paused: $animations.play("pause")
	else: $animations.play_backwards("pause")

# движение окна
var mouse_offset
func _on_move_button_down():
	mouse_offset = get_local_mouse_position()

func _process(delta):
	# движение окна
	if $move.pressed and mouse_offset: OS.window_position += get_local_mouse_position() - mouse_offset
	# движение линии видео со временем
	if duration and not Input.is_action_pressed("mouse"):
		$videoplayer/panel/line.value = start_value + $videoplayer.stream_position / duration

func _on_close_pressed():
	get_tree().quit()

func _on_minimize_pressed():
	OS.window_minimized = true

var value
var seconds
var time_start_hour
var time_start_min
var time_start_secs
var start_value = 0
func _on_line_gui_input(event):
	if event is InputEventMouseButton and duration:
		# запомним новое состояние (пригодится потом)
		value = $videoplayer/panel/line.value
		start_value = value
		# получим весь таймкод в секундах
		seconds = int(value * duration)
		# отделим от секунд минуты
		time_start_hour = int(seconds / 3600)
		seconds -= time_start_hour * 3600
		# отделим от секунд часы
		time_start_min = int(seconds / 60)
		seconds -= time_start_min * 60
		time_start_secs = seconds
		rewind(str(time_start_hour), str(time_start_min), str(time_start_secs))

func rewind(time_start_hour, time_start_min, time_start_secs):
	OS.execute("ffmpeg", ['-ss', time_start_hour+':'+time_start_min+':'+time_start_secs, 
	'-to', '999:0:0', '-i', 'normal.webm', '-c', 'copy', 'cutted.webm', '-y'], true, stdout)
	video = VideoStreamWebm.new()
	video.set_file('cutted.webm')
	$videoplayer.stream = video
	$videoplayer.play()



