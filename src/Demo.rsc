module Demo

import AST;
import CST2AST;
import Check;
import Compile;
import Eval;
import Resolve;
import Syntax;
import Transform;

import IO;
import ParseTree;


AForm createAST(loc u) = cst2ast(parse(#start[Form], u));


// DEMO FOR TRANSFORM
void demoRename() {
  start[Form] f = parse(#start[Form], |project://QL/examples/simple.myql|);
  loc use = |project://QL/examples/simple.myql|(152,2,<9,17>,<9,19>);
  loc def = |project://QL/examples/simple.myql|(38,2,<3,4>,<3,6>);
  
  println(rename(f, def, "root"));
}

AForm demoFlatten() {
  AForm f = createAST(|project://QL/examples/flattenable.myql|);
  return flatten(f);
}


// DEMO FOR EVAL
VEnv demoEval(bool b) {
  AForm f = createAST(|project://QL/examples/simple.myql|);
  Input inp = input("bool", vbool(b));
  VEnv env = initialEnv(f);
  
  return eval(f, inp, env);
}

// DEMO FOR RESOLVE
UseDef demoResolve() {
  AForm f = createAST(|project://QL/examples/simple.myql|);
  return resolve(f);
}


// DEMO FOC COMPILE
void demoCompile() {
  list[loc] locs = [
                    |project://QL/examples/binary.myql|,
                    |project://QL/examples/cyclic.myql|,
                    |project://QL/examples/empty.myql|,
                    |project://QL/examples/errors.myql|,
                    |project://QL/examples/flattenable.myql|,
                    |project://QL/examples/my_example.myql|,
                    |project://QL/examples/simple.myql|,
                    |project://QL/examples/tax.myql|
  				];
  
  for (loc u <- locs)
    compile(createAST(u));
}

// DEMO ERROR CHECKING
void checkForm(loc u) {
  AForm f =  createAST(u);
  TEnv tenv = collect(f);
  UseDef ud = resolve(f);
  for ( Message m <- check(f, tenv, ud) )
    println(m);
}

void demoErrors() {
  checkForm(|project://QL/examples/errors.myql|);
}