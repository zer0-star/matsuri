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

proc generateConstructor(fs: seq[NimNode];
                         typename, enumName: NimNode;
                         isGeneric, isRef, isPublic: bool;
                         genericParams: NimNode
                         ): NimNode {.compileTime.} =
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
    if isPublic: nnkPostfix.newTree(
        ident"*",
        kindName
      ) else: kindName,
    newEmptyNode(),
    if isGeneric: genericParams else: newEmptyNode(),
    param,
    newEmptyNode(),
    newEmptyNode(),
    nnkStmtList.newTree(obj)
  )

proc generateFunctions(typename, enumName: NimNode;
                       xs: seq[seq[NimNode]];
                       isGeneric, isRef, isPublic: bool;
                       genericParams: NimNode
                       ): NimNode {.compileTime.} =
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
  let
    val = if isRef: nnkBracketExpr.newTree(ident"val") else: ident"val"
    dollarBody = quote do:
      for x, y in `val`.fieldPairs:
        when x == "kind":
          result = $y & "("
        else:
          result &= x & ": " & $y & ", "
      if result[^1] == ' ':
        result[^2..^1] = ")"
      else:
        result.add ')'
    equalBody = quote do:
      if `lhs`.kind == `rhs`.kind:
        `cas`
      else:
        return false
  return nnkStmtList.newTree(
    nnkProcDef.newTree(
      if isPublic: nnkPostfix.newTree(
          ident"*",
          dollar
        ) else: dollar,
      newEmptyNode(),
      if isGeneric: genericParams else: newEmptyNode(),
      nnkFormalParams.newTree(
        ident"string",
        nnkIdentDefs.newTree(
          ident"val",
          typename,
          newEmptyNode()
    )
  ),
      newEmptyNode(),
      newEmptyNode(),
      dollarBody
    ),
    nnkProcDef.newTree(
      if isPublic: nnkPostfix.newTree(
          ident"*",
          equal
        ) else: equal,
      newEmptyNode(),
      if isGeneric: genericParams else: newEmptyNode(),
      nnkFormalParams.newTree(
        ident"bool",
        nnkIdentDefs.newTree(
          lhs,
          rhs,
          typename,
          newEmptyNode()
      )
    ),
      newEmptyNode(),
      newEmptyNode(),
      equalBody
    )
  )

proc generateMatcher(xs: seq[seq[NimNode]];
                     enumName: NimNode;
                     typeStr: string;
                     isRef, isPublic: bool
                     ): NimNode {.compileTime.} =
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
    matchBody.add quote do:
      if `right`[0].strVal == `kindNameLit`:
        `ifBody`
  return nnkMacroDef.newTree(
    if isPublic: nnkPostfix.newTree(
      ident"*",
      ident"customMatcher"
    ) else: ident"customMatcher",
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      ident"untyped",
      nnkIdentDefs.newTree(
        left,
        ident(typeStr),
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


proc variantImpl(typename, body: NimNode; isRef, isPublic: bool): NimNode =
  var
    isGeneric: bool
    genericParams = nnkGenericParams.newTree(nnkIdentDefs.newTree())
    typeStr: string
  typename.expectKind({nnkBracketExpr, nnkIdent})
  case typename.kind
  of nnkIdent:
    isGeneric = false
    typeStr = typename.strVal
  of nnkBracketExpr:
    typename.expectMinLen(2)
    isGeneric = true
    for i in 1 ..< typename.len:
      typename[i].expectKind(nnkIdent)
      genericParams[0].add typename[i]
    genericParams[0].add newEmptyNode()
    genericParams[0].add newEmptyNode()
    typeStr = typename[0].strVal
  else:
    discard
  body.expectKind(nnkStmtList)
  let
    enumName = ident(typeStr & "Kind")
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
  let
    objtyBody = nnkObjectTy.newTree(
        newEmptyNode(),
        newEmptyNode(),
        nnkRecList.newTree(field)
      )
  result.add newEnum(enumName, kinds, false, true)
  result.add nnkTypeSection.newTree nnkTypeDef.newTree(
    if isPublic: nnkPostfix.newTree(
      ident"*",
      ident(typeStr)
    ) else: ident(typeStr),
    if isGeneric: genericParams else: newEmptyNode(),
    if isRef: nnkRefTy.newTree(objtyBody) else: objtyBody
  )
  for fs in xs:
    result.add generateConstructor(fs, typename, enumName, isGeneric, isRef,
        isPublic, genericParams)
  result.add generateFunctions(typename, enumName, xs, isGeneric, isRef,
      isPublic, genericParams)
  result.add generateMatcher(xs, enumName, typeStr, isRef, isPublic)
  result = result.copy

macro variant*(typename, body: untyped): untyped =
  return variantImpl(typename, body, false, false)

macro variantp*(typename, body: untyped): untyped =
  return variantImpl(typename, body, false, true)

macro variantRef*(typename, body: untyped): untyped =
  return variantImpl(typename, body, true, false)

macro variantRefp*(typename, body: untyped): untyped =
  return variantImpl(typename, body, true, true)
