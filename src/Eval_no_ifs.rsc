module Eval_no_ifs

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
  
  bool unresolved = true;
  while(unresolved) {
    unresolved = false;
    for(AQuestion q := f) {
      if (!q has id) continue; // ignore if 'questions' 
      
      try
        env[q.id] = eval(q, env);
      catch NoSuchKey:
        unresolved = true;
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
  venv[inp.question] =  inp.\value;
  
  for (/AQuestion q := f)
    eval(q, inp, venv);
  
  return venv; 
}



VEnv eval(AQuestion q, Input inp, VEnv venv) {
  if (q has val) 
    ;
  
  return venv; 
}


Value eval(AExpr e, VEnv venv) {
  int n;
  switch (e) {
    case ref(str x): return venv[x];
    case eInt(int n): return vint(n);
    case eBool(bool b): return vbool(b);
    case eStr(str s): return vstr(s);
    case eBracks(AExpr e1): return eval(e1, venv);
    case eLt(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n < eval(e2, venv).n );
    case eLeq(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n <= eval(e2, venv).n );
    case eGt(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n > eval(e2, venv).n );
    case eGeq(AExpr e1, AExpr e2): 
      return vbool( eval(e1, venv).n >= eval(e2, venv).n );
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