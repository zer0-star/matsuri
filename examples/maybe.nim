import matsuri

import sugar

variant Maybe:
  Just(x: int)
  Nothing()

proc fmap(f: int -> int): Maybe -> Maybe =
  return proc (m: Maybe): Maybe =
    match m:
    of Just(x):
      return Just(f(x))
    of Nothing():
      return Nothing()

proc `>>=`(m: Maybe; f: int -> Maybe): Maybe =
  match m:
  of Just(x):
    return f(x)
  of Nothing():
    return Nothing()

echo fmap(x => x+10)(Just(1))
echo fmap(x => x+10)(Nothing())

echo Just(1) >>= (x => Just(x+10))
echo Nothing() >>= (x => Just(x+10))
