%{
  open Types.Types;;
  open Type_Helpers;;
%}


  %token EOF

  %token IMPORT
  %token BLACKBOX
  %token MODULE
  %token TYPE
  %token PLUS
  %token MINUS
  %token HELPER
  %token ACTION
  %token NOT
  %token <bool> BOOLEAN

  %token PERIOD
  %token AMPERSAND
  %token COLON_HYPHEN
  %token COLON
  %token SEMICOLON
  %token EQUALS
  %token LCURLY
  %token RCURLY
  %token COMMA
  %token LPAREN
  %token RPAREN
  %token DOUBLEQUOTE
  %token <string> DOTTED_IP
  %token <string> NUMBER
  %token <string> NAME
  %start main

  %type <program> main
  %type <string list * blackbox list> top
  %type <term_type list * clause list> bottom
  %type <string> import
  %type <blackbox> blackbox
  %type <string> module_decl
  %type <term_type> type_decl
  %type <string list> name_list
  %type <clause> clause
  %type <atom> atom
  %type <atom list> atom_list
  %type <term> term
  %type <term list> term_list
  %%
  main:
      top module_decl bottom EOF { match $1 with (imports, blackboxes) ->
        match $3 with (types, clauses) ->
        Parse_Helpers.process_program_names (Program($2, imports, blackboxes, types, clauses)) }
  ;
  top:
      import { ([$1], []) }
    | blackbox { ([], [$1]) }
    | import top { match $2 with (imports, blackboxes) -> ($1 :: imports, blackboxes) }
    | blackbox top { match $2 with (imports, blackboxes) -> (imports, $1 :: blackboxes) }
  ;
  bottom:
      type_decl { ([$1], []) }
    | clause { ([], [$1]) }
    | type_decl bottom { match $2 with (types, clauses) -> ($1 :: types, clauses) }
    | clause bottom { match $2 with (types, clauses) -> (types, $1 :: clauses) }
  ;
  import:
      IMPORT NAME SEMICOLON { $2 }
  ;
  blackbox:
      BLACKBOX NAME AMPERSAND DOTTED_IP NUMBER SEMICOLON { BlackBox(String.lowercase $2, External($4, (int_of_string $5))) }
    | BLACKBOX NAME SEMICOLON { BlackBox(String.lowercase $2, Internal) }
  ;
  module_decl:
      MODULE NAME COLON { String.lowercase $2 }
  ;
  type_decl:
    TYPE NAME EQUALS LCURLY name_list RCURLY SEMICOLON { Type(String.lowercase $2, $5) }
  | TYPE NAME EQUALS LCURLY RCURLY SEMICOLON { Type(String.lowercase $2, []) }
  ;
  name_list:
      NAME { [String.uppercase $1] }
    | NAME COMMA name_list { (String.uppercase $1) :: $3 }
  ;
  clause:
      PLUS NAME LPAREN term_list RPAREN COLON_HYPHEN atom_list SEMICOLON { Clause(Signature(Plus, "", String.lowercase $2, $4), $7) }
    | MINUS NAME LPAREN term_list RPAREN COLON_HYPHEN atom_list SEMICOLON { Clause(Signature(Minus, "", String.lowercase $2, $4), $7) }
    | HELPER NAME LPAREN term_list RPAREN COLON_HYPHEN atom_list SEMICOLON { Clause(Signature(Helper, "", String.lowercase $2, $4), $7) }
    | HELPER NAME LPAREN RPAREN COLON_HYPHEN atom_list SEMICOLON { Clause(Signature(Helper, "", String.lowercase $2, []), $6) }
    | ACTION NAME LPAREN term_list RPAREN COLON_HYPHEN atom_list SEMICOLON { Clause(Signature(Action, "", String.lowercase $2, $4) ,$7) }
  ;
  term_list:
      term { [$1] }
    | term COMMA term_list { $1 :: $3 }
  ;
  term:
      NAME { Variable(String.uppercase $1, Term_defer("")) }
    | NUMBER { Constant([$1], raw_type) }
    | DOUBLEQUOTE NAME DOUBLEQUOTE { Constant([$2], raw_type) (* WHAT IF THERE ARE SPACES? use String.map (fun c -> if c = ' ' then '_' else c) maybe? *)} 
    | NAME PERIOD NAME { Field_ref(String.uppercase $1, String.uppercase $3) }
    | NAME COLON NAME { Variable(String.uppercase $1, Term_defer(String.lowercase $3)) }
  ;
  atom:
      term EQUALS term { Equals(true, $1, $3) }
    | NOT term EQUALS term { Equals(false, $2, $4) }
    | NAME LPAREN term_list RPAREN { Apply(true, "", String.lowercase $1, $3) }
    | NOT NAME LPAREN term_list RPAREN { Apply(false, "", String.lowercase $2, $4) }
    | NAME LPAREN RPAREN { Apply(true, "", String.lowercase $1, []) }
    | NOT NAME LPAREN RPAREN { Apply(false, "", String.lowercase $2, []) }
    | NAME PERIOD NAME LPAREN term_list RPAREN { Apply(true, (String.lowercase $1), (String.lowercase $3), $5) }
    | NAME PERIOD NAME LPAREN RPAREN { Apply(false, (String.lowercase $1), (String.lowercase $3), []) }
    | NOT NAME PERIOD NAME LPAREN term_list RPAREN { Apply(false, (String.lowercase $2), (String.lowercase $4), $6) }
    | NOT NAME PERIOD NAME LPAREN RPAREN { Apply(false, (String.lowercase $2), (String.lowercase $4), []) }
    | BOOLEAN { Bool($1) }
    | NOT BOOLEAN { Bool(not $2) }
  ;
  atom_list:
      atom { [$1] }
    | atom COMMA atom_list { $1 :: $3 }
  ; 