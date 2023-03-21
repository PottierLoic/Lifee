import gg
import gx
import rand
import math
import time

// Windows size
const width = 800
const height = 800

// Amounts used to construct simlation
const cell_amount = 100

//  spawn of cells
const spawn_radius = 100

const cell_color = gx.white
const trace_color = gx.white
const bg_color = gx.black

const trace_spawn_delay = 40
const trace_duration = 1000

const cell_size = 10
const trace_size = 1

struct Cell {
	mut:
		x f64
		y f64
		direction f64
		last_spawn time.StopWatch
}

fn (mut cell Cell) update () {
	cell.x += math.cos(cell.direction*math.pi)
	cell.y += math.sin(cell.direction*math.pi)

	if cell.x < 0 { cell.x = 0.0 
				   cell.direction=rand.f64n(2) or { 0 } }
	if cell.x > width { cell.x = width
							  cell.direction=rand.f64n(2) or { 0 } }
	if cell.y < 0 { cell.y = 0.0
				   cell.direction=rand.f64n(2) or { 0 } }
	if cell.y > height { cell.y = height
							   cell.direction=rand.f64n(2) or { 0 } }
}

fn new_cell() Cell {
	return Cell{x : math.cos(rand.f64n(2) or { 0 })*spawn_radius + width/2
			   y : math.sin(rand.f64n(2) or { 0 })*spawn_radius + height/2
			   direction : rand.f64n(2) or { 0 }
			   last_spawn: time.new_stopwatch()}
}

struct Trace {
	mut:
		x f64
		y f64
		spawn_time time.StopWatch
}

fn new_trace(pos_x f64, pos_y f64) Trace {
	return Trace {x: pos_x
				  y: pos_y
				  spawn_time: time.new_stopwatch()}
}

struct Sim {
	mut:
		cells []Cell
		traces []Trace
}

fn (mut sim Sim) update() {
	for mut cell in sim.cells {
		cell.update()
		if cell.last_spawn.elapsed().milliseconds() > trace_spawn_delay {
			sim.traces << new_trace(cell.x, cell.y)
			cell.last_spawn.restart()
		}
	}
	for i in 0..sim.traces.len {
		if sim.traces[i].spawn_time.elapsed().milliseconds() > trace_duration {
			sim.traces.delete(i)
		}
	}
}

fn new_sim() Sim {
	mut cell_list := []Cell{}
	for _ in 0 .. cell_amount { cell_list << new_cell() }

	return Sim {
		cells: cell_list
		traces: []Trace{}
	}
}

struct App {
	mut:
		gg &gg.Context = unsafe { nil }
		iidx int
		pixels &u32 = unsafe { vcalloc(width * height * sizeof(u32)) }
		sim Sim
}

fn (mut app App) display_sim() {
	for index in 0 .. width * height { app.pixels[index] = u32(bg_color.abgr8()) }
	
	for cell in app.sim.cells {
		for i in int(-cell_size/2) .. int(cell_size/2) {
			for j in int(-cell_size/2) .. int(cell_size/2) {
				app.pixels[int(cell.x + j) + i + (int(cell.y + i) + j) * width] = u32(cell_color.abgr8())
			}
		}
		app.pixels[int(cell.x) + int(cell.y) * width] = u32(cell_color.abgr8())
	}
	for trace in app.sim.traces {
		app.pixels[int(trace.x) + int(trace.y) * width] = u32(trace_color.abgr8())
	}
	mut istream_image := app.gg.get_cached_image_by_idx(app.iidx)
	istream_image.update_pixel_data(app.pixels)
	size := gg.window_size()
	app.gg.draw_image(0, 0, size.width, size.height, istream_image)
}

fn graphics_init(mut app App) {
	app.iidx = app.gg.new_streaming_image(width, height, 4, pixel_format: .rgba8)
}

fn frame(mut app App) {
	app.gg.begin()
	app.sim.update()
	app.display_sim()
	app.gg.end()
}

fn main() {
	mut app := App {
		gg: 0
		sim: new_sim()
	}
	app.gg = gg.new_context(
		bg_color: bg_color
		frame_fn: frame
		init_fn: graphics_init
		user_data: &app
		width: width
		height: height
		create_window: true
		window_title: 'Slime simulation'
	)
	app.gg.run()
}