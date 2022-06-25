/******************************************************
 * File Name   : subc.h
 * Description
 *    This is a header file for the subc program.
 ******************************************************/

#ifndef __SUBC_H__
#define __SUBC_H__

#include <stdio.h>
#include <string.h>

// decl classes
#define _VAR 0
#define _CONST 1
#define _FUNC 2
#define _TYPE 3
#define _EXP 4
#define _NULL 5

// type classes
#define _VOID 0
#define _INT 1
#define _CHAR 2
#define _STRING 3
#define _ARRAY 4
#define _STRUCT 5
#define _POINTER 6

/* OPCODE */
#define ADD 0
#define SUB 1
#define REL 2
#define EQU 3
#define AND 4
#define OR 5

/* RELOP CASE */
#define RELOP_RG	0
#define RELOP_RGE	1
#define RELOP_LG	2
#define RELOP_LGE	3

/* EQUOP CASE */
#define EQUOP_EQUAL	0
#define EQUOP_NOTEQ	1


/* structure for ID */
typedef struct id {
      char *name;
      int tokenType;
} id;

typedef struct ste{	// symbol table entry
	struct id *name;
	struct decl *decl;
	struct ste *prev;
} ste;

typedef struct decl{
	int declclass;
	int prev_declclass;

	struct decl *type;
	int longdata;
	
	int int_value;
	char char_value;
	
	struct ste *formals;
	struct ste *returntype; 

	int typeclass;
	struct decl *elementvar;
	int num_index;
	struct ste *fieldlist;
	struct decl *ptrto;

	int size;
	int offset;
	struct ste **scope;
	struct decl* next;

} decl;

typedef struct sse {	// scope stack element
	struct ste* stetop;
	struct sse* prev;
	int size;
} sse;

sse *ssetop;
ste* globalste;
decl * function_type;
decl * function_type_all;
decl * function_decl;
ste* function_ste;
struct id* inthash;
struct id* charhash;

decl *null;
decl *voidtype;
decl *inttype;
decl *chartype;
id* returnid;
int disable_error_temp;

char *filename;
int read_line();

char *outfilename;
FILE *outfile;

unsigned hash(char *name);
struct id *enter(int tokenType, char *name, int length);

void push_scope();
ste* pop_scope();
void push_stelist(ste* stelist);
void declare(id* name, decl* decl);
void declare_struct(id* name, decl* decl);

decl* copydecl(decl* org);

ste* findste(id* name);
ste* findste_currentscope(id* name);
ste* findste_field(ste* fields, id* name);
decl* find(id* name);
decl* find_currentscope(id* name);
decl* find_field(ste* field, id* name);

decl* maketypedecl(int typeclass);
decl* makevardecl(decl* typedecl);
decl* makeconstdecl(decl* typedecl);
decl* makeptrdecl(decl* ptrtodecl);
decl* makearraydecl(decl* const_expr_decl, decl* vardecl);
decl* makestructdecl(ste* fields);
decl* makeprocdecl();

int check_compatible_type(decl* dec1, decl* dec2);
int check_is_var(decl* dec1);
int check_is_const(decl* dec1);
int check_is_expr(decl* dec1);
int check_is_pointer(decl* dec1);
int check_is_array(decl* dec1);
int check_is_struct(decl* dec1);
int check_is_struct_type(decl* dec1);



sse* get_global_scope();
ste* find_ste_in_global(decl* _decl);
int is_global(decl* _decl);
void push_variable_addr(decl* _decl);
int size_of_formals(ste* fields);
ste* find_ste_in_allscope(decl* _decl);


void fetch_struct_value(decl* _decl);
void assign_bulk(decl* _decl);
void pop_struct_value(decl* _decl);
int offset_from_nonglobal();

#endif

