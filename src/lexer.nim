import std/[lexbase, streams]

type
  ScribLexer* = object of BaseLexer

  TokenKind* = enum
    tkIdent
    tkBuiltIn
    tkPipe
    tkString
    tkEOF
    tkLParen
    tkRParen
    tkDot
    tkEnvVar
    tkPlus
    tkMinus
    tkSlash
    tkAsterisk
    tkAssign
    tkEqual
    tkBang
    tkNotEq

  Token* = object
    kind*: TokenKind
    value*: string


proc newScribLexer*(filename: string): ScribLexer =
  let fs = openFileStream(filename)
  result = ScribLexer()
  result.open(fs)


proc curr(L: ScribLexer): string =
  result = $L.buf[L.bufpos]


proc peek(L: ScribLexer): char =
  result = L.buf[L.bufpos + 1]


proc next(L: var ScribLexer) =
  inc(L.bufpos)


proc extractIdent(L: var ScribLexer): string =
  result = ""
  while L.buf[L.bufpos] in {'a'..'z', 'A'..'Z', '_'}:
    result.add(L.buf[L.bufpos])
    L.next()


proc extractString(L: var ScribLexer): string =
  result = ""
  while L.buf[L.bufpos] != '"':
    result.add(L.buf[L.bufpos])
    L.next()
  L.next()


proc getNextToken*(L: var ScribLexer): Token =
  while L.buf[L.bufpos] in {'\t', ' '}:
    L.next()

  while L.buf[L.bufpos] in {'\n', '\r'}:
    L.bufpos = L.handleLF(L.bufpos)

  if L.buf[L.bufpos] == EndOfFile:
    result = Token(kind: tkEOF, value: "")
    return

  case L.buf[L.bufpos]:
  of '@':
    L.next()
    let builtIn = L.extractIdent()
    result = Token(kind: tkBuiltIn, value: builtIn)

  of '$':
    L.next()
    let envVar = L.extractIdent()
    result = Token(kind: tkEnvVar, value: envVar)

  of {'a'..'z', 'A'..'Z', '_'}:
    let ident = L.extractIdent()
    result = Token(kind: tkIdent, value: ident)

  of '|':
    if L.peek() == '>':
      var pipe = L.curr()
      L.next()
      pipe.add(L.buf[L.bufpos])
      L.next()
      result = Token(kind: tkPipe, value: pipe)

  of '"':
    L.next()
    let str = L.extractString()
    result = Token(kind: tkString, value: str)

  of '(':
    result = Token(kind: tkLParen, value: L.curr())
    L.next()

  of ')':
    result = Token(kind: tkRParen, value: L.curr())
    L.next()

  of '.':
    result = Token(kind: tkDot, value: L.curr())
    L.next()

  of '+':
    result = Token(kind: tkPlus, value: L.curr())
    L.next()

  of '-':
    result = Token(kind: tkMinus, value: L.curr())
    L.next()

  of '*':
    result = Token(kind: tkAsterisk, value: L.curr())
    L.next()

  of '/':
    result = Token(kind: tkSlash, value: L.curr())
    L.next()

  of '=':
    if L.peek() == '=':
      var eq = L.curr()
      L.next()
      eq.add(L.curr())
      result = Token(kind: tkEqual, value: eq)
      L.next()
    else:
      result = Token(kind: tkAssign, value: L.curr())
      L.next()

  of '!':
    if L.peek() == '=':
      var neq = L.curr()
      neq.add(L.peek())
      result = Token(kind: tkNotEq, value: neq)
      L.bufpos += 2
    else:
      result = Token(kind: tkBang, value: L.curr())
      L.next()

  else:
    discard
