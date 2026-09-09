package main

import "core:fmt"
import sdl "vendor:sdl3"

width : i32 : 600
height : i32 : 400

main :: proc() {
  if i := sdl.Init({});!i {
    fmt.println("failed to init sdl: ", sdl.GetError())
    return
  }

  window: ^sdl.Window
  renderer: ^sdl.Renderer
  if wr := sdl.CreateWindowAndRenderer("conway", width, height, {.ALWAYS_ON_TOP}, &window, &renderer);!wr {
    fmt.println("failed to create window & renderer: ", sdl.GetError())
    return
  }

  if s := sdl.SetRenderDrawColor(renderer, 255, 255, 255, 250);!s {
    fmt.println("failed to set render draw color: ", sdl.GetError())
    return
  }

  sdl.RenderClear(renderer);
  sdl.RenderPresent(renderer);

  running := true
  for running {
    event: sdl.Event
    for sdl.PollEvent(&event) {
      if event.type == .QUIT {
        running = false
      }
    }
    sdl.RenderClear(renderer)
    sdl.RenderPresent(renderer)
  }
  sdl.Delay(2000);

  // Todo: start loop

  defer {
    sdl.DestroyWindow(window)
    sdl.DestroyRenderer(renderer)
  }
}
