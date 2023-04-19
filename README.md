# A* Pathfinding Visualizer in zig

> First time writting zig and I have no clue about what I'm doing.

> Error handling is almost non-existent, the program crashes alot.

## Build and Run

``` sh
zig build run
```

Dependencies:
* SDL2

## Keybindings

| Key                         | Action                         |
|-----------------------------|--------------------------------|
| `Left Mouse Button`         | Add Wall node                  |
| `Right Mouse Button`        | Remove what's under the cursor |
| `Ctrl + Left Mouse Button`  | Add Start node                 |
| `Ctrl + Right Mouse Button` | Add Goal node                  |
| `A`                         | Start pathfinder               |
| `Esc`                       | Stop pathfinder                |
| `C`                         | Clear map                      |
| `S`                         | Export map to `map.json`       |
| `L`                         | Load map from `map.json`       |
| `Q`                         | Quit program                   |

## Customization

### Colors

`colors.json` is loaded at start.

## TODO

* [ ] More Algorithms
  * [ ] Dijkstra
  * [ ] DFS
  * [ ] BFS
* [-] UI
  * [ ] Delay slider
  * [ ] Save/Load file picker
  * [ ] Zoom
  * [X] Custom colors
* [ ] General
  * [ ] Generate maze
  * [ ] Better error handling
  * [ ] Dynamic map size

## License

MIT 
