/* lexical grammar */
%lex
%%

(\s+|\/\/+.*\n)        /* skip whitespace and line comments */
[0-9]+("."[0-9]+)?\b  return 'NUMBER'
\"([^\\\"]|\\.)*\"    return 'STRING_LITERAL'
"$"                   return "$"
"@"                   return "@"
"import"              return "import"
"from"                return "from"
"endfunction"         return "endfunction"
"endwhile"            return "endwhile"
"endfor"              return "endfor"
"endswitch"           return "endswitch"
"endif"               return "endif"
"function"            return "function"
"continue"            return "continue"
"typeof"              return "typeof"
"class"               return "class"
"const"               return 'const'
"elseif"              return 'elseif'
"if"                  return 'if'
"else"                return 'else'
"case"                return "case"
"otherwise"           return 'otherwise'
"return"              return 'return'
"yield"               return 'yield'
"while"               return 'while'
"switch"              return 'switch'
"break"               return 'break'
"for"                 return 'for'
"var"                 return 'var'
"of"                  return 'of'
","                   return ','
";"                   return ';'
"..."                 return '...'
"."                   return '.'
":"                   return ':'
"&&"                  return '&&'
"&"                   return '&'
"||"                  return '||'
"|"                   return '|'
">="                  return '>='
">"                   return '>'
"<="                  return '<='
"<"                   return '<'
"=="                  return '=='
"!="                  return '!='
"!"                   return "!"
"="                   return '='
"%"                   return '%'
"*="                  return '*='
"*"                   return '*'
"/="                  return '/='
"/"                   return '/'
"-="                  return '-='
"--"                  return '--'
"-"                   return '-'
"++"                  return '++'
"+="                  return '+='
"+"                   return '+'
"^"                   return '^'
"{"                   return '{'
"}"                   return '}'
"["                   return '['
"]"                   return ']'
"?"                   return '?'
"("                   return '('
")"                   return ')'
"instanceof"          return 'instanceof'
"in"                  return 'in'
[a-zA-Z_][a-zA-Z0-9_]* return 'IDENTIFIER'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */

%right '?'

%left '...'
%left '||' '|'
%left '&&' '&'
%left '<' '<=' '>' '>=' '==' '!='
%left '+' '-'
%left '*' '/' '%'
%left UMINUS

%start expressions

%% /* language grammar */

expressions
    : statements_ EOF
        {return ["top_level_statements",$1];}
    ;

statements_: statement statements_ {$$ = [$1].concat($2);} | statement {$$ =
 [$1];};

statements: statements_ {$$ = ["statements",$1]};

case_statement: "case" parentheses_expr statements {$$ = ["case",$2,$3]};
case_statements_: case_statement case_statements_ {$$ = [$1].concat($2);} | case_statement {$$ =
 [$1];};
case_statements: case_statements_ "otherwise" statements {$$ = $1.concat([["default",$3]])} | case_statements_;


statement
    :
    "switch" "(" e ")" case_statements "endswitch" {$$ = ["switch",$3,$5];}
    | "while" "(" e ")" statements "endwhile" {$$ = ["while",$3,$5];}
    | "function" IDENTIFIER "(" parameters ")" statements "endfunction" {$$ = ["function","public","void",$2,$4,$6];}
    | statement_with_semicolon ";" {$$ = ["semicolon",$1];}
    | "if" "(" e ")" statements elif "endif" {$$ = ["if",$3,$5,$6];}
	| "if" "(" e ")" statements "endif" {$$ = ["if",$3,$5];}
    ;

statement_with_semicolon
   : 
   "import" IDENTIFIER "from" STRING_LITERAL {$$ = ["import_from",$2,$4];}
   | "continue" {$$ = [$1];}
   | "return" e  {$$ = ["return",$2];}
   | access_array "=" e {$$ = ["set_var",$1,$3];}
   | IDENTIFIER "=" e {$$ = ["set_var",$1,$3];}
   | IDENTIFIER "++" {$$ = [$2,$1];}
   | IDENTIFIER "--" {$$ = [$2,$1];}
   | IDENTIFIER "+=" e {$$ = [$2,$1,$3];}
   | IDENTIFIER "-=" e {$$ = [$2,$1,$3];}
   | IDENTIFIER "*=" e {$$ = [$2,$1,$3];}
   | IDENTIFIER "/=" e {$$ = [$2,$1,$3];}
   | function_call
   ;
e
    :
     e "?" e ":" e {$$ = ["ternary_operator",$1,$3,$5]}
    | "..." e {$$=["unpack_array",$2]}
    |e '||' e
        {$$ = [$2,$1,$3];}
    |e '|' e
        {$$ = [$2,$1,$3];}
    |e '&&' e
        {$$ = [$2,$1,$3];}
    |e '&' e
        {$$ = [$2,$1,$3];}
    |e '!=' e
        {$$ = ['!=',$1,$3];}
    |e '==' e
        {$$ = ['==',$1,$3];}
    |e '<=' e
        {$$ = [$2,$1,$3];}
    |e '<' e
        {$$ = [$2,$1,$3];}
    | e '>=' e
        {$$ = [$2,$1,$3];}
    |e '>' e
        {$$ = [$2,$1,$3];}
    | e '+' e
        {$$ = [$2,$1,$3];}
    | e '-' e
        {$$ = [$2,$1,$3];}
    | e '*' e
        {$$ = [$2,$1,$3];}
    | e '/' e
        {$$ = [$2,$1,$3];}
    | e '%' e
        {$$ = [$2,$1,$3];}
    | '-' e %prec UMINUS
        {$$ = ["-",$2];}
    | not_expr
    ;

not_expr: "!" dot_expr {$$ = ["!", [".",$2]];} | dot_expr {$$ = [".", $1];};


dot_expr: parentheses_expr  "." dot_expr  {$$ = [$1].concat($3);} | parentheses_expr {$$ =
 [$1];};

access_array: IDENTIFIER "[" e "]" {$$ = ["access_array",$1,[$3]];};

function_call:
	IDENTIFIER "(" ")" {$$= ["function_call",$1,[]];}
    | IDENTIFIER "(" exprs ")" {$$= ["function_call",$1,$3];};

parentheses_expr:
    "(" "@" "(" parameters ")" parentheses_expr_ ")" {$$ = ["anonymous_function","Object",$4,["statements",[["semicolon",["return",$6]]]]];}
    | function_call
    | access_array
    | '(' e ')' {$$ = ["parentheses",$2];}
    | parentheses_expr_;

parentheses_expr_:
    "{" "}" {$$ = ["associative_array","Object","Object",[]];}
    | "{" key_values "}" {$$ = ["associative_array","Object","Object",$2];}
    | "[" "]" {$$ = ["initializer_list","Object",[]];}
    | "[" exprs "]" {$$ = ["initializer_list","Object",$2];}
    | NUMBER
        {$$ = yytext;}
    | IDENTIFIER
        {$$ = yytext;}
    | STRING_LITERAL
        {$$ = yytext;};

parameter: IDENTIFIER "=" e {$$ = ["default_parameter","Object",$1,$3];} | IDENTIFIER {$$ = ["Object", $1];};
parameters: parameter "," parameters {$$ = [$1].concat($3);} | parameter {$$ =
 [$1];} | {$$ = []};
exprs: e "," exprs {$$ = [$1].concat($3);} | e {$$ = [$1];};

key_values: key_values "," key_value {$$ = $1.concat([$3]);} | key_value {$$ = [$1];};
key_value: STRING_LITERAL ":" e {$$ = [$1,$3]} | IDENTIFIER ":" e {$$ = ["\""+$1+"\"",$3]};

elif: "elseif" "(" e ")" statements elif {$$ = ["elif",$3,$5,$6]} | "else" statements {$$ = ["else",$2];};
identifiers: IDENTIFIER "," identifiers {$$ = [$1].concat($3);} | IDENTIFIER {$$ = [$1];};
