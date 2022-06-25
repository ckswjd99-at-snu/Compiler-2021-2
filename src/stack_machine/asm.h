#ifndef __SIM_H__
#define __SIM_H__

#include <stdio.h>
#include <strings.h>

typedef struct _id
{
	char* name;
	int lextype;
	
	int pc;		/* this is for label,
				   if this id is label, then this will have matched pc. */

	struct _id* next;
} t_id,*id_ptr;

/* For hash table */
#define  ID_HASH_TABLE_SIZE   1021

void init_idHash();
unsigned idHash(char *name);
id_ptr identer(int lextype, char *name, int length);
id_ptr idlookup(char *name);

extern int lineno;

#endif
