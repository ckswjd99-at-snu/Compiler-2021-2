%{
/*
 * File Name   : subc.l
 * Description : a skeleton flex input
 */

#include "subc.h"
#include "subc.tab.h"

#include <string.h>

static int comment_depth = 0;
static int lineno = 1;

%}

/* regular definitions */
letter		[A-Za-z_]
digit		[0-9]
id		{letter}({letter}|{digit})*
integer_const	([1-9]{digit}*)|"0"


relop <|<=|>|>=
equop ==|!=

white-space		[ \t]+
special-char	\\[nt]


%x COMMENT
%%

"int" |
"char"	{
	yylval.idptr = enter(TYPE, yytext, yyleng);
	return TYPE;
}

"void"	{
	yylval.idptr = enter(VOID, yytext, yyleng);
	return VOID;
}

"struct"	{
	yylval.idptr = enter(STRUCT, yytext, yyleng);
	return STRUCT;
}

{integer_const}	{
	yylval.intVal = atoi(yytext);
	return INTEGER_CONST; 
}

"return"	{
	yylval.idptr = enter(RETURN, yytext, yyleng);
	return RETURN;
}

"if"	{
	yylval.idptr = enter(IF, yytext, yyleng);
	return IF;
}

"else"	{
	yylval.idptr = enter(ELSE, yytext, yyleng);
	return ELSE;
}

"while"	{
	yylval.idptr = enter(WHILE, yytext, yyleng);
	return WHILE;
}

"for"	{
	yylval.idptr = enter(FOR, yytext, yyleng);
	return FOR;
}

"break"	{
	yylval.idptr = enter(BREAK, yytext, yyleng);
	return BREAK;
}

"continue"	{
	yylval.idptr = enter(CONTINUE, yytext, yyleng);
	return CONTINUE;
}

"||"	{ return LOGICAL_OR; }

"&&"	{ return LOGICAL_AND; }

{relop} { 
	if(strcmp(yytext, "<") == 0) yylval.intVal = RELOP_RG;
	else if(strcmp(yytext, "<=") == 0) yylval.intVal = RELOP_RGE;
	else if(strcmp(yytext, ">") == 0) yylval.intVal = RELOP_LG;
	else if(strcmp(yytext, ">=") == 0) yylval.intVal = RELOP_LGE;
	return RELOP;
}

{equop} { 
	if(strcmp(yytext, "==") == 0) yylval.intVal = EQUOP_EQUAL;
	else if(strcmp(yytext, "!=") == 0) yylval.intVal = EQUOP_NOTEQ;
	return EQUOP; 
}

'({special-char}|[^\\'\n])'	{
	yylval.charVal = yytext[1];
	return CHAR_CONST;
}

\"({special-char}|[^\\\"\n])*\"	{
	yylval.stringVal = yytext;
	return STRING;
}

"++" { return INCOP; }

"--" { return DECOP; }

"->" { return STRUCTOP; }

{id}	{
	yylval.idptr = enter(ID, yytext, yyleng);
	return (yylval.idptr)->tokenType; 
}

","		{  return ','; }
"="		{  return '='; }

"&"		{  return '&'; }
"+"		{  return '+'; }
"-"		{  return '-'; }
"*"		{  return '*'; }

"!"		{  return '!'; }

"(" 	{  return '('; }
")" 	{  return ')'; }
"["		{  return '['; }
"]"		{  return ']'; }
"."		{  return '.'; }

"{" 	{  return '{'; }
"}" 	{  return '}'; }
";"		{  return yytext[0]; }

{white-space}
<*>\n		   ++lineno;

<INITIAL,COMMENT>"/*"	{
		   ++comment_depth;
		   BEGIN (COMMENT);
		}
<COMMENT>"*/"	   if(--comment_depth == 0) BEGIN (INITIAL);
<COMMENT>.		 {}


%%

int read_line()
{
   return lineno;
}

void init_stack() {
	sse* temp_scope = (sse*)malloc(sizeof(sse)); 
	temp_scope->prev = NULL;
	ssetop = (sse*)malloc(sizeof(sse)); 
	ssetop->prev = temp_scope;

	ste *temp_ste = (ste*)malloc(sizeof(ste));
	temp_ste->prev = NULL;
	temp_ste->decl = NULL;
	ssetop->stetop = temp_ste; 
	ssetop->prev->stetop = temp_ste;
}
   
void init_type() {
	voidtype = maketypedecl(_VOID);
	declare(enter(ID, "void", 4), voidtype);

	inttype = maketypedecl(_INT);
	declare(enter(ID, "int", 3), inttype); 

	chartype = maketypedecl(_CHAR);
	declare(enter(ID, "char", 4), chartype); 

	null = makeconstdecl(NULL);
	null->declclass = _NULL;
	declare(enter(ID, "NULL", 4), null); 

	globalste = ssetop->stetop;
	returnid = enter(ID, "*return", 7);
}

int main(int argc, char* argv[]) {

    static char *keyword[] = { "int", "char", "void", "struct", "return", "if", "else", "while", "for", "break", "continue", "NULL", 
							   "read_int", "read_char", "write_int", "write_string", "write_char", NULL };
    static int tokentype[] = { TYPE, TYPE, VOID, STRUCT, RETURN, IF, ELSE, WHILE, FOR, BREAK, CONTINUE, ID,
							   READINT, READCHAR, WRITEINT, WRITESTR, WRITECHAR, 0 };
    int i;
	inthash = enter(tokentype[0], keyword[0], strlen(keyword[0]));
	charhash = enter(tokentype[1], keyword[1], strlen(keyword[1]));
    for(i = 2; keyword[i] != NULL; i++)
        enter(tokentype[i], keyword[i], strlen(keyword[i]));

	init_stack();

	init_type();

	if(argc == 2) {
		yyin = fopen(argv[1], "r");
		filename = argv[1];
		outfilename = "out.s";
	}
	else if(argc == 3) {
		yyin = fopen(argv[1], "r");
		filename = argv[1];
		outfilename = argv[2];
	}
	else {
		yyin = stdin;
		outfilename = "out.s";
	}
	if(!yyin) {
		printf("Can't open input stream!\n");
		exit(1);
	}

	outfile = fopen(outfilename, "w");
		
	yyparse();
	fclose(yyin);
	return 0;
}
