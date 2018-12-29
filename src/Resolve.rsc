module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

// the reference graph
alias UseDef = rel[loc use, loc def];


// Combines the usage and definition sets to obtain the declaration location from each usage location
UseDef resolve(AForm f) = uses(f) o defs(f);

/*
 * Creates a set of tuples<loc, name> referring to the uses of each
 * variable by name and location.
*/
Use uses(AForm f) = { *{<e.src, e.name> | e has name} | /AExpr e <- f};


/* 
 * Creates a set of tuples<name,loc> referring to the initial declaration of
 * each variable name and their corresponding locations.
*/
Def defs(AForm f) = { *{<q.id, q.src> | q has id} | /AQuestion q <- f };
