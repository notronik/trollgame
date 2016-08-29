# Escape the trolls
For /r/dailyprogrammer weekly challenge #25.
Written in Swift 3.0 as of Xcode 8 Beta 4.

Challenge post: <https://www.reddit.com/r/dailyprogrammer/comments/4vrb8n/weekly_25_escape_the_trolls/>.

---

This is my first foray into non-cocoa programming with Swift, and it was a lot of fun. Input and drawing is currently handled with ncurses, but any object can be a renderer and input handler as long as it conforms to the `Renderer` and `InputHandler` protocols.

I may have also gone a bit overboard since I added an entity component system that _kinda_ works. I mean it works, but many of the components still expect a specific execution order so that the correct data is set. One neat thing with this approach is that the player can theoretically be wired up with the same AI component as the trolls and therefore become automated, though it doesn't currently have the ability to avoid entity tiles and therefore often runs into trolls.

I've implemented Phases 1 - 4, Bonus 1, Bonus 6 (kinda) and maybe Bonus 4. I decided against Bonus 5 because the # symbols work better with the blood stain system (walls become blood-stained when used for crushing). Real-time gameplay is something I'd experimented with at the beginning, but it really doesn't work very well from a gameplay perspective, so I abandoned it.

My Bonus 6 implementation is basically a viewport thing. The renderer renders only a small region of the maze, which enables the use of really large mazes. The viewport moves with the player unless the player is close to the sides, in which case it will stick to the edges of the maze.

Some places tell me that the maze backtracking algorithm that I use generates perfect mazes, so maybe I've also implemented Bonus 4.

I didn't feel that Bonus 7 was necessary because I implemented a block pulling mechanic.

## Requirements
It probably only runs on macOS, and you need a terminal that supports custom RGB colours. I use iTerm2.

## Gifs
20 trolls spawn by default in a 101x51 maze with 3x1 cells.
Trolls use A* pathfinding, but don't follow the player if more than 100 positions are checked before the player is found. When they are not following the player they just sort of move around randomly. Trolls follow the same orientation rules as the player, so they must rotate to face the direction they want to move in prior to making that move during the next turn.

![](https://fat.gfycat.com/TediousSafeBrocketdeer.gif)

Of course the trolls kill the player

![](https://fat.gfycat.com/PoliticalImmaculateBobcat.gif)

…unless the player finds the exit before getting killed.

![](https://zippy.gfycat.com/ViciousDeafeningAtlanticsharpnosepuffer.gif)

Crushing with blocks and pulling them around can be very useful.
