module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return cst2ast(f);
  //return form("", [], src=f@\loc); 
}



AForm cst2ast(f:(Form)`form <Id x> { <Question* qs> }`)
  = form("<x>", [cst2ast(q) | Question q <- qs], src=f@\loc)
  ;

AQuestion cst2ast(Question q) {
  switch(q) {
    case (Question)`<Str questionText> <Identifier id> : <Type t>`:
      return qSimple("<questionText>", "<id>", cst2ast(t), src=q@\loc);
      
    case (Question)`<Str questionText> <Identifier id> : <Type t> = <Expr e>`:
      return qSimpleDef("<questionText>", "<id>", cst2ast(t), cst2ast(e), src=q@\loc);
      
	case (Question)`if ( <Expr cond> ) { <Question* qs> }`:
	  return qIf(cst2ast(cond), [cst2ast(q) | Question q <- qs], src=q@\loc);
	
	case (Question)`if ( <Expr cond> ) { <Question* qs1> } else { <Question* qs2> }` :
	  return qIfElse(cst2ast(cond), 
	                   [cst2ast(q) | Question q <- qs1],
	                     [cst2ast(q) | Question q <- qs2],
                           src=q@\loc);
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    // identifier
    case (Expr)`<Id x>`: return ref("<x>", src=e@\loc);
    
    // literal expressions
    case (Expr)`<Int i>`: return eInt(toInt("<i>"), src=e@\loc);
    case (Expr)`<Bool b>`: return eBool("<b>" == "true", src=e@\loc);
    case (Expr)`<Str s>`: return eStr("<s>", src=e@\loc);
    
    case (Expr)`( <Expr ex> )`:
      return eBracks( cst2ast(ex), src=e@\loc );
    
    // arithmetic operations
    case (Expr)`<Expr e1> / <Expr e2>`:
      return eDiv(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1> * <Expr e2>`:
      return eProd(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1> - <Expr e2>`:
      return eSub(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1> + <Expr e2>`:
      return eAdd(cst2ast(e1), cst2ast(e2), src=e@\loc);
    
    // comparison operations
    case (Expr)`<Expr e1> \< <Expr e2>`:
      return eLt(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1> \<= <Expr e2>`:
      return eLeq(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1> \> <Expr e2>`:
      return eGt(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1> \>= <Expr e2>`:
      return eGeq(cst2ast(e1), cst2ast(e2), src=e@\loc);
    
    // boolean operations
    case (Expr)`<Expr e1> && <Expr e2>`:
      return eAnd(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1> || <Expr e2>`:
      return eOr(cst2ast(e1), cst2ast(e2), src=e@\loc);
      
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch (t) {
    case (Type)`integer` : return typeInt(src=t@\loc);
    case (Type)`boolean` : return typeBool(src=t@\loc);
    case (Type)`string`  : return typeStr(src=t@\loc);
  }
}
