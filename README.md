**Note:** There are several breaking changes planned for this library in the near future. Keep in mind that an update may require you to rewrite much of the code that uses this library.

# Matsuri: Useful Variant Type and Powerful Pattern Matching

[![CircleCI](https://circleci.com/gh/zer0-star/matsuri.svg?style=shield)](https://circleci.com/gh/zer0-star/matsuri)
[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble_js.png)](https://github.com/yglukhov/nimble-tag)

Matsuri is a library providing variant types and pattern matching inspired by [Patty](https://github.com/andreaferretti/patty).

Matsuri's pattern matching system is unique. The key of this is the macro `customMatcher`.

For example, you can use pattern matching as follows:

```nim
match n: # This colon is NECESSARY!
of 1:
  echo "one"
of 2:
  echo "two"
of _:
  echo "something else"
```

This will be converted to the following code by the `match` macro.

```nim
let :tmp = n
if customMatcher(:tmp, 1):
  echo "one"
elif customMatcher(:tmp, 2):
  echo "two"
elif (let _ = :tmp; true):
  echo "something else"
```

As the argument of the `match` macro, `` `x` `` in `` of `x`: `` is converted to `` (let `x` = :tmp; true) `` if `` `x` `` is an identifier, otherwise `` customMatcher(:tmp, `x`) ``.

Next, the macro `customMatcher` will be expanded depending on `:tmp`'s type. In this case `:tmp` is `int`, so `` customMatcher(:tmp, `x`) `` will be converted to `` :tmp == `x` ``.

```nim
let :tmp = n
if :tmp == 1:
  echo "one"
elif :tmp == 2:
  echo "two"
elif (let _ = :tmp; true):
  echo "something else"
```

The important thing is that you can define your `customMatcher` for each type you want to match. This makes Matsuri's pattern matching very flexible.

When you want to define your `customMatcher`, you can use the compile-time function `matchWrapper` which makes a binding or a `customMatcher` call.

## Variant types

To define variant types, you can use the `variant` macro. It's similar to Patty's, but this one generates a `customMatcher` for the variant type.

```nim
variant Maybe[T]:
  Just(x: T)
  Nothing()
```

This will be converted like:

```nim
type
  MaybeKind {.pure.} = enum
    Just, Nothing
type
  Maybe[T] = object
    case kind: MaybeKind
    of MaybeKind.Just:
      x: T
    of MaybeKind.Nothing:
      discard


proc Just[T](x: T): Maybe =
  result = Maybe[T](kind: MaybeKind.Just, x: x)

proc Nothing[T](): Maybe =
  result = Maybe[T](kind: MaybeKind.Nothing)

proc `$`[T](val: Maybe[T]): string =
  result = $val.kind & "("
  case val.kind
  of MaybeKind.Just:
    result &= ", x: " & $val.x
  of MaybeKind.Nothing:
  if result[^1] == ' ':
    result[^2..^1] = ")"
  else:
    result.add ')'

proc `==`[T](lhs, rhs: Maybe[T]): bool =
  if lhs.kind == rhs.kind:
    case lhs.kind
    of MaybeKind.Just:
      return true and lhs.x == rhs.x
    of MaybeKind.Nothing:
      return true
  else:
    return false

macro customMatcher(left: Maybe; right: untyped): untyped =
  if right[0].strVal == "Just":
    result = quote:
      `left`.kind == MaybeKind.Just
    result = nnkInfix.newTree(
      ident"and",
      result,
      matchWrapper(
        quote: `left`.x,
        right[1]
      )
    )
  if right[0].strVal == "Nothing":
    result = quote:
      `left`.kind == MaybeKind.Nothing
```

The macro `customMatcher` is generated so that you can use the `match` macro with variant types.

```nim
variant Maybe[T]:
  Just(x: T)
  Nothing()

let m = Just(10)

match m:
of Just(x):
  echo fmt"Just {x}"
of Nothing():
  echo "Nothing"
```

You can export a variant type with the `variantp` macro, make it `ref object` type with the `variantRef` macro, or do both with `variantRefp` macro.

## Examples

For more examples, see [examples](https://github.com/zer0-star/matsuri/tree/master/examples).

## Future Work

- Rust-like variant types

```nim
variantRef Tree[T]:
  Leaf(T) # unnamed field
  Node{left: Tree[T], right: Tree[T]} # named field

proc depth[T](t: Tree[T]): int =
  match t:
  of Leaf(_):
    return 1
  of Node{left: left, right: right}:
  # Also can write as:
  #   of Node{left, right}:
    return 1 + max(depth(left), depth(right))
```
