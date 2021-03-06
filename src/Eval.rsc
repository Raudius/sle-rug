module Eval

import IO;
import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  

/*
 * Return a default value for a type
 */
Value defaultValue(AType t) {
  switch (t) {
    case typeInt():
      return vint(0);
    case typeBool():
      return vbool(false);
    case typeStr():
      return vstr("");
  }
  // not caught by switch-case throw error:
  throw "Undefined type <t>";
}


Value eval(AQuestion q, VEnv env) {
  if(q has val) return eval(q.val, env);
  return defaultValue(q.t);
}


// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv env = ();
  return solve(env)
    env = initialEval(f.questions, env);
}


VEnv initialEval(list[AQuestion] qs, VEnv env) {
  for(AQuestion q <- qs) {
    switch(q) {
      // default value creation
      case qSimple(str question, str id, AType t):
        env[id] = defaultValue(t);
        
      // try to apply definition to question 
      // ignore failures as  we can assume name correctness
      case qSimpleDef(str question, str id, AType t, AExpr val):
        try env[id] = eval(val, env);
        catch NoSuchKey: ; 
        
      // branching
      case qIf(AExpr cond, list[AQuestion] block):
        if( eval(cond, env).b )  env = initialEval(block, env);
      case qIfElse(AExpr cond, list[AQuestion] ifBlock, list[AQuestion] elseBlock):
        if ( eval(cond,env).b ) env = initialEval(ifBlock, env);
        else env = initialEval(elseBlock, env);  
    }
  }
  return env;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(AQuestion q <- f.questions)
    venv = eval(q, inp, venv);
  return venv;
}


VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch(q) {
    // Simple question
    case qSimple(str question, str id, AType t): // check type match?
      if(inp.question == id) venv[id] = inp.\value;
      
    // Computed question (i.e. with definition)
    case qSimpleDef(str question, str id, AType t, AExpr val):
      venv[id] = eval(val, venv);

    // If question
    case qIf(AExpr cond, list[AQuestion] block):
      if( eval(cond, venv).b )
        for(AQuestion q <- block)  venv += eval(q, inp, venv);
      else 
        venv = removeNames(venv, block);
    
    // If-then-else question
    case qIfElse(AExpr cond, list[AQuestion] ifBlock, list[AQuestion] elseBlock):
      if( eval(cond, venv).b ) {
        venv = removeNames(venv, elseBlock);
        for(AQuestion q <- ifBlock)   venv += eval(q, inp, venv);
      }
      else {
        venv = removeNames(venv, ifBlock);
        for(AQuestion q <- elseBlock) venv += eval(q, inp, venv);
      }
  }
  
  return venv; 
}


VEnv removeName(VEnv env, qSimple(_, str id, _)) = env - (id:0);
VEnv removeName(VEnv env, qSimpleDef(_, str id, _, _)) = env - (id:0);
VEnv removeName(VEnv env, qIf(_, list[AQuestion] block)) = removeNames(env, block);
VEnv removeName(VEnv env, qIfElse(_, list[AQuestion] ifBlock, list[AQuestion] elseBlock))
  = removeName(removeNames(env, ifBlock), elseBlock);

VEnv removeNames(VEnv env, list[AQuestion] qs) {
  for(AQuestion q <- qs) {
    env = removeName(env, q);
  }
  return env;
}




Value eval(AExpr e, VEnv venv) {
  int n;
  switch (e) {
    // reference 
    case ref(str x): return venv[x];
    
    // literals
    case eInt(int n): return vint(n);
    case eBool(bool b): return vbool(b);
    case eStr(str s): return vstr(s);
    case eBracks(AExpr e1): return eval(e1, venv);
    
    // comparators
    case eLt(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n < eval(e2, venv).n );
    case eLeq(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n <= eval(e2, venv).n );
    case eGt(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n > eval(e2, venv).n );
    case eGeq(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n >= eval(e2, venv).n );
      
    // booolean ops
    case eAnd(AExpr e1, AExpr e2):
      return vbool( eval(e1, venv).b && eval(e2, venv).b);
    case eOr(AExpr e1, AExpr e2):
	      return vbool(eval(e1,venv).b || eval(e2, venv).b);
    
    // arithmetical operators
    case eDiv(AExpr e1, AExpr e2): 
      n = eval(e1, venv).n / eval(e2, venv).n;
    case eProd(AExpr e1, AExpr e2): 
      n = eval(e1, venv).n * eval(e2, venv).n;
    case eAdd(AExpr e1, AExpr e2): 
      n = eval(e1, venv).n + eval(e2, venv).n;
    case eSub(AExpr e1, AExpr e2): 
      n = eval(e1, venv).n - eval(e2, venv).n;
    
    default: throw "Unsupported expression <e>";
  }
  
  return vint(n);
}