import matsuri

import sugar

variant Maybe[T]:
  Just(x: T)
  Nothing()

proc fmap[T, U](f: T -> U): Maybe[T] -> Maybe[U] =
  return proc (m: Maybe[T]): Maybe[U] =
    match m:
    of Just(x):
      return Just(f(x))
    of Nothing():
      return Nothing[U]()

proc `>>=`[T, U](m: Maybe[T]; f: T -> Maybe[U]): Maybe[U] =
  match m:
  of Just(x):
    return f(x)
  of Nothing():
    return Nothing[U]()

echo fmap((x: int) => x+10)(Just(1))
echo fmap((x: int) => x+10)(Nothing[int]())

echo Just(1) >>= ((x: int) => Just(x+10))
echo Nothing[int]() >>= ((x: int) => Just(x+10))

echo fmap((x: int) => $x & "a")(Just(1))
echo fmap((x: int) => $x & "a")(Nothing[int]())

echo Just(1) >>= ((x: int) => Just($x & "a"))
echo Nothing[int]() >>= ((x: int) => Just($x & "a"))
