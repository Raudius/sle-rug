module Compile

import String;
import Check;
import AST;
import Resolve;
import IO;
import MyDOM; // see standard library

import Type;
import Syntax;
import ParseTree;
import CST2AST;
/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */


// Creates a string hash for a location value
str loc2str(loc u) = "<u.begin.line>_<u.begin.column>";

void compile(AForm f) {
  str name = f.src[extension=""].file;

  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f, name)));
}



/****************/
/****************/
/* HTML Compile */
/****************/
/****************/
HTML5Attr v_model(value val) = html5attr("v-model", val);
HTML5Attr v_model_number(value val) = html5attr("v-model.number", val);
HTML5Attr v_if(value val) = html5attr("v-if", val);
HTML5Attr v_else() = html5attr("v-else", "");

// simple question: create input field
HTML5Node q2html(qSimple(str qst, str id, AType t)) =
  p(
    "<qst>: ",
    input(
      [
        *[v_model("q_<id>") | getType(t) != tint()], // tint() has its own v_model for automatic casting

        *[\type("checkbox") | getType(t) == tbool()],
        *[*\type("number"), v_model_number("q_<id>") | getType(t) == tint()],
        *[\type("input") | getType(t) == tstr()]
      ]
    )
  );

// question with definition: result shown as string
HTML5Node q2html(qSimpleDef(str qst, str id, AType t, AExpr val))
  = p("<qst>: ", "{{ get_" + id + "() }}");

// if-block: create 'condictionally-shown div' with v_if
HTML5Node q2html(qIf(AExpr cond, list[AQuestion] block))
  = div(
      v_if("if_<loc2str(cond.src)>()"), 
      qblock2html(block) 
    );


// if-then-else block 'condictionally-shown divs' with v_if/v_else
HTML5Node q2html(qIfElse(AExpr cond, list[AQuestion] block, list[AQuestion] elseBlock))
  = div(
      div(
        v_if("if_<loc2str(cond.src)>()"), 
        qblock2html(block) 
      ),
      div(
        v_else(),
        qblock2html(elseBlock)
      )
    );

// question block
HTML5Node qblock2html(list[AQuestion] qs) = div([q2html(q) | AQuestion q <- qs]);

// Construct html form
HTML5Node form2html(AForm f, str name) =
  html( 
   head(
    script(src("https://cdn.jsdelivr.net/npm/vue/dist/vue.js"))
   ), 
   body(
    div(
     id("form_" + f.name),
     qblock2html(f.questions)
    ),
    script(src("<name>.js"))
   )
  );




/****************/
/****************/
/** JS Compile **/
/****************/
/****************/

// These aliases are used to help model the Vue app
// VData contains the data entries of the app
// VMethods contains the method entries of the app
// VApp holds the methods and data in a tuple
alias VData = rel[str name, value val];
alias VMethods = rel[str name, AExpr expr];
alias VApp = tuple[VData ds, VMethods ms];

// Merge multiple apps into a single app
VApp vMerge(VApp apps...) {
  VApp app = <{}, {}>;
  for(VApp app2 <- apps) {
    app.ds += app2.ds;
    app.ms += app2.ms;
  }
  return app;
}

// A simple question adds a data entry to the ap wit its name and default value
VApp q2js(qSimple(str q, str id, AType t)) {
  value v;
  switch(getType(t)) {
    case tbool():
      v = false;
    case tint():
      v = 0;
    case tstr():
      v ="\"\"";
  }
  return < {<id, v>}, {} >;
}

// A question with a definition adds a method to the VueApp which computes its value
VApp q2js(qSimpleDef(str question, str id, AType t, AExpr val))
 = < {}, {<"get_<id>", val>} >;

// Ifs adds a method to the app which computes its condition
VApp q2js(qIf(AExpr cond, list[AQuestion] block)) 
 = vMerge( <{}, {<"if_<loc2str(cond.src)>", cond>}>, qblock2js(block) );

VApp q2js(qIfElse(AExpr cond, list[AQuestion] ifBlock, list[AQuestion] elseBlock))
  = vMerge( <{}, {<"if_<loc2str(cond.src)>", cond>}>,
  qblock2js(ifBlock), qblock2js(elseBlock) );

// Gets the data and method attributes of all questions in the block
VApp qblock2js(list[AQuestion] qs) =
  vMerge( [q2js(q) | AQuestion q <- qs] );


// Convert QL expressions to Javascript expressions
str expr2js(ref(str name)) = "this.get_<name>()";
str expr2js(eInt(int n)) = "<n>";
str expr2js(eBool(bool b)) = "<b>";
str expr2js(eStr(str s)) = "<s>";
str expr2js(eBracks(AExpr e1)) = "(" + expr2js(e1) + ")";
// <
str expr2js(eLt(AExpr e1, AExpr e2))
  = expr2js(e1) + "\<" + expr2js(e2);
// <=
str expr2js(eLeq(AExpr e1, AExpr e2))
  = expr2js(e1) + "\<=" + expr2js(e2);
// >
str expr2js(eGt(AExpr e1, AExpr e2))
  = expr2js(e1) + "\>" + expr2js(e2);
// >=
str expr2js(eGeq(AExpr e1, AExpr e2))
  = expr2js(e1) + "\>=" + expr2js(e2);
// /
str expr2js(eDiv(AExpr e1, AExpr e2))
  = expr2js(e1) + "/" + expr2js(e2);
// *
str expr2js(eProd(AExpr e1, AExpr e2))
  = expr2js(e1) + "*" + expr2js(e2);
// +
str expr2js(eAdd(AExpr e1, AExpr e2))
  = expr2js(e1) + "+" + expr2js(e2);
// -
str expr2js(eSub(AExpr e1, AExpr e2))
  = expr2js(e1) + "-" + expr2js(e2);
  

// &&
str expr2js(eAnd(AExpr e1, AExpr e2))
  = expr2js(e1) + "&&" + expr2js(e2);

// ||
str expr2js(eOr(AExpr e1, AExpr e2))
  = expr2js(e1) + "||" + expr2js(e2);

// make a Vue method from function name and return expression strings
str make_func(str name, str r)
  = "<name>: function() {
	'  return <r>;
	'},\n";

// converts a form into a JS string
str form2js(AForm f) {
  // VApp contains the data and method attributes for the Vue app
  VApp app = qblock2js(f.questions);
  
  str _data = "";
  str _methods = "";
  // for each data attribute add its entry to the app and create a getter method
  for(<name, val> <- app.ds) {
    _data += "q_<name>:<val>,\n";
    _methods += make_func("get_<name>", "this.q_<name>");
  }
  
  // create all methods for the Vue app (for computed questions and if conditions)
  for(<name, expr> <- app.ms) {
    str m = expr2js(expr);
    _methods += make_func(name, m);
  }

  // return the Vue app with the data and method attributes computed above  
  return "var app = new Vue({
         'el: \'#form_<f.name>\',
         'data: {
         '<_data>
         '},
         'methods: {
         '<_methods>
         '}
         '})";
}
