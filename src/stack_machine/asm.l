%{
#include <stdio.h>
#include <string.h>

#include "asm.h"
#include "gram.tab.h"

int lineno=1;

%}

Digit		[0-9]
Letter		[a-zA-Z_]
AlphaNum	{Letter}|{Digit}
String		"\""(([^"\\]|"\\\\"|(\\["tnbr0]))*)"\""

%%

{Letter}{AlphaNum}*	{
		id_ptr entered;
		entered=identer(ID, yytext, yyleng);
		//if(entered==NULL) fprintf(stderr,"invalid op\n");
		yylval.id=entered;
		return entered->lextype;
	}

{Digit}+	{
		yylval.intVal=strtol(yytext,NULL,0);
		return INT_CONST;
	}

{String} {
		yylval.stringVal = strdup(yytext+1);
		yylval.stringVal[strlen(yylval.stringVal)-1] = '\0';
		return STRING_CONST;
	}


[ \t]+	{ }
[\n]	{
		lineno++;
		return NEW_LINE;
	}
"."|":"|"+"|"-"	{
		return yytext[0];
	}

.	{
	fprintf(stderr,"line %d: error\n",lineno);
}

%%

int yywrap()
{
	return 1;
}

char* keyword[]={
        "negate", "not", "abs",
        "add", "sub", "mul", "div", "mod", "and", "or", "equal", "not_equal",
        "greater", "greater_equal", "less", "less_equal",
        "jump", "branch_true", "branch_false", "exit",
        "push_const", "push_reg", "pop_reg",
        "shift_sp",
        "assign", "fetch",
        "read_int", "read_char",
        "write_int", "write_char", "write_string",
        "sp", "fp", "pc",
        "data", "string",
		NULL
	};
int tokentype[]={
        NEGATE, NOT, ABS,
        ADD, SUB, MUL, DIV, MOD, AND, OR, EQUAL, NOT_EQUAL,
        GREATER, GREATER_EQUAL, LESS, LESS_EQUAL,
        JUMP, BRANCH_TRUE, BRANCH_FALSE, EXIT,
        PUSH_CONST, PUSH_REG, POP_REG,
        SHIFT_SP,
        ASSIGN, FETCH,
        READ_INT, READ_CHAR,
        WRITE_INT, WRITE_CHAR, WRITE_STRING,
        SP, FP, PC,
		DATA, STRING,
		NULL
	};

void init_stack_machine(void);
void simulate_stack_machine(void);

int main(int argc, char* argv[])
{
	int i;

	init_idHash();
	for( i=0; keyword[i] != NULL; i++ )
	{
		identer(tokentype[i], keyword[i],strlen(keyword[i]));
	}

	if(argc >= 2) yyin = fopen(argv[1],"r");
	else yyin = stdin;
	if(!yyin)
	{
		fprintf(stderr,"Can't open input stream!\n");
		exit(1);
	}

	init_stack_machine();    
	yyparse();
	simulate_stack_machine();

	fclose(yyin);
	return 0;
}

