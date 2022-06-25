#include "subc.h"
#include <stdlib.h>
#include <string.h> 

// make ste & modify stack
void declare(id* _id, decl* _decl) {
    
    ste* temp = (ste*)malloc(sizeof(ste));
    temp->name = _id;
    temp->decl = _decl;
    temp->prev = ssetop->stetop;
    ssetop->stetop = temp;

	if(_decl->declclass==_VAR || (_decl->declclass==_CONST && _decl->type->typeclass==_ARRAY)) {
		_decl->offset = offset_from_nonglobal();
		ssetop->size += _decl->size;
	}
	// printf("declared %s with size %d, offset %d\n", _id->name, _decl->size, _decl->offset);
}

//push new sse in the scope_stack
void push_scope(){
	// printf("push scope\n");
    sse* ssenew = (sse*)malloc(sizeof(sse));
    ssenew->stetop = ssetop->stetop;
    ssenew->prev = ssetop;
    ssetop = ssenew;
}

// pop upmost sse 
// and return ste in the sse 
ste* pop_scope(){
	// printf("pop scope\n");
    ste* upframe = ssetop->stetop;
    ste* downframe = ssetop->prev->stetop;
    ste* popstetop = (ste*)malloc(sizeof(ste));
    ste* iter;
    for (iter = upframe; iter != downframe; iter = upframe)
    {
        upframe = iter->prev;
        iter->prev = popstetop;
        popstetop = iter;
    }
    ssetop = ssetop->prev;
    //return ste reverse order
    return popstetop;
}


//push stelist top of the current stack
//reverse order 
void push_stelist(ste* stelist){
	if(stelist == NULL) return;

	//iterate stelist and put ste on the ssetop->stetop
	ssetop->size = 0;
	ste* iter = stelist;
	for (;iter->prev != NULL ;iter = iter->prev )
	{
		ste* push_ste = (ste*)malloc(sizeof(ste));
		memcpy(push_ste,iter,sizeof(ste));

		push_ste->prev = ssetop -> stetop;
		ssetop->stetop = push_ste;
		if(push_ste->decl->declclass==_VAR || (push_ste->decl->declclass==_CONST && push_ste->decl->type->typeclass==_ARRAY)) {
			ssetop->size += push_ste->decl->size; 
		}
	}
	
}

//make ste of declare of struct type in the globalste 
void declare_struct(id* name, decl* decl){
	ste* newste = (ste*)malloc(sizeof(ste));
	newste->name = name;
	newste->decl = decl;
	newste->prev = globalste->prev;

	globalste->prev = newste;

	globalste = newste;
}

// findste by id name
ste* findste(id* name){
	for (ste* iter = ssetop->stetop; iter != NULL ; iter = iter->prev)
	{
		if(iter->name == name) return iter;
	}
	return NULL; // not found	
}

//findste by id name in current scope 
ste* findste_currentscope(id* name){
	ste* downframe = ssetop->prev->stetop;
	for (ste* iter = ssetop->stetop ; iter != downframe ; iter = iter->prev)
	{
		if(iter->name == name) return iter;
	}
	return NULL;
}

ste* findste_field(ste* field, id* name){
	for (ste* iter = field; iter != NULL ; iter = iter->prev)
	{
		if(iter->name == name) return iter;
	}
	return NULL; // not found	
}

decl* find(id* name){
	for (ste* iter = ssetop->stetop; iter != NULL ; iter = iter->prev)
	{
		if(iter->name == name) return iter->decl;
	}
	return NULL; // not found	
}

decl* find_currentscope(id* name){
	ste* downframe = ssetop->prev->stetop;
	for (ste* iter = ssetop->stetop ; iter != downframe ; iter = iter->prev)
	{
		if(iter->name == name) return iter->decl;
	}
	return NULL;
}
decl* find_field(ste* field, id* name){
	for (ste* iter = ssetop->stetop; iter != NULL ; iter = iter->prev)
	{
		if(iter->name == name) return iter->decl;
	}
	return NULL; // not found	
}


decl* copydecl(decl* src){
	decl* temp = (decl*)malloc(sizeof(decl));
	memcpy(temp, src, sizeof(decl));
	return temp;
}


// make decl funcs 

decl* maketypedecl(int typeclass){
	decl* makedecl = (decl*)malloc(sizeof(decl));	
	makedecl->declclass = _TYPE;
	makedecl->typeclass = typeclass;
	makedecl->size = 1;
	return makedecl;
}

decl* makevardecl(decl* typedecl){
	decl* makedecl = (decl*)malloc(sizeof(decl));
	makedecl->declclass = _VAR;
	makedecl->type = typedecl;
	makedecl->size = typedecl->size;
	makedecl->longdata = 0;
	return makedecl;

}

decl* makeconstdecl(decl* typedecl){
	decl* makedecl = (decl*)malloc(sizeof(decl));
	if(typedecl == NULL) {
		makedecl->declclass = _NULL;
		makedecl->type = NULL;
		makedecl->size = 1;
		makedecl->longdata = 0;
	}
	else {
		makedecl->declclass = _CONST;
		makedecl->type = typedecl;
		makedecl->size = typedecl->size;
		makedecl->longdata = 0;
	}
	return makedecl;
}

decl* makeptrdecl(decl* ptrtodecl){
	decl* makedecl = (decl*)malloc(sizeof(decl));
	makedecl->declclass = _TYPE;
	makedecl->typeclass = _POINTER;
	makedecl->ptrto = ptrtodecl;
	makedecl->size = 1;
	makedecl->longdata = 0;
	return makedecl;
}

decl* makearraydecl(decl* const_expr_decl, decl* vardecl){
	decl* makedecl = (decl*)malloc(sizeof(decl));
	makedecl->declclass = _TYPE;
	makedecl->typeclass = _ARRAY;
	makedecl->elementvar = vardecl;
	
	//element_num
	makedecl->num_index = const_expr_decl->int_value;
	makedecl->size = makedecl->num_index * vardecl->size;
	// printf("array var %d with size %d\n", vardecl->size, makedecl->size);

	return makedecl;	
}

decl* makestructdecl(ste* fields){
	// printf("making struct decl...\n");
	decl* makedecl = (decl*)malloc(sizeof(decl));
	makedecl->declclass = _TYPE;
	makedecl->typeclass= _STRUCT;
	makedecl->fieldlist = fields;

	makedecl->size = 0;
	for(ste* elem = fields; elem->prev != NULL; elem = elem->prev) {
		// printf("elem: size %d at %p\n", elem->decl->size, elem);
		makedecl->size += elem->decl->size;
	}
	// printf("struct with size %d\n", makedecl->size);
	
	return makedecl;
	
}

decl* makeprocdecl(){
	decl* makedecl = (decl*)malloc(sizeof(decl));
	makedecl->declclass = _FUNC;
	return makedecl;
}



// added
sse* get_global_scope() {
    sse* result = ssetop;
    while(result->prev->prev != NULL) result = result->prev;
    return result;
}

ste* find_ste_in_global(decl* _decl) {
	ste* temp = get_global_scope()->stetop;
	while(temp->prev != NULL) {
		if(temp->decl == _decl) return temp;
		temp = temp->prev;
	}
	return NULL;
}

ste* find_ste_in_allscope(decl* _decl) {
	ste* temp = ssetop->stetop;
	while(temp->prev != NULL) {
		if(temp->decl == _decl) return temp;
		temp = temp->prev;
	}
	return NULL;
}

int is_global(decl* _decl) {
	ste* temp = get_global_scope()->stetop;
	while(temp->prev != NULL) {
		if(temp->decl == _decl) return 1;
		temp = temp->prev;
	}
	return 0;
}

void push_variable_addr(decl* _decl) {
    int isGlobal = is_global(_decl);
    if(isGlobal) {
        fprintf(outfile, "\tpush_const Lglob+%d\n", _decl->offset);
    }
    else {
        fprintf(outfile, "\tpush_reg fp\n");
        fprintf(outfile, "\tpush_const %d\n", _decl->offset+1);
        fprintf(outfile, "\tadd\n");
    }
}

int size_of_formals(ste* fields) {
	int size = 0;
	ste* temp = fields;
	while(temp->prev != NULL) {
		size += temp->decl->size;
		temp = temp->prev;
	}
	return size;
}


// struct adv

void fetch_struct_value(decl* _decl) {
	// stack: ... str_addr
	// how?
	// make space and move address
	// then loop fetching

	int str_size = _decl->size;

	fprintf(outfile, "\tshift_sp %d\n", str_size-1);
	fprintf(outfile, "\tpush_reg sp\n");
	fprintf(outfile, "\tpush_const %d\n", str_size-1);
	fprintf(outfile, "\tsub\n");
	fprintf(outfile, "\tfetch\n");
	// now stack: ... str_space src_addr
	

	for(int i=0; i<str_size; i++) {
		fprintf(outfile, "\tpush_reg sp\n");
		fprintf(outfile, "\tpush_const %d\n", str_size);
		fprintf(outfile, "\tsub\n");
		fprintf(outfile, "\tpush_const %d\n", i);
		fprintf(outfile, "\tadd\n");
		// now stack: ... str_space src_addr str_space_begin+i

		fprintf(outfile, "\tpush_reg sp\n");
		fprintf(outfile, "\tpush_const 1\n");
		fprintf(outfile, "\tsub\n");
		fprintf(outfile, "\tfetch\n");
		// now stack: ... str_space src_addr str_space_begin+i src_addr

		fprintf(outfile, "\tpush_const %d\n", i);
		fprintf(outfile, "\tadd\n");
		// now stack: ... str_space src_addr str_space_begin+i src_addr+i

		fprintf(outfile, "\tfetch\n");
		// now stack: ... str_space src_addr str_space_begin+i src_i_th_value

		fprintf(outfile, "\tassign\n");
		// now stack: ... str_space src_addr
	}

	// now stack: ... full_str_space src_addr
	fprintf(outfile, "\tshift_sp -1\n");
	// now stack: ... full_str_space
}

void assign_bulk(decl* _decl) {
	// stack: assign_target struct_value
	int str_size = _decl->size;
	for(int i=0; i<str_size; i++) {
		fprintf(outfile, "\tpush_reg sp\n");
		fprintf(outfile, "\tpush_const %d\n", -str_size);
		fprintf(outfile, "\tadd\n");
		fprintf(outfile, "\tfetch\n");
		// stack: assign_target struct_value assign_target
		fprintf(outfile, "\tpush_const %d\n", i);
		fprintf(outfile, "\tadd\n");
		// stack: assign_target struct_value assign_target+i
		fprintf(outfile, "\tpush_reg sp\n");
		fprintf(outfile, "\tpush_const %d\n", -str_size+i);
		fprintf(outfile, "\tadd\n");
		fprintf(outfile, "\tfetch\n");
		// stack: assign_target struct_value assign_target+i i_th_struct_value
		fprintf(outfile, "\tassign\n");
		// stack: assign_target struct_value
	}
	fprintf(outfile, "\tshift_sp %d\n", -str_size-1);
}

void pop_struct_value(decl* _decl) {
	int str_size = _decl->size;
	fprintf(outfile, "\tshift_sp %d\n", -str_size);
}

int offset_from_nonglobal() {
	sse* globalStart = get_global_scope();
	sse* temp = ssetop;
	int result = 0;
	while(1) {
		if(temp == globalStart) break;
		result += temp->size;
		temp = temp->prev;
	}
	return result;
}