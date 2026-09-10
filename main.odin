package main

import "core:fmt"
import sdl "vendor:sdl3"

GameState :: struct {
  window_width: i32,
  window_height: i32,
  padding: i32,
  is_paused: bool,
  is_running: bool,
  mouse_x: f32,
  mouse_y: f32,
  mouse_event: string,
  debug_x: f32,
  debug_y: f32,
}

main :: proc() {
  game_state := GameState{
    window_width = 600,
    window_height = 400,
    padding = 10,
    is_paused = false, 
    is_running = true,
    mouse_event = "no mouse event yet",
    debug_x = 0,
    debug_y = 0,
  }
  game_state.debug_x = f32(game_state.padding)
  game_state.debug_y = f32(game_state.window_height-(2*game_state.padding))

  if ok := sdl.Init({.VIDEO}); !ok {
    fmt.println("failed to init sdl: ", sdl.GetError())
    return
  }

  window: ^sdl.Window
  renderer: ^sdl.Renderer
  if ok := sdl.CreateWindowAndRenderer("conway", game_state.window_width, game_state.window_height, {.ALWAYS_ON_TOP}, &window, &renderer); !ok {
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

    sdl.SetRenderDrawColor(renderer, 55, 65, 81, 255)
    line_y := game_state.debug_y - f32(game_state.padding)
    _ = sdl.RenderLine(renderer, 0, line_y, f32(game_state.window_width), line_y)

    sdl.SetRenderDrawColor(renderer, 209, 213, 219, 255)
    text := fmt.ctprintf("%s  x=%.1f y=%.1f", game_state.mouse_event, game_state.mouse_x, game_state.mouse_y)
    sdl.RenderDebugText(renderer, game_state.debug_x, game_state.debug_y, text)

    sdl.RenderPresent(renderer)
  }
}
