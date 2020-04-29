import macros
export macros

proc matchWrapper(e, o: NimNode): NimNode {.compileTime.} =
  if o.kind == nnkIdent:
    return quote do:
      (let `o` = `e`; true)
  else:
    return quote do:
      customMatcher(`e`, `o`)

macro match*(e: typed; stmts: varargs[untyped]): untyped =
  let sym = genSym(nskLet)
  result = nnkStmtList.newTree
  result.add quote do:
    let `sym` = `e`
  var ifStmt = nnkIfStmt.newTree()
  for st in stmts:
    st.expectKind(nnkOfBranch)
    let
      o = st[0]
    var tmp = nnkElifBranch.newTree()
    if o.kind == nnkInfix and o[0].strVal == "and":
      let
        body = o[1]
        cond = o[2]
      tmp.add nnkInfix.newTree(
        ident"and",
        matchWrapper(sym, body),
        cond
      )
    else:
      tmp.add matchWrapper(sym, o)
    tmp.add st[1]
    ifStmt.add tmp
  result.add ifStmt

macro customMatcher*(e: SomeNumber|string|char|bool; o: untyped): untyped =
  return quote do: `e` == `o`

macro customMatcher*(e: tuple; o: untyped): untyped =
  o.expectKind(nnkPar)
  o.expectLen(e.getTypeInst.len)
  result = newLit true
  for i, t in o:
    result = nnkInfix.newTree(
      ident"and",
      result,
      matchWrapper(nnkBracketExpr.newTree(e, newLit i), t)
    )

# ========================================================================

proc generateConstructor(fs: seq[NimNode]; typename,
    enumName: NimNode): NimNode {.compileTime.} =
  var
    obj = nnkObjConstr.newTree(typename)
    param = nnkFormalParams.newTree(typename)
    kindName = fs[0]
  obj.add nnkExprColonExpr.newTree(
    ident"kind",
    quote do: `enumName`.`kindName`
  )
  for i in 1 ..< fs.len:
    obj.add nnkExprColonExpr.newTree(
      fs[i][0],
      fs[i][0]
    )
    param.add nnkIdentDefs.newTree(
      fs[i][0],
      fs[i][1],
      newEmptyNode()
    )
  return nnkProcDef.newTree(
    kindName,
    newEmptyNode(),
    newEmptyNode(),
    param,
    newEmptyNode(),
    newEmptyNode(),
    nnkStmtList.newTree(obj)
  )

proc generateFunctions(typename, enumName: NimNode; xs: seq[seq[
    NimNode]]): NimNode {.compileTime.} =
  let
    dollar = nnkAccQuoted.newTree(ident"$")
    equal = nnkAccQuoted.newTree(ident"==")
    lhs = ident"lhs"
    rhs = ident"rhs"
  var
    cas = nnkCaseStmt.newTree(quote do: `lhs`.kind)
  for fs in xs:
    let kindName = fs[0]
    var m = newLit true
    for i in 1 ..< fs.len:
      let f = fs[i][0]
      m = quote do: `m` and `lhs`.`f` == `rhs`.`f`
    cas.add nnkOfBranch.newTree(
      quote do: `enumName`.`kindName`,
      quote do: return `m`
    )
  return quote do:
    proc `dollar`*(val: `typename`): string =
      for x, y in val.fieldPairs:
        when x == "kind":
          result = $y & "("
        else:
          result &= x & ": " & $y & ", "
      if result[^1] == ' ':
        result[^2..^1] = ")"
      else:
        result.add ')'
    proc `equal`*(`lhs`, `rhs`: `typename`): bool =
      if `lhs`.kind == `rhs`.kind:
        `cas`
      else:
        return false

proc generateMatcher(xs: seq[seq[NimNode]]; typename,
    enumName: NimNode): NimNode {.compileTime.} =
  let
    left = genSym(nskParam, "left")
    right = genSym(nskParam, "right")
  var
    matchBody = nnkStmtList.newTree()
  for fs in xs:
    proc accq(x: NimNode): NimNode =
      nnkAccQuoted.newTree(x)
    let
      kindName = fs[0]
      kindNameLit = newLit(kindName.strVal)
      qleft = accq(left)
    var ifBody = nnkStmtList.newTree()
    ifBody.add quote do:
      result = (quote do: `qleft`.kind == `enumName`.`kindName`)
    for i in 1 ..< fs.len:
      let
        index = newLit(i)
        n = fs[i][0]
      ifBody.add quote do:
        result = nnkInfix.newTree(ident"and", result, matchWrapper(
            quote do: `qleft`.`n`, `right`[`index`]))
    # ifBody.add quote do:
    #   return `m`
    matchBody.add quote do:
      if `right`[0].strVal == `kindNameLit`:
        `ifBody`
  # matchBody.add quote do:
  #   echo result.repr
  return nnkMacroDef.newTree(
    ident"customMatcher",
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      ident"untyped",
      nnkIdentDefs.newTree(
        left,
        typename,
        newEmptyNode()
    ),
    nnkIdentDefs.newTree(
      right,
      ident"untyped",
      newEmptyNode()
    )
  ),
    newEmptyNode(),
    newEmptyNode(),
    matchBody
  )


macro variant*(typename, body: untyped): untyped =
  typename.expectKind(nnkIdent)
  body.expectKind(nnkStmtList)
  let
    enumName = ident(typename.strVal & "Kind")
  var
    kinds: seq[NimNode]
    field = nnkRecCase.newTree()
    xs: seq[seq[NimNode]]
  field.add nnkIdentDefs.newTree(
    ident"kind",
    enumName,
    newEmptyNode()
  )
  for k in body:
    var fs: seq[NimNode]
    case k.kind
    of nnkObjConstr:
      let kindName = k[0]
      fs.add kindName
      kinds.add kindName
      var
        brnc = nnkOfBranch.newTree quote do: `enumName`.`kindName`
        rec = nnkRecList.newTree()
      for i in 1 ..< k.len:
        let
          f = k[i]
        fs.add f
        f.expectKind(nnkExprColonExpr)
        rec.add nnkIdentDefs.newTree(
          f[0],
          f[1],
          newEmptyNode()
        )
      brnc.add rec
      field.add brnc
    of nnkIdent, nnkCall:
      if k.kind == nnkCall:
        k.expectLen(1)
      let k = if k.kind == nnkCall: k[0] else: k
      fs.add k
      kinds.add k
      field.add nnkOfBranch.newTree(
        quote do: `enumName`.`k`,
        nnkRecList.newTree(newNilLit())
      )
    else:
      raise newException(ValueError, "Unexpected kind of variant body")
    xs.add fs
  result = nnkStmtList.newTree()
  result.add newEnum(enumName, kinds, false, true)
  result.add nnkTypeSection.newTree nnkTypeDef.newTree(
    typename,
    newEmptyNode(),
    nnkObjectTy.newTree(
      newEmptyNode(),
      newEmptyNode(),
      nnkRecList.newTree(field)
    )
  )
  for fs in xs:
    result.add generateConstructor(fs, typename, enumName)
  result.add generateFunctions(typename, enumName, xs)
  result.add generateMatcher(xs, typename, enumName)
  # echo result.repr
