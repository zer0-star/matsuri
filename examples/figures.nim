import matsuri
import strformat

variant Point:
  Origin
  P(x: float, y: float)

variant Figure:
  Rectangle(w: float, h: float)
  Circle(c: Point, r: float)

proc explain(s: Figure) =
  match s:
  of Rectangle(w, h) and w == h:
    echo "Thsi is a square."
  of Rectangle(_, _):
    echo "This is not a square, but a rectangle."
  of Circle(P(x, y), r):
    echo fmt"This is a circle with the center as ({x}, {y}) and the radius as {r}."
  of Circle(Origin(), r):
    echo fmt"This is a circle with the center as the origin and the radius as {r}."

explain Rectangle(10, 10)
explain Rectangle(10, 12)
explain Circle(P(1, 2), 4)
explain Circle(Origin(), 2)
