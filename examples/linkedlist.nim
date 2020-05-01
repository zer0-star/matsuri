import matsuri

proc `$`[T](x: ref T): string =
  `$`(x[])

variant List[T]:
  Nil
  Cons(x: T, y: ref List[T])

proc `~`[A](a: A): ref A =
  new(result)
  result[] = a

proc toList[T](xs: seq[T]): List[T] =
  if xs.len == 0:
    Nil[T]()
  else:
    Cons(xs[0], ~toList(xs[1..^1]))

proc sum(a: List[int]): int =
  match a:
  of Cons(x, y):
    return x + sum(y[])
  of Nil():
    return 0


let xs = toList(@[3, 1, 4, 1, 5, 9])

echo xs
echo sum(xs)
