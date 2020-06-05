import matsuri

variantRefp Tree[T]:
  Leaf(x: T)
  Node(left: Tree[T], right: Tree[T])
