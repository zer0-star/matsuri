import matsuri
import tPublic1
import unittest

test "stringify":
  check $Node(Node(Leaf(3), Leaf(1)), Leaf(0)) == "Node(left: Node(left: Leaf(x: 3), right: Leaf(x: 1)), right: Leaf(x: 0))"

test "equality":
  check Node(Leaf(1), Leaf(0)) == Node(Leaf(1), Leaf(0))
  check Node(Leaf(1), Leaf(0)) != Node(Leaf(2), Leaf(0))
  check Node(Leaf(1), Leaf(0)) != Node(Node(Leaf(1), Leaf(0)), Leaf(0))

test "matching":
  proc depth[T](x: Tree[T]): int =
    match x:
    of Leaf(_):
      return 1
    of Node(left, right):
      return max(depth(left), depth(right)) + 1
  check depth(Node(Node(Leaf(3), Leaf(1)), Leaf(0))) == 3
  check depth(Leaf("aiueo")) == 1
