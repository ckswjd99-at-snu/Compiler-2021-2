/***************************************************************
 * File Name    : hash.c
 * Description
 *      This is an implementation file for the open hash table.
 *
 ****************************************************************/

#include "subc.h"
#include <stdio.h>
#include <stdlib.h>

#define  HASH_TABLE_SIZE   101

typedef struct nlist {
	struct nlist *next;
	id *data;
} nlist;

static nlist *hashTable[HASH_TABLE_SIZE];

void appendNList(nlist** _target, int tokenType, char* name, int length) {
	nlist* target = (nlist*)malloc(sizeof(nlist));
	target->next = NULL;
	target->data = (id*)malloc(sizeof(id));
	target->data->tokenType = tokenType;
	target->data->name = (char*)malloc(sizeof(char)*(length+1));
	memcpy(target->data->name, name, (length+1)*sizeof(char));
	target->data->name[length] = '\0';

	*_target = target;
}

id *enter(int tokenType, char *name, int length) {
	/* implementation is given here */
	
	// Hashing
	int hashIndex = 0;
	for(int i=0; i<length; i++) hashIndex += (int)name[i]*(int)name[i];
	hashIndex = hashIndex % HASH_TABLE_SIZE;
	
	if(hashTable[hashIndex] == NULL) { // Check if hashIndex exist
		appendNList(&(hashTable[hashIndex]), tokenType, name, length);
		return hashTable[hashIndex]->data;
	}
	else { // Check if name exist
		nlist* enterList = hashTable[hashIndex];
		int exist = 0;
		while(1) {
			if(strcmp(enterList->data->name, name) == 0) {
				exist = 1;
				break;
			}
			if(enterList->next == NULL) break;
			enterList = enterList->next;
		}

		if(exist) {	// name token already exist
			return enterList->data;
		}
		else {	// name token doesn't exist
			appendNList(&(enterList->next), tokenType, name, length);
			return enterList->next->data;
		}
	}

	return NULL;
}

