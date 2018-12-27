module Check

import IO;
import Set;
import AST;
import Resolve;
import Message; // see standard library

import Syntax;
import CST2AST;
import ParseTree;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  
void check_test(loc src) {
  AForm f = cst2ast(parse(#start[Form], src));
  UseDef use_def = resolve(f);
  TEnv tenv = collect(f);
  
  set[Message] msgs = check(f, tenv, use_def);
  
  println(size(msgs));
  for(Message m <- msgs) {
    println(m);
  }
}

  
Type getType(typeBool()) = tbool();
Type getType(typeInt()) = tint();
Type getType(typeStr()) = tstr();

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];


TEnv collect(qSimple(str question, str id, AType t, src = loc u)) 
  = {<u, id, question, getType(t)>};
TEnv collect(qSimpleDef(str question, str id, AType t, AExpr val, src = loc u)) 
  = {<u, id, question, getType(t)>};
// no need to recursively collect from 'list[AQ] block'  because of deep matching
TEnv collect(qIf(AExpr cond, list[AQuestion] block)) = {};
TEnv collect(qIfElse(AExpr cond, list[AQuestion] ifBlock, list[AQuestion] elseBlock)) = {};

// Get type for all questions
TEnv collect(AForm f) = {*collect(q) | /AQuestion q := f};


set[Message] check(AForm f, TEnv tenv, UseDef useDef)
  = { *check(q, tenv, useDef) | /AQuestion q <- f.questions};

// produces errors or warnings for duplicate labels
// If a type error is already given it does not produce a duplicate label error
set[Message] checkDups(loc u, str id, TEnv tenv) {
  set[Message] msgs = {};
  // get set of types in all definitions of $id
  list[Type] types = [t | <loc u, id, str l, Type t> <- tenv];
  
  msgs += { error("TypeError: Duplicate label \'<id>\' initiated with different types.", u) | size(toSet(types)) > 1} ;
  msgs += { warning("Duplicate label used for <id>", u) | size(msgs) == 0 &&size(types) > 1 };
  
  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  switch (q) {
    case qSimple(str s, str id, AType t): 
      msgs += checkDups(q.src, q.id, tenv);
    
    case qSimpleDef(str s, str id, AType t, AExpr val): {
      msgs += checkDups(q.src, q.id, tenv);
      msgs += { error("Type mismatch in definition", q.src) | typeOf(val, tenv,  useDef) != getType(t) };
      msgs += check(val, tenv, useDef);
    }    
    case qIf(AExpr c, list[AQuestion] block): {
      msgs += { error("Cannot evaluate condition, must be type: bool", q.src) | typeOf(c, tenv,  useDef) != tbool()};
      msgs += check(c, tenv, useDef);
    }
    case qIfElse(AExpr c, list[AQuestion] bIf, list[AQuestion] bElse): {
      msgs += { error("Cannot evaluate condition, must be type: bool", q.src) | typeOf(c, tenv,  useDef) != tbool()};
      msgs += check(c, tenv, useDef);
    }
  }
  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  println(e.src);
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question \'<x>\'", u) | useDef[u] == {} };
    
    // Arithmetic/comparison operators must have integer operands 
    case eLt(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Operator \< expects int operands", u)
                 | typeOf(e1, tenv,  useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
    case eLeq(AExpr e1, AExpr e2, src = loc u): 
      msgs += { error("Operator \<= expects int operands", u)
                 | typeOf(e1, tenv,  useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
    case eGt(AExpr e1, AExpr e2, src = loc u): 
      msgs += { error("Operator \> expects int operands", u) 
                 | typeOf(e1, tenv,  useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
    case eGeq(AExpr e1, AExpr e2, src = loc u): 
      msgs += { error("Operator \>= expects int operands", u)
                 | typeOf(e1, tenv,  useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
    case eDiv(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Operator / expects int operands", u)
                 | typeOf(e1, tenv,  useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
    case eProd(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Operator * expects int operands", u) 
                 | typeOf(e1, tenv, useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
    case eAdd(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Operator + expects int operands", u)
                 | typeOf(e1, tenv,  useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
    case eSub(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Operator - expects int operands", u)
                 | typeOf(e1, tenv,  useDef) != tint() || typeOf(e2, tenv,  useDef) != tint()};
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    // return type of refferenced var from definition
    case ref(str x, src = loc u):
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv)
        return t;
    
    // literals
    case eInt(int n):
      return tint();
    case eBool(bool b):
      return tbool();
    case eStr(str s):
      return tstr();
      
    // Comparison operator returns booleans
    case eLt(AExpr e1, AExpr e2):
      return tbool();
    case eLeq(AExpr e1, AExpr e2):
      return tbool();
    case eGt(AExpr e1, AExpr e2):
      return tbool();
    case eGeq(AExpr e1, AExpr e2):
      return tbool();
    
    // Arithmetic operators return integers
    case eDiv(AExpr e1, AExpr e2):
      return tint();
    case eProd(AExpr e1, AExpr e2):
      return tint();
    case eAdd(AExpr e1, AExpr e2):
      return tint();
    case eSub(AExpr e1, AExpr e2):
      return tint();
  }
  return tunknown(); 
}

