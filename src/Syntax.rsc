module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id Block; 


syntax Block = "{" Question* "}" ;

syntax Identifier = Id \ "true" \ "false" \ "form" \ "if" \ "else";


syntax Question
  = "if" "(" Expr ")" Block 
  | "if" "(" Expr ")" Block "else" Block
  | Str Identifier ":" Type
  | Str Identifier ":" Type "=" Expr 
  ; 
  
  
syntax Expr 
  = Identifier
  | Int
  | Bool
  | Str
  | "(" Expr ")"
  > left ( 
    Expr '/' Expr
    | Expr '*' Expr
  )
  > left( 
    Expr '+' Expr
    | Expr '-' Expr
  )
  > non-assoc( 
    Expr '\<' Expr 
    | Expr '\<=' Expr 
    | Expr '\>' Expr 
    | Expr '\>=' Expr 
    )
  ;
  
syntax Type = "boolean" | "integer" | "string";  
  
lexical Str = "\"" ![\"]* "\"";

lexical Int = [0-9]+;

lexical Bool = "true" | "false";
