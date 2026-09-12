package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

GameState :: struct {
	window_w:     f32,
	window_h:     f32,
	padding:      f32,
	is_paused:    bool,
	is_running:   bool,
	grid:         [dynamic][dynamic]bool,
	grid_rows:    u32,
	grid_cols:    u32,
	grid_row:     [dynamic]sdl.FRect,
	cell_d:       f32,
	cell_padding: f32,
	mouse_x:      f32,
	mouse_y:      f32,
	mouse_event:  string,
	debug_x:      f32,
	debug_y:      f32,
}

main :: proc() {
	game_state := GameState {
		window_w     = 600,
		window_h     = 400,
		padding      = 10,
		is_paused    = false,
		is_running   = true,
		grid         = nil,
		cell_d       = 20,
		cell_padding = 5,
		mouse_event  = "no mouse event yet",
		debug_x      = 0,
		debug_y      = 0,
	}

	// Note: once resize is handled turn this into a function
	// make cell_d a factor of the window size, same for padding
	// cell padding can be a factor of cell size maybe
	game_state.debug_x = game_state.padding
	game_state.debug_y = game_state.window_h - (2 * game_state.padding)
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


	if ok := sdl.Init({.VIDEO}); !ok {
		fmt.println("failed to init sdl: ", sdl.GetError())
		return
	}

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

	for game_state.is_running {
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

			if i %% 2 == 0 {
				sdl.SetRenderDrawColor(renderer, 206, 17, 38, 100)
				_ = sdl.RenderFillRect(renderer, &game_state.grid_row[i])
			}
		}

		// debug section
		sdl.SetRenderDrawColor(renderer, 55, 65, 81, 255)
		line_y := game_state.debug_y - f32(game_state.padding)
		_ = sdl.RenderLine(renderer, 0, line_y, f32(game_state.window_w), line_y)

		sdl.SetRenderDrawColor(renderer, 209, 213, 219, 255)
		text := fmt.ctprintf(
			"%s  x=%.1f y=%.1f",
			game_state.mouse_event,
			game_state.mouse_x,
			game_state.mouse_y,
		)
		sdl.RenderDebugText(renderer, game_state.debug_x, game_state.debug_y, text)

		sdl.RenderPresent(renderer)
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
