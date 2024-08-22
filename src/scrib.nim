# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import lexer, ast

var l = newScribLexer("example.scrib")
var t: Token

while t.kind != tkEOF:
  t = l.getNextToken()
  echo t
