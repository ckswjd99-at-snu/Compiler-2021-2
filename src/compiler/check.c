#include "subc.h"
#include <stdio.h>

// check functions

int check_compatible_type(decl* dec1, decl* dec2) {
	if(dec1 == NULL || dec2 == NULL) return 0;
	else if(dec1 == dec2) return 1;
	else if(dec1->typeclass != dec2->typeclass) return 0;
	else if(dec1->typeclass == _POINTER) return dec1->ptrto == dec2->ptrto;
	else if(dec1->typeclass == _ARRAY) return dec1->elementvar->type->typeclass == dec2->elementvar->type->typeclass;
	else return 0;
}

int check_is_var(decl* dec1){
	if(dec1==NULL) return 0;
	return (dec1->declclass==_VAR);
}

int check_is_const(decl* dec1){
	if(dec1==NULL) return 0;
	if(dec1->type==NULL) return 0;
	if(dec1->declclass==_CONST) {
		if(dec1->type==inttype || dec1->type==chartype) return 1;
	}
	return 0;
}

int check_is_expr(decl* dec1) {
	if(dec1==NULL) return 0;
	if(dec1->declclass==_EXP) return 1;
	return 0;
}

int check_is_pointer(decl* dec1){
	if(dec1==NULL) return 0;
	if(dec1->type==NULL) return 0;
	if(dec1->type->typeclass==_POINTER) return 1;
	return 0;
}

int check_is_array(decl* dec1){
	if(dec1==NULL) return 0;
	if(dec1->type==NULL) return 0;
	if (dec1->declclass==_CONST) {
		if(dec1->type->typeclass==_ARRAY) return 1;
	}
	return 0;
}

int check_is_struct(decl* dec1){
	if(dec1==NULL) return 0;
	if(dec1->type==NULL) return 0;
	if(dec1->type->typeclass==_STRUCT) return 1;
	return 0;
}

int check_is_struct_type(decl* dec1){
	if(dec1==NULL) return 0;
	return (dec1->typeclass==_STRUCT);
}
