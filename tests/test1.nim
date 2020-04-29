import unittest
import math

import matsuri

suite "match macro":
  test "literal match":
    proc f(x: int): string =
      match x:
      of 1: return "one\n"
      of 2: return "two\n"
      of _: return "otherwise\n"
    var tmp = ""
    tmp &= f(0)
    tmp &= f(1)
    tmp &= f(2)
    tmp &= f(3)
    check tmp == """
otherwise
one
two
otherwise
"""
  test "match with guard":
    proc f(x: float): string =
      match x:
      of a and a == PI: return "pi\n"
      of a and a == floor(a): return "integer\n"
      of 1.23: return "one-point-two-three\n"
      of _: return "otherwise\n"
    var tmp = ""
    tmp &= f(0.1)
    tmp &= f(1.23)
    tmp &= f(2.0)
    tmp &= f(PI)
    check tmp == """
otherwise
one-point-two-three
integer
pi
"""
  test "match with tuple":
    var tmp = ""
    for i in 1..15:
      match (i mod 3, i mod 5):
      of (0, 0):
        tmp &= "FizzBuzz\n"
      of (0, _):
        tmp &= "Fizz\n"
      of (_, 0):
        tmp &= "Buzz\n"
      of (_, _):
        tmp &= $i & "\n"
    check tmp == """
1
2
Fizz
4
Buzz
Fizz
7
8
Fizz
Buzz
11
Fizz
13
14
FizzBuzz
"""
  test "match with tuple recursively":
    match (1, 2, (3, ((4, 5), 6))):
    of (a, b, (c, (d, e))):
      check a == 1 and b == 2 and c == 3 and d == (4, 5) and e == 6
    of _:
      check false

variant A:
  One(x: int, y: string)
  Two(a: float)
  Three()

suite "variant types":
  test "stringify":
    check $One(1, "abc") == "One(x: 1, y: abc)"
    check $Two(0.01) == "Two(a: 0.01)"
    check $Three() == "Three()"
  test "equality":
    check One(1, "e") == One(1, "e")
    check One(1, "e") != One(1, "a")
    check Two(0.0) != One(1, "a")
    check Three() == Three()
  test "matching":
    match One(1, "abc"):
    of One(x, y):
      check x == 1 and y == "abc"
    of _:
      check false
    match Two(0.01):
    of Two(a):
      check a == 0.01
    of _:
      check false
    match Three():
    of Three():
      check true
    of _:
      check false
