package main

import "core:fmt"
import sdl "vendor:sdl3"

width : i32 : 600
height : i32 : 400
padding : i32 : 10

main :: proc() {
  if ok := sdl.Init({.VIDEO}); !ok {
    fmt.println("failed to init sdl: ", sdl.GetError())
    return
  }

  window: ^sdl.Window
  renderer: ^sdl.Renderer
  if ok := sdl.CreateWindowAndRenderer("conway", width, height, {.ALWAYS_ON_TOP}, &window, &renderer); !ok {
    fmt.println("failed to create window & renderer: ", sdl.GetError())
    return
  }

  defer {
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
  }

  mouse_x, mouse_y: f32
  mouse_event: string = "no mouse event yet"
  running := true
  l_x1, l_x2, l_y1, l_y2: f32
  l_x1, l_y1, l_x2, l_y2 = 0, f32(height-(3*padding)), f32(width), f32(height-(3*padding))
  debug_x := f32(padding)
  debug_y := f32(height-(2*padding))
  for running {
    event: sdl.Event
    for sdl.PollEvent(&event) {
      #partial switch event.type {
      case .QUIT:
        running = false
      case .MOUSE_MOTION:
        mouse_x = event.motion.x
        mouse_y = event.motion.y
        mouse_event = "MOUSE_MOTION"
      case .MOUSE_BUTTON_DOWN:
        mouse_x = event.button.x
        mouse_y = event.button.y
        mouse_event = "MOUSE_BUTTON_DOWN"
      case .MOUSE_BUTTON_UP:
        mouse_x = event.button.x
        mouse_y = event.button.y
        mouse_event = "MOUSE_BUTTON_UP"
      }
    }

    if ok := sdl.SetRenderDrawColor(renderer, 30, 34, 39, 255); !ok {
      fmt.println("failed to set render draw color: ", sdl.GetError())
      return
    }
    sdl.RenderClear(renderer)

    sdl.SetRenderDrawColor(renderer, 55, 65, 81, 255)
    _ = sdl.RenderLine(renderer, l_x1, l_y1, l_x2, l_y2)

    sdl.SetRenderDrawColor(renderer, 209, 213, 219, 255)
    text := fmt.ctprintf("%s  x=%.1f y=%.1f", mouse_event, mouse_x, mouse_y)
    sdl.RenderDebugText(renderer, debug_x, debug_y, text)

    sdl.RenderPresent(renderer)
  }
}
