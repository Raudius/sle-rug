module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id Block; 



// TODO: question, computed question, block, if-then-else, if-then
syntax Block = "{" Question* "}" ;

syntax Identifier = Id \ "true" \ "false";

syntax IdDefinition
  = Identifier ":" Type
  | Identifier ":" Type "=" Expr
  ;

syntax Question
  = "if" "(" Expr ")" Block 
  | "if" "(" Expr ")" Block "else" Block
  | Str IdDefinition
  ; 
  
  

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Identifier
  | Int
  | Bool
  | "(" Expr ")"
  > Expr [\<|\>|\<=|\>=] Expr
  > Expr '/' Expr
  > Expr '*' Expr
  > Expr '+' Expr
  > Expr '-' Expr
  ;
  
syntax Type = "boolean" | "integer" | "string";  
  
lexical Str = "\"" ![\"]* "\"";

lexical Int = [0-9]+;

lexical Bool = "true" | "false";
