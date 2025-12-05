extends Label

var totalCPU:float
var totalGPU:float
var totalFPS:float
var avgCPU:float
var avgGPU:float
var avgFPS:float
var times_called:float = 0


func _process(delta):
	times_called += 1
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true);
	var CPU_RenderTime = str(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
	var GPU_RenderTime  = str(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
	text = "FRAMES PER SECOND: " + str(Engine.get_frames_per_second()) + "\nFRAME RENDER TIME CPU / GPU: " + CPU_RenderTime.substr(0,5) + " / " + GPU_RenderTime.substr(0,5)
	totalFPS += Engine.get_frames_per_second()
	avgFPS = totalFPS / times_called
	totalCPU += RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid())
	avgCPU = totalCPU / times_called
	totalGPU += RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	avgGPU = totalGPU / times_called
	text = text + "\n\n AVERAGE FPS: " + str(avgFPS) + "\n AVG RENDER TIME CPU / GPU: " + str(avgCPU).substr(0,5) + " / " + str(avgGPU).substr(0,5)
