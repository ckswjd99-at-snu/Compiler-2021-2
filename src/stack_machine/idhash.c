#include <stdlib.h>
#include "asm.h"

t_id idHashTab[ID_HASH_TABLE_SIZE];

void init_idHash()
{
	memset(idHashTab,0,sizeof(t_id)*ID_HASH_TABLE_SIZE);
}

unsigned
idHash (char* name)
{
	unsigned int key = 0;
	int count = 0;

	while((*name) != 0)
	{
		key <<=4;
		key += *name;
		count++;
		name++;
	}

	return key%ID_HASH_TABLE_SIZE;
}

/*
 * find entry(through getPrev function) and count reference.
 * if not found, create the entry
 */
id_ptr identer (int lextype, char* name, int length)
{
	id_ptr prev, curr;
	unsigned key;

	key = idHash(name);

	curr=&(idHashTab[key]);

	if(curr->name!=NULL)
	{
		while(curr!=NULL)
		{
			if(strcmp(curr->name,name)==0) return curr;
			prev = curr;
			curr=curr->next;
		}

		curr = prev->next = (id_ptr)malloc(sizeof(t_id));
	}

	curr->next = NULL;
	curr->pc = -1;
	curr->lextype = lextype;
	curr->name = (char*)malloc(length+1);
	strcpy(curr->name, name);

	return curr;
}

/*
 * find and return id named "name"
 */
id_ptr idlookup (char* name)
{
	id_ptr curr = &(idHashTab[idHash(name)]);

	while(curr != NULL)
	{
		if(strcmp(name,curr->name)==0)
		{
			return curr;
		}
		curr = curr->next;
	}
	return NULL;
}

/*
void print_data(id* data)
{
	switch(data->tokenType)
	{
	case KEYWORD: case ID:
		fprintf(stdout,"%d,\t%s,\t%s\n",data->count, e2str[data->tokenType], data->name);
		break;
	default:
		fprintf(stdout,"\t%s,\t%s\n",e2str[data->tokenType], data->name);
	}
}
*/
