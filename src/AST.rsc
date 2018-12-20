module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ;


data AQuestion(loc src = |tmp:///|)
  = qSimple(str question, str id, AType t)
  | qSimpleDef(str question, str id, AType t, AExpr val)
  | qIf(AExpr cond, list[AQuestion] block)
  | qIfElse(AExpr cond, list[AQuestion] ifBlock, list[AQuestion] elseBlock)
  ;


data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | eInt(int n)
  | eBool(bool b)
  | eStr(str s)
  | eBracks(AExpr e1)
  | eLt(AExpr e1, AExpr e2) // <
  | eLeq(AExpr e1, AExpr e2) // <=
  | eGt(AExpr e1, AExpr e2) // >
  | eGeq(AExpr e1, AExpr e2) // >=
  | eDiv(AExpr e1, AExpr e2)
  | eProd(AExpr e1, AExpr e2)
  | eAdd(AExpr e1, AExpr e2)
  | eSub(AExpr e1, AExpr e2)
  ;

data AType(loc src = |tmp:///|) 
  = typeBool()
  | typeInt()
  | typeStr()
  ;