module P = Snick_parse

(* Argument parsing code *)
let infile_name = ref None

type compiler_mode = PrettyPrint | Compile
let mode = ref Compile

(* --------------------------------------------- *)
(*  Specification for command-line options       *)
(* --------------------------------------------- *)
let (speclist:(Arg.key * Arg.spec * Arg.doc) list) =
  ["-p",
     Arg.Unit(fun () -> mode := PrettyPrint),
     " Run the compiler in pretty-printer mode"
  ]

let main () =
  (* Parse the command-line arguments *)
  Arg.parse speclist
      (begin fun fname -> infile_name := Some fname end)
      "bean [-p] [bean source]" ;
  (* Open the input file *)
  let infile = match !infile_name with
  | None -> stdin
  | Some fname -> open_in fname in
  (* Initialize lexing buffer *)
  let lexbuf = Lexing.from_channel infile in
  (* Call the parser *)
  try
   let prog = Snick_parse.program Snick_lex.token lexbuf in
   match !mode with
   | PrettyPrint ->
     Snick_pprint.print_program Format.std_formatter prog
   | Compile ->
     Analyze.semantic_analysis prog;
     Codegen.generate prog;
  with
   | Snick_lex.Syntax_error msg ->
    let (ln, col) = Snick_lex.get_lex_pos lexbuf in
    Printf.fprintf stderr
      "Lexer error: %s at line %i, column %i\n" msg ln col;
    exit 1
   | Parsing.Parse_error ->
    let (ln, col) = Snick_lex.get_lex_pos lexbuf in
    Printf.fprintf stderr
      "Parse error at line %i, column %i\n" ln col;
     exit 1
let _ = main ()
