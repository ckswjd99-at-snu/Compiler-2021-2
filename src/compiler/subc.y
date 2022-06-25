%{
/*
 * File Name   : subc.y
 * Description : a skeleton bison input
 */

#include "subc.h"
#include "subc.tab.h"

int    yylex ();
int    yyerror (char* s);
void 	REDUCE(char* s);
void print_errormsg(char *s);

int string_count = 0;
int label_count = 0;
int if_count = 0;
int loop_count = 0;
int loop_now = 0;
%}

/* yylval types */
%union {
	int		intVal;
	char	charVal;
	char	*stringVal;
	id		*idptr;
	decl	*declptr;
	ste		*steptr;
}

/* Precedences and Associativities */
%left	','
%right	'='	
%left 	LOGICAL_OR
%left 	LOGICAL_AND
%left 	'&'
%left 	EQUOP
%left 	RELOP
%left 	'+' '-'
%left 	'*' 
%right 	'!' INCOP DECOP
%left 	'[' ']' '(' ')' '.' STRUCTOP

%nonassoc IFONLY
%nonassoc ELSE

/* Token and Types */

%type<intVal> pointers if_expr
%type<declptr> def def_list ext_def ext_def_list local_defs and_expr and_list args or_expr or_list
%type<declptr> func_decl param_decl param_list type_specifier struct_specifier binary unary const_expr expr expr_e

%token READINT READCHAR WRITEINT WRITESTR WRITECHAR
%token<idptr> TYPE STRUCT RETURN IF ELSE WHILE FOR BREAK CONTINUE
%token<stringVal> LOGICAL_OR LOGICAL_AND INCOP DECOP STRUCTOP
%token<idptr> VOID
%token<stringVal> STRING
%token<charVal> CHAR_CONST
%token<idptr> ID
%token<intVal> INTEGER_CONST
%token<intVal> RELOP EQUOP
 

%%
program
		: {
			fprintf(outfile, "\tshift_sp 1\n");
			fprintf(outfile, "\tpush_const EXIT\n");
			fprintf(outfile, "\tpush_reg fp\n");
			fprintf(outfile, "\tpush_reg sp \n");
			fprintf(outfile, "\tpop_reg fp\n");
			fprintf(outfile, "\tjump main\n");

			fprintf(outfile, "EXIT:\n");
			fprintf(outfile, "\texit\n");
		} ext_def_list {
			int temp_lglob_size = ssetop->size;
			fprintf(outfile, "Lglob.\tdata %d\n", temp_lglob_size);
		}
;

ext_def_list
		: ext_def_list ext_def { }
		| /* empty */ { }
;

ext_def
		: type_specifier pointers ID ';'{
			if($1 && $3) {
				if(find($3)) {
					$$ = NULL;
					print_errormsg("redeclaration");
				}
				else {
					if(!$2) declare($3, makevardecl($1)); 
					else declare($3, makevardecl(makeptrdecl($1)));
				}
			}

		}

		| type_specifier pointers ID '[' const_expr ']' ';'{
			if($1 && $3 && $5) {
				if(find($3)) {
					print_errormsg("redeclaration");
					$$ = NULL;
				}
				else {
					decl* temp = $2 ? makeptrdecl($1) : $1;
					declare($3,makeconstdecl(makearraydecl($5,makevardecl(temp))));
				}
			}
		}
		| func_decl ';' { pop_scope(); }
		| type_specifier ';'{ }
		| func_decl { 
			function_type_all = function_type; 
			function_decl = $1;
			function_ste = find_ste_in_global($1);
			fprintf(outfile, "%s:\n", function_ste->name->name);
		} function_compound_stmt { 
			pop_scope(); 

			// end up code and final position
			fprintf(outfile, "%s_final:\n", function_ste->name->name);
			fprintf(outfile, "\tpush_reg fp\n");
			fprintf(outfile, "\tpop_reg sp\n");
			fprintf(outfile, "\tpop_reg fp\n");
			fprintf(outfile, "\tpop_reg pc\n");
			fprintf(outfile, "%s_end:\n", function_ste->name->name);
		}
; 

type_specifier
		: TYPE { $$ = find($1); }
		| VOID { $$ = find($1); }
		| struct_specifier { $$ = $1; }
;

struct_specifier
		: STRUCT ID '{' {
				push_scope();
				if(find($2)) {
					$<declptr>$ = NULL;
					print_errormsg("redeclaration");
				}
			}
			def_list '}' {
				ste* fields = pop_scope();
				if($2 == NULL) $$ = NULL;
				else {
					if(find($2)) $$ = NULL;
					else{
						$$ = makestructdecl(fields);
						declare_struct($2, $$);
					}
				}
		}

		| STRUCT ID {
			if($2 == NULL)  $$ = NULL;
			else{
				if(find($2)){
					if(check_is_struct_type(find($2))){
						$$ = find($2);
					}
					else {
						$$ = NULL;
						print_errormsg("not declared");
					}
				}
				else {
					$$ = NULL;
					print_errormsg("incomplete type");
				}
			}
		}	
;

func_decl
		: type_specifier pointers ID '(' ')'
		{
			function_type = $1;
			
			if($1 && $3) {
				if(find_currentscope($3)){
					push_scope();
					$$ = NULL;
					print_errormsg("redeclaration");
				}
				else {
					decl* proc = makeprocdecl();
					declare($3,proc);
					push_scope();

					if(!$2) declare(returnid,$1);
					else {
						decl* temptype = (decl*)malloc(sizeof(decl));
						temptype->declclass = _TYPE;
						temptype->typeclass = _POINTER;
						temptype->ptrto = $1;
						temptype->size = 1;

						declare(returnid,temptype);
					}

					ste* formal = pop_scope();
					
					if(proc && formal){
						proc->formals = formal->prev;
						proc->returntype = formal;
					}

					push_scope();
					push_stelist(formal);
					$$ = proc;
				}				
			}
			else {
				push_scope();
				$$ = NULL;				
			}
		}
		| type_specifier pointers ID '(' VOID ')' {
			function_type = $1;
			if($1 && $3){
				if(find_currentscope($3)){
					push_scope();
					$$ = NULL;
					print_errormsg("redeclaration");
				}
				else {
					decl* proc = makeprocdecl();
					declare($3,proc);
					push_scope();

					if(!$2) declare(returnid,$1);
					else {
						decl* temptype = (decl*)malloc(sizeof(decl));
						temptype->declclass = _TYPE;
						temptype->typeclass = _POINTER;
						temptype->ptrto = $1;
						temptype->size = 1;

						declare(returnid,temptype);
					}

					ste* formal = pop_scope();
					
					if(proc && formal){
						proc->formals = formal->prev;
						proc->returntype = formal;
					}
					push_scope();
					push_stelist(formal);
					$$ = proc;
				}				
			}
			else {
				push_scope();
				$$ = NULL;				
			}

		}
		| type_specifier pointers ID '(' {
				function_type = $1;
				if($1 == NULL) { push_scope(); $<declptr>$ = NULL;}
				else if($3 == NULL) { push_scope(); $<declptr>$ = NULL;}
				else {
					if(find_currentscope($3)){
						push_scope();
						$<declptr>$ = NULL;
						print_errormsg("redeclaration");
					}

					else{
						decl *func = makeprocdecl();
						declare($3, func);
						push_scope();
						decl *returntype;
						if($2) { returntype = makeptrdecl($1); }
						else { returntype = $1; }
						
						declare(returnid, returntype);
						$<declptr>$ = func;
					}
				}
				
				
			}
			 param_list ')'
			{
				decl* func = $<declptr>5;
				int ssize = ssetop->size;
				if(func==NULL){ 
						pop_scope();
						$$ = NULL; 
						push_scope();
				}
				else{
					ste* formal = pop_scope();

					if(func && formal){
						func->formals = formal->prev;
						func->returntype = formal;
					}
					push_scope();
					ssetop->size = ssize;
					push_stelist(formal);
					$$ = func;
				}
			}
;

pointers
		: '*'{
			$$ = 1;
		}
		| /* empty */ {
			$$ = 0;
		}
;

param_list
		: param_decl{
			$$ = $1;
		}
		| param_list ',' param_decl{
		}
;

param_decl
		: type_specifier pointers ID {
			if($1 && $3){
				if(find_currentscope($3)) {
					$$ =  NULL;
					print_errormsg("redeclaration");
				}
				else {
					if(!$2) declare($3, makevardecl($1)); 
					else declare($3, makevardecl(makeptrdecl($1)));
				}				
			}
			else { $$ = NULL; }			
		}
		| type_specifier pointers ID '[' const_expr ']'{
			if($1 && $3 && $5) {
				if(find_currentscope($3)) {
					$$ = NULL;
					print_errormsg("redeclaration");
				}
				else {
					if(!$2) declare($3,makeconstdecl(makearraydecl($5,makevardecl($1))));
					else declare($3,makeconstdecl(makearraydecl($5,makevardecl(makeptrdecl($1)))));
				}
			}
			else { $$ = NULL; }
		}
;

def_list
		: def_list def { }
		| /* empty */ { $$ = NULL; }
;

def
		: type_specifier pointers ID ';' {
			if($1 && $3) {
				if(find_currentscope($3)) {
					$$ = NULL;
					print_errormsg("redeclaration");
				}
				else {
					decl* temp = $2 ? makeptrdecl($1) : $1;
					declare($3, makevardecl(temp));
				}				
			}
			else { $$ = NULL; }		
		}

		| type_specifier pointers ID '[' const_expr ']' ';' {
			if($1 && $3 && $5) {
				if(find_currentscope($3)) {
					$$ = NULL;
					print_errormsg("redeclaration");
				}
				else {
					decl* temp = $2 ? makeptrdecl($1) : $1;
					declare($3,makeconstdecl(makearraydecl($5,makevardecl(temp))));
				}
			}
			else {
				$$ = NULL;
			}
		}

		| type_specifier ';' { $$ = $1; }

		| func_decl ';' {
			$$ = $1;
			pop_scope();
		}
;

compound_stmt
		: '{' { 
			push_scope(); 
		} local_defs {
			fprintf(outfile, "\tshift_sp %d\n", ssetop->size);
			$<intVal>$ = ssetop->size;
		} stmt_list '}' { 
			pop_scope(); 
			fprintf(outfile, "\tshift_sp -%d\n", $<intVal>4);
		}
;

function_compound_stmt
		: '{' local_defs {
			int formal_size = size_of_formals(function_decl->formals);
			fprintf(outfile, "\tshift_sp %d\n", ssetop->size-formal_size);
			fprintf(outfile, "%s_start:\n", function_ste->name->name);
		} stmt_list '}' { }
;

local_defs
		:	def_list { $$ = $1; }
;

stmt_list
		: stmt_list stmt { }
		| /* empty */ { }
;

stmt
		: expr ';' {
			// if address, make it value
			// then shift -1
			if($1 != NULL && $1->declclass == _VAR && $1->type->typeclass != _STRUCT) fprintf(outfile, "\tfetch\n");
			if($1 != NULL) {
				if($1->type->typeclass == _STRUCT && $1->longdata) pop_struct_value($1);
				else fprintf(outfile, "\tshift_sp -1\n");
			}
		}
		| compound_stmt { }
		| RETURN ';' {
			if(find_currentscope(returnid)){
				if(find_currentscope(returnid) != voidtype) print_errormsg("incompatible return types");
			}
			else{
				if(function_type_all != voidtype) print_errormsg("incompatible return types");
			}

			fprintf(outfile, "\tjump %s_final\n", function_ste->name->name);
		}
		| RETURN {
			// push return value address
			fprintf(outfile, "\tpush_reg fp\n");
			fprintf(outfile, "\tpush_const -%d\n", function_decl->returntype->decl->size+1);
			fprintf(outfile, "\tadd\n");
		} expr ';' {
			if($3 != NULL) {
				if(find_currentscope(returnid)){
					if($3->declclass == _NULL){
						if(!(find_currentscope(returnid)->typeclass == _POINTER)) print_errormsg("incompatible return types");
					}
					else if(!check_compatible_type(find_currentscope(returnid), $3->type)) print_errormsg("incompatible return types");
					
				}
				else{
					if(!check_compatible_type(function_type_all, $3->type)) print_errormsg("incompatible return types");
				}
			}
			assign_bulk($3);

			fprintf(outfile, "\tjump %s_final\n", function_ste->name->name);
		}
		| ';' { }
		
		| if_expr stmt { 
				int if_num = $1;
				fprintf(outfile, "ifnot_%d:\n", if_num);
			} %prec IFONLY
		| if_expr stmt ELSE {
				int if_num = $1;
				fprintf(outfile, "\tjump ifend_%d\n", if_num);
				fprintf(outfile, "ifnot_%d:\n", if_num);
			} stmt { 
				int if_num = $1;
				fprintf(outfile, "ifend_%d:\n", if_num);
			}
		| WHILE {
				$<intVal>$ = loop_now;	// store prev loop id
				loop_now = ++loop_count;
				fprintf(outfile, "loop_start_%d:\n", loop_now);
			} '(' expr {
				if($4->declclass == _VAR) fprintf(outfile, "\tfetch\n");
				fprintf(outfile, "\tbranch_false loop_end_%d\n", loop_now);

			} ')' stmt { 
				fprintf(outfile, "loop_last_%d:\n", loop_now);
				fprintf(outfile, "\tjump loop_start_%d\n", loop_now);
				fprintf(outfile, "loop_end_%d:\n", loop_now);
				loop_now = $<intVal>2;
			}
		| FOR {
				$<intVal>$ = loop_now;	// store prev loop id
				loop_now = ++loop_count;
			} '(' expr_e ';' {
				if($4->declclass == _VAR) fprintf(outfile, "\tfetch\n");
				fprintf(outfile, "\tshift_sp -1\n");
				fprintf(outfile, "loop_start_%d:\n", loop_now);
			} expr_e ';' {
				if($4->declclass == _VAR) fprintf(outfile, "\tfetch\n");
				fprintf(outfile, "\tbranch_false loop_end_%d\n", loop_now);
				fprintf(outfile, "\tjump loop_body_%d\n", loop_now);
				fprintf(outfile, "loop_last_%d:\n", loop_now);
			} expr_e ')' {
				if($4->declclass == _VAR) fprintf(outfile, "\tfetch\n");
				fprintf(outfile, "\tjump loop_start_%d\n", loop_now);
				fprintf(outfile, "loop_body_%d:\n", loop_now);
			} stmt { 
				fprintf(outfile, "\tjump loop_last_%d\n", loop_now);
				fprintf(outfile, "loop_end_%d:\n", loop_now);
				loop_now = $<intVal>2;
			}
		| BREAK ';' { 
			fprintf(outfile, "\tjump loop_end_%d\n", loop_now);
		}
		| CONTINUE ';' { 
			fprintf(outfile, "\tjump loop_last_%d\n", loop_now);
		}
		/* TODO: I/O FUNC */
		| READINT '(' unary ')' { }
		| READCHAR '(' unary ')' { }
		| WRITEINT '(' unary ')' { 
			if($3->declclass == _VAR) fprintf(outfile, "\tfetch\n");
			fprintf(outfile, "\twrite_int\n");
		}
		| WRITECHAR '(' unary ')' { 
			if($3->declclass == _VAR) fprintf(outfile, "\tfetch\n");
			fprintf(outfile, "\twrite_char\n");
		}
		| WRITESTR '(' unary ')' { 
			if($3->declclass == _VAR) fprintf(outfile, "\tfetch\n");
			fprintf(outfile, "\twrite_string\n");
		}
;

if_expr
	: IF '(' expr ')' {
		if($3->declclass = _VAR) fprintf(outfile, "\tfetch\n");
		fprintf(outfile, "\tbranch_false ifnot_%d\n", if_count);
		fprintf(outfile, "if_%d:\n", if_count); 
		$$ = if_count++;
	}

expr_e
		: expr { $$ = $1; }
		| /* empty */ { 
			// consider it as true or false?
			$$ = makeconstdecl(inttype); 
			fprintf(outfile, "\tpush_const 1\n");
		}
;

const_expr
		: expr { 
			$$ = $1; 
			if($1 != NULL && $1->declclass == _VAR) fprintf(outfile, "\tfetch\n");
			if($1 != NULL) fprintf(outfile, "\tshift_sp -1\n");
		}
;

expr
		: unary {
			// address of unary will be on stack top
				fprintf(outfile, "\tpush_reg sp\n");
				fprintf(outfile, "\tfetch\n");
			} '=' expr{
				if(!$1 || !$4) $$ = NULL;				
				else if(!check_is_var($1)) {
					$$ = NULL;
					print_errormsg("LHS is not a variable");
				}
				else if($4->declclass == _NULL) {
					if($1->type->typeclass == _POINTER) $$ = $1;
					else{
						$$ = NULL;
						print_errormsg("RHS is not a const or variable");
					}
				}
				else if(!(check_is_var($4) || check_is_const($4) || check_is_expr($4)) && $4->type->typeclass != _ARRAY){
					$$ = NULL;
					print_errormsg("RHS is not a const or variable");	
				}
				else if(!check_compatible_type($1->type, $4->type)){
					$$ = NULL;
					print_errormsg("LHS and RHS are not same type");
				}
				else {
					$$ = $1;
					if($1 != NULL && $4->declclass == _VAR) fprintf(outfile, "\tfetch\n");
					if($1 != NULL) {
						assign_bulk($1);
					}
				}
		}
		| or_expr { $$ = $1; }
;

or_expr
		: or_list { $$ = $1; }
;

or_list
		: or_list LOGICAL_OR and_expr {
			if($1 == NULL || $3 == NULL) $$ = NULL;
			else if($1->type != inttype || $3->type != inttype) {
				$$ = NULL;
				print_errormsg("not computable");
			}
			else {
				$$ = makevardecl(inttype);
				$$->declclass = _CONST;

				$$->int_value = $1->int_value || $3->int_value;
				fprintf(outfile, "\tor\n");
			}
		}
		| and_expr { $$ = $1; }
;

and_expr
		: and_list { $$ = $1; }
;

and_list
		: and_list LOGICAL_AND binary {
			if($1 == NULL || $3 == NULL) $$ = NULL;
			else if($1->type != inttype || $3->type != inttype) {
				$$ = NULL;
				print_errormsg("not computable");
			}
			else {
				$$ = makevardecl(inttype);
				$$->declclass = _CONST;

				$$->int_value = $1->int_value && $1->int_value;
				fprintf(outfile, "\tand\n");
			}
		}
		| binary { $$ = $1; }
;

binary
		: binary RELOP binary {
			disable_error_temp = 0;
			if($1 == NULL || $3 == NULL) $$ = NULL;
			else if($1->type != inttype && $1->type != chartype) {
				print_errormsg("not comparable");
				$$ = NULL;
			}
			else if($3->type != inttype && $3->type != chartype) {
				print_errormsg("not comparable");
				$$ = NULL;
			}
			else if($1->type != $3->type) {
				print_errormsg("not comparable");
				$$ = NULL;
			}
			else {
				$$ = makevardecl(inttype);
				$$->declclass = _CONST;
				switch($2) {
					case RELOP_RG: {
						$$->int_value = $1->int_value < $3->int_value;
						fprintf(outfile, "\tless\n");
						break;
					}
					case RELOP_RGE: {
						$$->int_value = $1->int_value <= $3->int_value;
						fprintf(outfile, "\tless_equal\n");
						break;
					}
					case RELOP_LG: {
						$$->int_value = $1->int_value > $3->int_value;
						fprintf(outfile, "\tgreater\n");
						break;
					}
					case RELOP_LGE: {
						$$->int_value = $1->int_value >= $3->int_value;
						fprintf(outfile, "\tgreater_equal\n");
						break;
					}
				}
			}
		}
		| binary EQUOP binary {
			disable_error_temp = 0;
			if($1 == NULL || $3 == NULL) $$ = NULL;
			else if(($1->type != NULL && $1->type->typeclass == _POINTER) && ($3->type != NULL && $3->type->typeclass == _POINTER)) {
				if($1->type->ptrto != $3->type->ptrto) {
					$$ = NULL;
					print_errormsg("not comparable");
				}
				else {
					$$ = makevardecl(inttype);
					$$->declclass = _CONST;
					switch($2) {
						case EQUOP_EQUAL: {
							$$->int_value = $1->int_value == $3->int_value;
							fprintf(outfile, "\tequal\n");
							break;
						}
						case EQUOP_NOTEQ: {
							$$->int_value = $1->int_value != $3->int_value;
							fprintf(outfile, "\tnot_equal\n");
							break;
						}
					}
				}
			}
			else if($1->type != $3->type) {
				$$ = NULL;
				print_errormsg("not comparable");
			}
			else if($1->type != inttype && $1->type != chartype){
				$$ = NULL;
				print_errormsg("not comparable"); 
				
			}
			else if($3->type != inttype && $3->type != chartype){
				$$ = NULL;
				print_errormsg("not comparable"); 
			}
			else {
				$$ = makevardecl(inttype);
				$$->declclass = _CONST;
				switch($2) {
					case EQUOP_EQUAL: {
						$$->int_value = $1->int_value == $3->int_value;
						fprintf(outfile, "\tequal\n");
						break;
					}
					case EQUOP_NOTEQ: {
						$$->int_value = $1->int_value != $3->int_value;
						fprintf(outfile, "\tnot_equal\n");
						break;
					}
				}
			}
		}
		| binary '+' binary {
			disable_error_temp = 0;
			if($1 == NULL || $3 == NULL) $$ = NULL;
			else if($1->type != inttype || $3->type != inttype) {
				print_errormsg("not computable");
				$$ = NULL;
			}
			else {
				$$ = copydecl($1);
				$$->declclass = _CONST;

				$$->int_value = $1->int_value + $3->int_value;
				fprintf(outfile, "\tadd\n");
			}
		}

		| binary '-' binary {
			disable_error_temp = 0;
			if($1 == NULL || $3 == NULL) $$ = NULL;
			else if($1->type != inttype || $3->type != inttype) {
				print_errormsg("not computable");
				$$ = NULL;
			}
			else {
				$$ = copydecl($1);
				$$->declclass = _CONST;

				$$->int_value = $1->int_value - $3->int_value;
				fprintf(outfile, "\tsub\n");
			}
		}
		| unary %prec '=' { 
			// if address, change into value
			$$ = copydecl($1);
			if($$->declclass == _VAR) {
				$$->declclass = _EXP;
				// DIFF
				if($$->type->typeclass == _STRUCT && !$$->longdata) fetch_struct_value($$);
				else fprintf(outfile, "\tfetch\n");
				$$->prev_declclass = $$->declclass;
				if($$->declclass == _VAR) $$->declclass = _EXP;
			}
		}

unary
		: '(' expr ')' { $$ = $2; }
		| '(' unary ')' { $$ = $2; }
		| INTEGER_CONST { 
			$$ = makeconstdecl(findste(inthash)->decl); 
			$$->int_value = $1;

			fprintf(outfile, "\tpush_const %d\n", $1);
		}
		| CHAR_CONST { 
			$$ = makeconstdecl(findste(charhash)->decl); 

			fprintf(outfile, "\tpush_const %d\n", $1);
		}
		| STRING {
			id* temp = charhash;	
			ste* typeste = findste(temp);
			decl* typedecl = typeste->decl;

			$$ = makevardecl(makeptrdecl(typedecl));
			$$->declclass = _EXP; 

			fprintf(outfile, "\tstr_%d. string %s\n", string_count, $1);
			fprintf(outfile, "\tpush_const str_%d\n", string_count++);
		}
		| ID {
			if(find($1)){

				ste* id_ste = findste($1);
				if(id_ste->decl->declclass == _FUNC) {
					$$ = id_ste->decl;
				}
				else {
					$$ = copydecl(id_ste->decl);
				}

				if($$->declclass != _FUNC) {
					// load variable address
					int isGlobal = is_global(id_ste->decl);
					if(isGlobal) {
						fprintf(outfile, "\tpush_const Lglob+%d\n", $$->offset);
					}
					else {
						fprintf(outfile, "\tpush_reg fp\n");
						fprintf(outfile, "\tpush_const %d\n", $$->offset+1);
						fprintf(outfile, "\tadd\n");
					}
				}
			}
			else {
				$$ = NULL;
				print_errormsg("not declared");				
			}
		}

		| '-' unary	%prec '!' {
			if($2 == NULL) $$ = NULL;
			else if($2->type != inttype){
				$$ = NULL;
				print_errormsg("not computable");
			}
			else if(!(check_is_var($2) || check_is_const($2) || check_is_expr($2))){
				$$ = NULL;
				print_errormsg("not computable");
			}
			else{
				$$ = copydecl($2);
				if(!check_is_const($$)) $$->declclass = _EXP; 
				else {
					$$->int_value = $$->int_value * (-1);
				}

				if($2->declclass == _VAR) fprintf(outfile, "\tfetch\n");
				fprintf(outfile, "\tnegate\n");
			}
		}

		| '!' unary {
			if($2 == NULL) $$ = NULL;
			else if($2->type != inttype){
				$$ = NULL;
				print_errormsg("not computable");
			}
			else if(!(check_is_var($2) || check_is_const($2) || check_is_expr($2))){
				$$ = NULL;
				print_errormsg("not computable");
			}
			
			else{
				$$ = copydecl($2);
				if(!check_is_const($$)) $$->declclass = _EXP; 
				else $$->int_value = !($$->int_value);

				if($2->declclass == _VAR) fprintf(outfile, "\tfetch\n");
				fprintf(outfile, "\tnot\n");
			}
		}

		| unary INCOP {
			// unary pushes its address at stack top
			if($1 == NULL) $$ = NULL;
			else {
				int typecheck = $1->type == inttype || $1->type == chartype;
				int varcheck = check_is_var($1);
				if(typecheck && varcheck) {
					$$ = $1;
					$$->declclass = _EXP;

					// stack: unary_addr
					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr

					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value unary_addr

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value unary_addr unary_value
					
					fprintf(outfile, "\tpush_const 1\n");
					fprintf(outfile, "\tadd\n");
					// stack: unary_addr unary_value unary_addr unary_value+1
					
					fprintf(outfile, "\tassign\n");
					// stack: unary_addr unary_value

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					// stack: unary_addr unary_value #-2

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value #-2 unary_value 

					fprintf(outfile, "\tassign\n");
					// stack: unary_value unary_value
					fprintf(outfile, "\tshift_sp -1\n");
					// stack: unary_value
				}
				else {
					if(!typecheck || !varcheck) print_errormsg("not computable");
					$$ = NULL;
				}
			}
		}

		| unary DECOP {
			if($1 == NULL) $$ = NULL;
			else {
				int typecheck = $1->type == inttype || $1->type == chartype;
				int varcheck = check_is_var($1);
				if(typecheck && varcheck) {
					$$ = $1;
					$$->declclass = _EXP;

					// stack: unary_addr
					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr

					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value unary_addr

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value unary_addr unary_value
					
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					// stack: unary_addr unary_value unary_addr unary_value-1
					
					fprintf(outfile, "\tassign\n");
					// stack: unary_addr unary_value

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					// stack: unary_addr unary_value #-2

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_value #-2 unary_value 

					fprintf(outfile, "\tassign\n");
					// stack: unary_value unary_value
					fprintf(outfile, "\tshift_sp -1\n");
					// stack: unary_value
				}
				else {
					if(!typecheck || !varcheck) print_errormsg("not computable");
					$$ = NULL;
				}
			}
		}
		| INCOP unary {
			if($2 == NULL) $$ = NULL;
			else {
				int typecheck = $2->type == inttype || $2->type == chartype;
				int varcheck = check_is_var($2);
				if(typecheck && varcheck) {
					$$ = $2;
					$$->declclass = _EXP;

					// stack: unary_addr
					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr
					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr unary_addr
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr unary_value
					fprintf(outfile, "\tpush_const 1\n");
					fprintf(outfile, "\tadd\n");
					// stack: unary_addr unary_addr unary_value+1
					fprintf(outfile, "\tassign\n");
					// stack: unary_addr
					fprintf(outfile, "\tfetch\n");
					// stack: unary_value(updated)
				}
				else {
					if(!typecheck || !varcheck) print_errormsg("not computable");
					$$ = NULL;
				}
			}
		}

		| DECOP unary {
			if($2 == NULL) $$ = NULL;
			else {
				int typecheck = $2->type == inttype || $2->type == chartype;
				int varcheck = check_is_var($2);
				if(typecheck && varcheck) {
					$$ = $2;
					$$->declclass = _EXP;

					// stack: unary_addr
					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr
					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr unary_addr
					fprintf(outfile, "\tfetch\n");
					// stack: unary_addr unary_addr unary_value
					fprintf(outfile, "\tpush_const -1\n");
					fprintf(outfile, "\tadd\n");
					// stack: unary_addr unary_addr unary_value-1
					fprintf(outfile, "\tassign\n");
					// stack: unary_addr
					fprintf(outfile, "\tfetch\n");
					// stack: unary_value(updated)
				}
				else {
					if(!typecheck || !varcheck) print_errormsg("not computable");
					$$ = NULL;
				}
			}
		}

		| '&' unary	%prec '!' {
			if($2==NULL) $$ = NULL;
			else if(!check_is_var($2)) {
				$$ = NULL;
				print_errormsg("not a variable");
			}
			else {
				decl* temp = makevardecl(makeptrdecl($2->type));
				$$ = temp;
				$$->declclass = _EXP;
			}
		}

		| '*' unary	%prec '!' {
			if($2==NULL) $$ = NULL;
			else if(!check_is_pointer($2)){
				$$ = NULL;
				print_errormsg("not a pointer");
			}
			else{
				decl* temp = makevardecl($2->type->ptrto);
				$$ = temp;
				$$->declclass = _VAR;

				if($2->declclass != _EXP) fprintf(outfile, "\tfetch\n");
			}
		}

		| unary '[' expr ']' {
			if($1 == NULL) $$ = NULL;
			else if($3 == NULL) $$ = NULL;
			else if(!check_is_array($1)) {
				$$ = NULL;
				print_errormsg("not an array type"); 
			}
			else {
				decl* temp = copydecl($1->type->elementvar);
				$$ = temp;
				$$->declclass = _VAR;
				$$->offset = $1->offset + $3->int_value * $$->size;

				if($3->declclass = _VAR) fprintf(outfile, "\tfetch\n");
				fprintf(outfile, "\tpush_const %d\n", $$->size);
				fprintf(outfile, "\tmul\n");
				fprintf(outfile, "\tadd\n");
			}
		}

		| unary '.' ID {
			if($1 == NULL) $$ = NULL;
			else if($3 == NULL) $$ = NULL;
			else if(!check_is_struct($1)) {
				$$ = NULL;
				print_errormsg("not a struct");
			}
			else{
				ste* field = findste_field($1->type->fieldlist, $3);
				if(field == NULL) {
					$$ = NULL;
					print_errormsg("struct not have same name field");
				}
				else {
					$$ = copydecl(field->decl);
					if($1->longdata) {
						$$->declclass = _EXP;
						int str_size = $1->size;
						int offset = $$->offset;

						fprintf(outfile, "\tpush_reg sp\n");
						fprintf(outfile, "\tpush_const %d\n", str_size-1);
						fprintf(outfile, "\tsub\n");
						// push origin address

						fprintf(outfile, "\tpush_reg sp\n");
						fprintf(outfile, "\tpush_const %d\n", -str_size+offset);
						fprintf(outfile, "\tadd\n");
						fprintf(outfile, "\tfetch\n");
						// get struct value

						fprintf(outfile, "\tassign\n");
						fprintf(outfile, "\tshift_sp %d\n", -str_size+1);
						// assing and flush struct value
					}
					else {
						fprintf(outfile, "\tpush_const %d\n", $$->offset);
						fprintf(outfile, "\tadd\n");
					}
					
				}
			}
		}

		| unary STRUCTOP ID {
			if($1 == NULL) $$ = NULL;
			else if($3 == NULL) $$ = NULL;
			else if(!check_is_pointer($1)) {
				$$ = NULL;
				print_errormsg("not a struct pointer");
			}
			else{
				decl* strtype = $1->type->ptrto;
				if(!check_is_struct_type(strtype)) {
					$$ = NULL;
					print_errormsg("not a struct pointer");
				}
				else{
					ste* field = findste_field(strtype->fieldlist, $3);
					if(field == NULL) {
						$$ = NULL;
						print_errormsg("struct not have same name field");
					}
					else {
						$$ = copydecl(field->decl);

						if($1->declclass == _VAR) fprintf(outfile, "\tfetch\n");
						fprintf(outfile, "\tpush_const %d\n", $$->offset);
						fprintf(outfile, "\tadd\n");
					}

				}
			}

		}
		| unary '(' {
			// caller's resp.
			fprintf(outfile, "\tshift_sp %d\n", $1->returntype->decl->size); // return value space
			fprintf(outfile, "\tpush_const label_%d\n", label_count); // return pc
			fprintf(outfile, "\tpush_reg fp\n"); // prev fp
			$<intVal>$ = label_count++;
		} args ')' {
			if($1 == NULL) $$ = NULL;
			else if($4 == NULL) $$ = NULL;
			else if($1->declclass != _FUNC){
				$$ = NULL;
				print_errormsg("not a function");
			}
			else{
				ste* temp_formal = $1->formals;
				decl* temp_decl = $4;
				int ok = 1;
				while(1) {
					if(temp_formal->prev == NULL && temp_decl == NULL) {
						break;
					}
					if(temp_formal->prev == NULL && temp_decl != NULL) {
						ok = 0;
						break;
					}
					if(temp_formal->prev != NULL && temp_decl == NULL) {
						ok = 0;
						break;
					}
					if(!check_compatible_type(temp_formal->decl->type, temp_decl->type)) {
						ok = 0;
						break;
					}
					temp_formal = temp_formal->prev;
					temp_decl = temp_decl->next;
				}

				if(ok) {
					$$ = makevardecl($1->returntype->decl);
					$$->declclass = _EXP;
					if($1->returntype->decl->size > 1) {
						$$->longdata = 1;
					}
					int size = 0;
					decl* temp = $4;
					while(temp != NULL) {
						size += temp->size;
						temp = temp->next;
					}

					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpush_const %d\n", -size);
					fprintf(outfile, "\tadd\n");
					fprintf(outfile, "\tpop_reg fp\n"); // now fp includes actual area

					// go to function area
					fprintf(outfile, "\tjump %s\n", find_ste_in_global($1)->name->name);
					fprintf(outfile, "label_%d:\n",$<intVal>3);
				}
				else {
					print_errormsg("actual args are not equal to formal args");
					$$ = NULL;
				}
			}
		}

		| unary '(' ')' {
			if($1==NULL) $$ = NULL; 

			else if($1->declclass != _FUNC){
				$$ = NULL;
				print_errormsg("not a function");
			}
			else{
				if($1->formals->prev == NULL){
					$$ = makevardecl($1->returntype->decl);
					$$->declclass = _EXP;
					if($1->returntype->decl->size > 1) $$->longdata = 1;

					// caller's resp.
					fprintf(outfile, "\tshift_sp %d\n", $1->returntype->decl->size); // return value space
					fprintf(outfile, "\tpush_const label_%d\n", label_count); // return pc
					fprintf(outfile, "\tpush_reg fp\n"); // prev fp

					// fp set
					fprintf(outfile, "\tpush_reg sp\n");
					fprintf(outfile, "\tpop_reg fp\n");

					// go to function area
					fprintf(outfile, "\tjump %s\n", find_ste_in_global($1)->name->name);
					fprintf(outfile, "label_%d:\n", label_count);
					label_count++;
				}
				else {
					$$ = NULL;
					print_errormsg("actual args are not equal to formal args");
				}
			}
		}
;

args
		: expr{
			if($1 == NULL) $$ = NULL;
			else {
				if($1->prev_declclass == _VAR && $1->type->typeclass == _STRUCT && !$1->longdata) fetch_struct_value($1);
				$$ = copydecl($1);
				$$->declclass = _VAR;
			}
		}
		| expr ',' args{
			if($1==NULL) $$ = NULL;
			else if($3 == NULL) $$ = NULL;
			else{
				if($1->prev_declclass == _VAR && $1->type->typeclass == _STRUCT && !$1->longdata) fetch_struct_value($1);
				$$ = copydecl($1);
				$$->next = $3;
				$$->declclass = _VAR;
			}
		}
;


%%

/*  Additional C Codes here */

int    yyerror (char* s)
{
	fprintf (stderr, "%s\n", s);
}

void 	REDUCE( char* s)
{
	printf("%s\n",s);
}

void print_errormsg(char* errormessage){
	if(!disable_error_temp) printf("%s:%d: error:%s\n", filename, read_line(), errormessage);
}

