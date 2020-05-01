import matsuri

import unittest

variant A[T, U]:
  One(x: T, y: U)
  Two(a: int)
  Three()

test "stringify":
  check $One(10, 4.1) == "One(x: 10, y: 4.1)"
  check $One("abc", false) == "One(x: abc, y: false)"
  check $Two[int, int](1) == "Two(a: 1)"
  check $Three[int, int]() == "Three()"

test "type check":
  check (One(19, "a") is A[int, string])
  check (One('u', @[0.0, 1.0]) is A[char, seq[float]])
  check (Two[(int, int), string](39) is A[(int, int), string])
  check (Three[void, set[uint8]]() is A[void, set[uint8]])

test "equality":
  check One(2, 2.2) == One(2, 2.2)
  check One(1, "a") != One(1, "b")
  check Two[int, int](10) == Two[int, int](10)
  check Two[int, int](10) != Two[int, int](1)
  check Three[int, int]() == Three[int, int]()
  check One("a", false) != Two[string, bool](1)
  check not compiles(One(false, "a") == One(1, 2.0))
  check not compiles(One(false, "a") == Two[int, int](1))
  check not compiles(Three[int, int]() == Three[int, float]())

test "matching":
  match One(1, "abc"):
  of One(x, y):
    check x == 1 and y == "abc"
  of _:
    check false
  match One(false, @[3]):
  of One(x, y):
    check x == false and y == @[3]
  of _:
    check false
  match Two[bool, string](0):
  of Two(a):
    check a == 0
  of _:
    check false
  match Three[int, int]():
  of Three():
    check true
  of _:
    check false
