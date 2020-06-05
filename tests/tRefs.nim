import matsuri
import sugar
import unittest

variantRef LinkedList[T]:
  Nil
  Cons(x: T, xs: LinkedList[T])

proc toList[T](x: varargs[T]): LinkedList[T] =
  if x.len == 0:
    return Nil[T]()
  else:
    return Cons(x[0], toList(x[1..^1]))

test "stringify":
  check $toList(0, 1, 1, 2, 3) == "Cons(x: 0, xs: Cons(x: 1, xs: Cons(x: 1, xs: Cons(x: 2, xs: Cons(x: 3, xs: Nil())))))"

test "equality":
  check toList(1, 2, 3) == toList(1, 2, 3)
  check toList(1, 2, 2) != toList(1, 2, 3)
  check toList(1, 2, 3) != toList(1, 2)

test "matching":
  proc foldr[T, U](x: LinkedList[T]; init: U; f: (T, U) -> U): U =
    match x:
    of Nil():
      return init
    of Cons(x, xs):
      return f(x, foldr(xs, init, f))

  check foldr(toList(1, 2, 3, 4, 5), 0, (x, y) => x + y) == 15
  check foldr(toList(3, 1, 4, 1, 5, 9, 2), 0, (x, y) => max(x, y)) == 9
  check foldr(toList(1, 2, 3, 1, 2, 3), "", (x, y) => $x & "," & y) == "1,2,3,1,2,3,"
