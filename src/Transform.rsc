module Transform

import Syntax;
import Resolve;
import AST;
import Eval;
import CST2AST;

import IO;
import Set;
import Type;
import ParseTree;
/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; if (a) { if (b) { q1: "" int; } q2: "" int; }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
AForm flatten(AForm f) = form(f.name, flatten(f.questions, []));


// flattens a list of conditions into an single condition
AExpr flatten(list[AExpr] conds) {
  AExpr expr = eBool(true);
  for(AExpr e <- conds) {
    if(expr == eBool(true))
      expr = e;
    else
      expr = eAnd(expr, e); 
  }
  return expr;
}

// flatten single questions -> transform them into if statements
AQuestion flatten(qSimple(str question, str id, AType t), list[AExpr] conds) 
  = qIf(flatten(conds), [qSimple(question, id, t)]);
AQuestion flatten(qSimpleDef(str question, str id, AType t, AExpr val), list[AExpr] conds)
  = qIf(flatten(conds), qSimple(question, id, t));
 
// gather questions from if statements and pass on conditions
list[AQuestion] flatten(qIf(AExpr cond, list[AQuestion] block), list[AExpr] conds)
  = flatten(block, conds+cond);
list[AQuestion] flatten(qIfElse(AExpr cond, list[AQuestion] ifBlock, list[AQuestion] elseBlock), list[AExpr] conds)
  = flatten(ifBlock, conds+cond)
  + flatten(elseBlock, conds);
  
// flatten a list of questions
list[AQuestion] flatten(list[AQuestion] qs , list[AExpr] conds) 
  = [ *flatten(q, conds) | AQuestion q <- qs ];



/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName) {
  // perform checks
  if(!isValidId(newName))
    throw ("New name: \'<newName>\' is not a valid name for an Identifier.");
  if(!isIdAvailable(cst2ast(f).questions, newName))
    throw ("New name: \'<newName>\' is already in use.");
   
  // get old and new names as Identifiers
  Identifier oldId = treeAt(#Identifier, useOrDef, f).tree;
  Identifier newId = parse(#Identifier, newName);
   
  // visit every node in the tree and replace any Identifier id == oldId with the new id 
  return visit(f) {
    case (Identifier) `<Identifier id>`:
      if("<id>" == "<oldId>") 
        insert newId;
  } 
}

// checks if an Id's name is valid (i.e. is accepted by the grammar)
bool isValidId(str name) {
  try 
    parse(#Identifier, name);
  catch ParseError:
    return false;  
  return true;
}

// checks whether an Id's name is already in use in a form
bool isIdAvailable(list[AQuestion] qs, str name) {
  for(AQuestion q <- qs) {
    switch(q) {
      case qSimple(_, str id, _):
        if(id == name) return false;
      case qSimpleDef(_, str id, _, _):
        if(id == name) return false;
      case qIf(_, list[AQuestion] block):
        if(!isIdAvailable(block, name)) return false;
      case qIfElse(_, list[AQuestion] ifBlock, list[AQuestion] elseBlock): {
        if(!isIdAvailable(ifBlock, name)) return false;
        if(!isIdAvailable(elseBlock, name)) return false;
      }
    }
  }
  return true;
}
