package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:time"
import sdl "vendor:sdl3"

BUTTON_WIDTH: f32 : 60
BUTTON_HEIGHT: f32 : 20
CHAR_WIDTH: f32 : 8
REFRESH_RATE_HZ: f32 : 60

GameState :: struct {
	window_w:             f32,
	window_h:             f32,
	refresh_rate_hz:      f32,
	padding:              f32,
	menu_padding_x:       f32,
	is_sim_running:       bool,
	is_sim_paused:        bool,
	is_running:           bool,
	initial_grid_density: f32,
	grid:                 [dynamic][dynamic]bool,
	grid_rows:            u32,
	grid_cols:            u32,
	grid_row:             [dynamic]sdl.FRect,
	cell_d:               f32,
	cell_padding:         f32,
	mouse_x:              f32,
	mouse_y:              f32,
	mouse_event:          string,
	debug_x:              f32,
	debug_y:              f32,
}

Button :: struct {
	rect:    ^sdl.FRect,
	text:    string,
	text_x:  f32,
	text_y:  f32,
	hovered: bool,
	pressed: bool,
}

main :: proc() {
	game_state := GameState {
		window_w             = 600,
		window_h             = 400,
		refresh_rate_hz      = REFRESH_RATE_HZ,
		padding              = 10,
		menu_padding_x       = 5,
		is_sim_running       = false,
		is_sim_paused        = false,
		is_running           = true,
		initial_grid_density = 0.20,
		grid                 = nil,
		cell_d               = 20,
		cell_padding         = 5,
		mouse_event          = "no mouse event yet",
		debug_x              = 0,
		debug_y              = 0,
	}

	// Note: once resize is handled turn this into a function
	// make cell_d a factor of the window size, same for padding
	// cell padding can be a factor of cell size maybe
	game_state.debug_x = game_state.padding
	game_state.debug_y = game_state.window_h - (2 * game_state.padding)
	// FixMe: when making the cells smaller they overflow onto the debug
	// section
	game_state.grid_rows = u32(
		math.floor_f32(
			(game_state.window_h - (3 * game_state.padding)) /
			(game_state.cell_d + game_state.cell_padding),
		),
	)
	game_state.grid_cols = u32(
		math.floor_f32(
			(game_state.window_w - (2 * game_state.padding)) /
			(game_state.cell_d + game_state.cell_padding),
		),
	)
	game_state.grid_row = make([dynamic]sdl.FRect, int(game_state.grid_cols))

	game_state.grid = make([dynamic][dynamic]bool, game_state.grid_rows)
	for i in 0 ..< game_state.grid_rows {
		game_state.grid[i] = make([dynamic]bool, game_state.grid_cols)
	}

	// bring random living cells to life :)
	for i in 0 ..< game_state.grid_rows {
		for j in 0 ..< game_state.grid_cols {
			game_state.grid[i][j] = rand.float32() < game_state.initial_grid_density
		}
	}

	// menu
	debug_top := game_state.debug_y - game_state.padding
	debug_section_h := game_state.window_h - debug_top

	// Todo: I don't like this (both)
	menu_y := debug_top + (debug_section_h - BUTTON_HEIGHT) / 2
	menu_x := math.floor_f32(game_state.window_w / 2) + (12 * game_state.padding)

	game_menu := [2]Button {
		Button {
			rect = &sdl.FRect{menu_x, menu_y, BUTTON_WIDTH, BUTTON_HEIGHT},
			text = "Reset",
			hovered = false,
			pressed = false,
		},
		Button {
			// FixMe: there is a better way to calculate this
			rect    = &sdl.FRect {
				menu_x + BUTTON_WIDTH + game_state.menu_padding_x,
				menu_y,
				BUTTON_WIDTH,
				BUTTON_HEIGHT,
			},
			text    = "Start",
			hovered = false,
			pressed = false,
		},
	}

	for &item in game_menu {
		text_w := f32(len(item.text)) * CHAR_WIDTH
		item.text_x = item.rect.x + (item.rect.w - text_w) / 2
		item.text_y = item.rect.y + (item.rect.h - CHAR_WIDTH) / 2
	}

	if ok := sdl.Init({.VIDEO}); !ok {
		fmt.println("failed to init sdl: ", sdl.GetError())
		return
	}

	// has to run after init
	display_count: i32 = 0
	displays := sdl.GetDisplays(&display_count)
	fmt.println("display count: ", display_count)
	for d in displays[:display_count] {
		display_mode := sdl.GetCurrentDisplayMode(d)
		if display_mode != nil {
			game_state.refresh_rate_hz = display_mode.refresh_rate
		}
	}
	sdl.free(displays)

	window: ^sdl.Window
	renderer: ^sdl.Renderer
	if ok := sdl.CreateWindowAndRenderer(
		"conway",
		i32(game_state.window_w),
		i32(game_state.window_h),
		{.ALWAYS_ON_TOP},
		&window,
		&renderer,
	); !ok {
		fmt.println("failed to create window & renderer: ", sdl.GetError())
		return
	}

	defer {
		sdl.DestroyRenderer(renderer)
		sdl.DestroyWindow(window)
	}

	frame_budget := time.Duration(f64(time.Second) / f64(game_state.refresh_rate_hz))
	for game_state.is_running {
		frame_start := time.tick_now()

		event: sdl.Event
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				game_state.is_running = false
			case .MOUSE_MOTION:
				game_state.mouse_x = event.motion.x
				game_state.mouse_y = event.motion.y
				game_state.mouse_event = "MOUSE_MOTION"
			case .MOUSE_BUTTON_DOWN:
				game_state.mouse_x = event.button.x
				game_state.mouse_y = event.button.y
				game_state.mouse_event = "MOUSE_BUTTON_DOWN"
			case .MOUSE_BUTTON_UP:
				game_state.mouse_x = event.button.x
				game_state.mouse_y = event.button.y
				game_state.mouse_event = "MOUSE_BUTTON_UP"
			// Todo: handle window resize
			}
		}

		if ok := sdl.SetRenderDrawColor(renderer, 30, 34, 39, 255); !ok {
			fmt.println("failed to set render draw color: ", sdl.GetError())
			return
		}
		sdl.RenderClear(renderer)

		// grid
		for i in 0 ..< game_state.grid_rows {
			sdl.SetRenderDrawColor(renderer, 55, 65, 81, 255)
			gridRow(&game_state, f32(i) * (game_state.cell_d + game_state.cell_padding))
			_ = sdl.RenderRects(
				renderer,
				raw_data(game_state.grid_row),
				i32(len(game_state.grid_row)),
			)

			for j in 0 ..< game_state.grid_cols {
				if game_state.grid[i][j] {
					sdl.SetRenderDrawColor(renderer, 206, 17, 38, 100)
					_ = sdl.RenderFillRect(renderer, &game_state.grid_row[j])
				}
			}
		}

		// debug section
		sdl.SetRenderDrawColor(renderer, 55, 65, 81, 255)
		line_y := game_state.debug_y - f32(game_state.padding)
		_ = sdl.RenderLine(renderer, 0, line_y, f32(game_state.window_w), line_y)

		sdl.SetRenderDrawColor(renderer, 209, 213, 219, 255)
		text := fmt.ctprintf(
			"%s  x=%.1f y=%.1f Refresh Rate=%.1f",
			game_state.mouse_event,
			game_state.mouse_x,
			game_state.mouse_y,
			game_state.refresh_rate_hz,
		)
		sdl.RenderDebugText(renderer, game_state.debug_x, game_state.debug_y, text)

		for item, i in game_menu {
			sdl.RenderRect(renderer, item.rect)
			sdl.RenderDebugText(renderer, item.text_x, item.text_y, fmt.ctprintf("%s", item.text))
		}

		sdl.RenderPresent(renderer)

		elapsed := time.tick_since(frame_start)
		if elapsed < frame_budget {
			time.sleep(frame_budget - elapsed)
		}
	}
}

gridRow :: proc(game_state: ^GameState, y: f32) {
	cell_d := game_state.cell_d
	padding := f32(game_state.padding)
	cell_padding := game_state.cell_padding

	for i in 0 ..< int(game_state.grid_cols) {
		game_state.grid_row[i] = sdl.FRect {
			padding + (f32(i) * (cell_d + cell_padding) + cell_padding),
			y + padding,
			cell_d,
			cell_d,
		}
	}
}
