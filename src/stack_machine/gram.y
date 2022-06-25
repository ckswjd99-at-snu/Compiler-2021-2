%{
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "asm.h"

int yylex();
int yyerror(char* s);

struct instr_node {
	id_ptr opcode;
	struct operand* operand;
};

struct operand {
	id_ptr reg;
	id_ptr label;
	int integer;
	int is_integer_used;
};

#define STACK_SIZE (64*1024)
#define STACK_AREA_OFFSET (0)
#define CODE_AREA_SIZE (64*1024)
#define CODE_AREA_OFFSET (64*1024)
#define DATA_AREA_SIZE (64*1024)
#define DATA_AREA_OFFSET (64*1024 + 64*1024)

int code_area_size = 0;
int global_data_size = 0;

/*
typedef union _stack_machine_data_type {
	int i;
	unsigned char b;
} stack_machine_data_type;
*/

typedef int stack_machine_data_type;

struct instr_node* code_area[CODE_AREA_SIZE];
stack_machine_data_type stack[STACK_SIZE];
stack_machine_data_type global_data_area[DATA_AREA_SIZE];

/* instruction without operand */
#define INSTR_TYPE_1 \
	yyval.instr = (struct instr_node*)malloc(sizeof(struct instr_node)); \
	yyval.instr->opcode = yyvsp[0].id; \
	yyval.instr->operand = NULL;

/* instruction with 1 constant operand */
#define INSTR_TYPE_2 \
	yyval.instr = (struct instr_node*)malloc(sizeof(struct instr_node)); \
	yyval.instr->opcode = yyvsp[-1].id; \
	yyval.instr->operand = yyvsp[0].operand;

/* instruction with 1 register operand */
#define INSTR_TYPE_3 \
	yyval.instr = (struct instr_node*)malloc(sizeof(struct instr_node)); \
	yyval.instr->opcode = yyvsp[-1].id; \
	yyval.instr->operand = yyvsp[0].operand;

/* instruction with 1 integer const operand */
#define INSTR_TYPE_4 \
	yyval.instr = (struct instr_node*)malloc(sizeof(struct instr_node)); \
	yyval.instr->opcode = yyvsp[-1].id; \
	yyval.instr->operand = yyvsp[0].operand;

%}

%union {
	int intVal;
	char* stringVal;
	id_ptr id;

	struct instr_node* instr;
	struct operand* operand;
}

%token <intVal> INT_CONST
%token <stringVal> STRING_CONST
%token <id> NEGATE NOT ABS
%token <id> ADD SUB MUL DIV MOD AND OR EQUAL NOT_EQUAL GREATER GREATER_EQUAL LESS LESS_EQUAL
%token <id> JUMP BRANCH_TRUE BRANCH_FALSE EXIT
%token <id> PUSH_CONST PUSH_REG POP_REG
%token <id> SHIFT_SP
%token <id> ASSIGN FETCH
%token <id> READ_INT READ_CHAR
%token <id> WRITE_INT WRITE_CHAR WRITE_STRING
%token <id> SP FP PC
%token <id> ID
%token <id> DATA
%token <id> STRING
%type <instr> inst
%type <operand> const_op integer reg

%token NEW_LINE

%start file
%%

inst
	: NEGATE { INSTR_TYPE_1 }
	| NOT { INSTR_TYPE_1 }
	| ABS { INSTR_TYPE_1 }
	| ADD { INSTR_TYPE_1 }
	| SUB { INSTR_TYPE_1 }
	| MUL { INSTR_TYPE_1 }
	| DIV { INSTR_TYPE_1 }
	| MOD { INSTR_TYPE_1 }
	| AND { INSTR_TYPE_1 }
	| OR { INSTR_TYPE_1 }
	| EQUAL { INSTR_TYPE_1 }
	| NOT_EQUAL { INSTR_TYPE_1 }
	| GREATER { INSTR_TYPE_1 }
	| GREATER_EQUAL { INSTR_TYPE_1 }
	| LESS { INSTR_TYPE_1 }
	| LESS_EQUAL { INSTR_TYPE_1 }
	| JUMP const_op { INSTR_TYPE_2 }
	| BRANCH_TRUE const_op { INSTR_TYPE_2 }
	| BRANCH_FALSE const_op { INSTR_TYPE_2 }
	| EXIT { INSTR_TYPE_1 }
	| PUSH_CONST const_op { INSTR_TYPE_2 }
	| PUSH_REG reg { INSTR_TYPE_3 }
	| POP_REG reg { INSTR_TYPE_3 }
	| SHIFT_SP integer { INSTR_TYPE_4 }
	| ASSIGN { INSTR_TYPE_1 }
	| FETCH { INSTR_TYPE_1 }
	| READ_INT { INSTR_TYPE_1 }
	| READ_CHAR { INSTR_TYPE_1 }
	| WRITE_INT { INSTR_TYPE_1 }
	| WRITE_CHAR { INSTR_TYPE_1 }
	| WRITE_STRING { INSTR_TYPE_1 }
	;

state
	: inst NEW_LINE
		{
			assert(code_area_size <= CODE_AREA_SIZE);

			code_area[code_area_size++] = $1;
		}
;

empty_state
	: NEW_LINE
	;

label
	: ID ':' NEW_LINE
		{
			assert($1->pc < 0);
			$1->pc = CODE_AREA_OFFSET + code_area_size;
		}
	;

global
	: ID '.' DATA INT_CONST NEW_LINE
		{
			int i;

			assert($1->pc < 0);
			$1->pc = DATA_AREA_OFFSET + global_data_size;

			for(i = 0; i < $4; i++) {
				global_data_area[ global_data_size + i ] = 0;
			}

			global_data_size += $4;

			assert(global_data_size <= DATA_AREA_SIZE);
		}
	;

string
	: ID '.' STRING STRING_CONST NEW_LINE
		{
			int i, size;

			assert($1->pc < 0);
			$1->pc = DATA_AREA_OFFSET + global_data_size;

			size = strlen($4) + 1;
			for(i = 0; i < size; i++) {
				global_data_area[ global_data_size + i ] = (int)$4[i];
			}

			global_data_size += size;

			assert(global_data_size <= DATA_AREA_SIZE);
		}
	;

integer
	: INT_CONST
		{
			$$ = (struct operand*)malloc(sizeof(struct operand)); \
			$$->reg = NULL; \
			$$->label = NULL; \
			$$->integer = yyvsp[0].intVal; \
			$$->is_integer_used = 1;
		}
	| '-' INT_CONST
		{
			$$ = (struct operand*)malloc(sizeof(struct operand)); \
			$$->reg = NULL; \
			$$->label = NULL; \
			$$->integer = -1 * yyvsp[0].intVal; \
			$$->is_integer_used = 1;
		}
	;

const_op
	: INT_CONST
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = NULL;
			$$->label = NULL;
			$$->integer = $1;
			$$->is_integer_used = 1;
		}
	| '-' INT_CONST
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = NULL;
			$$->label = NULL;
			$$->integer = -1 * $2;
			$$->is_integer_used = 1;
		}
	| ID
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = NULL;
			$$->label = $1;
			$$->integer = 0;
			$$->is_integer_used = 0;
		}
	| ID '+' INT_CONST
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = NULL;
			$$->label = $1;
			$$->integer = $3;
			$$->is_integer_used = 1;
		}
	| ID '-' INT_CONST
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = NULL;
			$$->label = $1;
			$$->integer = -1 * $3;
			$$->is_integer_used = 1;
		}
	;

reg
	: FP
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = $1;
			$$->label = NULL;
			$$->integer = 0;
			$$->is_integer_used = 0;
		}
	| SP
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = $1;
			$$->label = NULL;
			$$->integer = 0;
			$$->is_integer_used = 0;
		}
	| PC
		{
			$$ = (struct operand*)malloc(sizeof(struct operand));
			$$->reg = $1;
			$$->label = NULL;
			$$->integer = 0;
			$$->is_integer_used = 0;
		}
	;

file
	: file state { }
	| file label { }
	| file global { }
	| file string { }
	| state { }
	| label { }
	| empty_state { }
	| global { }
	| string { }
	;

%%

void init_stack_machine(void)
{
	memset(code_area, 0, sizeof(struct instr_node*) * CODE_AREA_SIZE);
	memset(stack, 0, sizeof(stack_machine_data_type) * STACK_SIZE);
	memset(global_data_area, 0, sizeof(stack_machine_data_type) * DATA_AREA_SIZE);
}

void validate_stack_machine(void)
{
	int i;
	struct operand* operand;

	for(i=CODE_AREA_OFFSET; i<CODE_AREA_OFFSET + code_area_size; i++) {
		assert(code_area[i - CODE_AREA_OFFSET]!=NULL);

		operand = code_area[i - CODE_AREA_OFFSET]->operand;

		switch(code_area[i - CODE_AREA_OFFSET]->opcode->lextype) {
		case NEGATE: case NOT: case ABS: case ADD: case SUB:
		case MUL: case DIV: case MOD: case AND: case OR:
		case EQUAL: case NOT_EQUAL: case GREATER: case GREATER_EQUAL:
		case LESS: case LESS_EQUAL:
		case EXIT:
		case ASSIGN: case FETCH:
		case READ_INT: case READ_CHAR:
		case WRITE_INT: case WRITE_CHAR: case WRITE_STRING:
			/* opcodes without operand */
			assert(operand==NULL);
			break;

		case JUMP: case BRANCH_TRUE: case BRANCH_FALSE:
		case PUSH_CONST:
			/* opcodes with 1 constant operand */
			assert(operand!=NULL);
			assert(operand->reg==NULL && (operand->label || operand->is_integer_used));
			if(operand->label) {
				if(!((operand->label->pc >= CODE_AREA_OFFSET && operand->label->pc < CODE_AREA_OFFSET + CODE_AREA_SIZE) || (operand->label->pc >= DATA_AREA_OFFSET && operand->label->pc < DATA_AREA_OFFSET + DATA_AREA_SIZE))) {
					fprintf(stderr, "%s is not declared.\n", operand->label->name);
					abort();
				}
			}
			break;

		case PUSH_REG: case POP_REG:
			/* opcodes with 1 register operand */
			assert(operand!=NULL);
			assert(operand->reg!=NULL && operand->label==NULL && operand->is_integer_used==0);
			break;
		case SHIFT_SP:
			/* opcodes with 1 integer operand */
			assert(operand!=NULL);
			assert(operand->reg==NULL && operand->label==NULL && operand->is_integer_used);
			break;
		defaule:
			assert(0);
		}
	}
}

void simulate_stack_machine(void)
{
	int pc, sp, fp;	/* stack machine registers */

	fprintf(stderr, "code area size %d\n", code_area_size);
	fprintf(stderr, "data area size %d\n", global_data_size);

	pc = CODE_AREA_OFFSET;
	sp = STACK_AREA_OFFSET - 1;
	fp = 0;

	validate_stack_machine();

#define PUSH(x) { \
		sp++; \
		assert(sp<STACK_AREA_OFFSET + STACK_SIZE);\
		stack[sp - STACK_AREA_OFFSET] = x; \
	}
#define POP(x) { \
		assert(sp>=STACK_AREA_OFFSET); \
		x = stack[sp]; \
		sp--; \
	}

	while(1) {
		int opcode;
		struct operand* operand;
		stack_machine_data_type temp_reg1, temp_reg2;

		assert(pc>=CODE_AREA_OFFSET && pc<CODE_AREA_OFFSET+CODE_AREA_SIZE);

		opcode = code_area[pc - CODE_AREA_OFFSET]->opcode->lextype;
		operand = code_area[pc - CODE_AREA_OFFSET]->operand;

		switch(opcode) {
		case NEGATE:
			POP(temp_reg1);
			PUSH(-1 * temp_reg1);
			pc++;
			break;
		case NOT:
			POP(temp_reg1);
			PUSH(!temp_reg1);
			pc++;
			break;
		case ABS:
			POP(temp_reg1);
			PUSH(temp_reg1>=0 ? temp_reg1 : (-1 * temp_reg1));
			pc++;
			break;
		case ADD:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 + temp_reg1);
			pc++;
			break;
		case SUB:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 - temp_reg1);
			pc++;
			break;
		case MUL:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 * temp_reg1);
			pc++;
			break;
		case DIV:
			POP(temp_reg1);
			POP(temp_reg2);
			if(temp_reg1==0) {
				fprintf(stderr, "divide by zero\n");
				abort();
			}
			PUSH(temp_reg2 / temp_reg1);
			pc++;
			break;
		case MOD:
			POP(temp_reg1);
			POP(temp_reg2);
			if(temp_reg1==0) {
				fprintf(stderr, "divide by zero\n");
				abort();
			}
			PUSH(temp_reg2 % temp_reg1);
			pc++;
			break;
		case AND:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 && temp_reg1);
			pc++;
			break;
		case OR:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 || temp_reg1);
			pc++;
			break;
		case EQUAL:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 == temp_reg1);
			pc++;
			break;
		case NOT_EQUAL:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 != temp_reg1);
			pc++;
			break;
		case GREATER:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 > temp_reg1);
			pc++;
			break;
		case GREATER_EQUAL:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 >= temp_reg1);
			pc++;
			break;
		case LESS:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 < temp_reg1);
			pc++;
			break;
		case LESS_EQUAL:
			POP(temp_reg1);
			POP(temp_reg2);
			PUSH(temp_reg2 <= temp_reg1);
			pc++;
			break;
		case JUMP:
			if(operand->label && operand->is_integer_used) {
				pc = operand->label->pc + operand->integer;
			} else if(operand->label && !operand->is_integer_used) {
				pc = operand->label->pc;
			} else if(operand->label==NULL && operand->is_integer_used) {
				pc = operand->integer;
			} else {
				assert(0);
			}
			break;
		case BRANCH_TRUE:
			POP(temp_reg1);
			if(temp_reg1) {
				if(operand->label && operand->is_integer_used) {
					pc = operand->label->pc + operand->integer;
				} else if(operand->label && !operand->is_integer_used) {
					pc = operand->label->pc;
				} else if(operand->label==NULL && operand->is_integer_used) {
					pc = operand->integer;
				} else {
					assert(0);
				}
			} else {
				pc++;
			}
			break;
		case BRANCH_FALSE:
			POP(temp_reg1);
			if(!temp_reg1) {
				if(operand->label && operand->is_integer_used) {
					pc = operand->label->pc + operand->integer;
				} else if(operand->label && !operand->is_integer_used) {
					pc = operand->label->pc;
				} else if(operand->label==NULL && operand->is_integer_used) {
					pc = operand->integer;
				} else {
					assert(0);
				}
			} else {
				pc++;
			}
			break;
		case EXIT:
			fprintf(stdout, "program exits\n");
			exit(0);
			break;
		case PUSH_CONST:
			if(operand->label && operand->is_integer_used) {
				temp_reg1 = operand->label->pc + operand->integer;
			} else if(operand->label && !operand->is_integer_used) {
				temp_reg1 = operand->label->pc;
			} else if(operand->label==NULL && operand->is_integer_used) {
				temp_reg1 = operand->integer;
			} else {
				assert(0);
			}
			PUSH(temp_reg1);
			pc++;
			break;
		case PUSH_REG:
			assert(operand->reg);
			switch(operand->reg->lextype) {
			case PC:
				temp_reg1 = pc;
				break;
			case SP:
				temp_reg1 = sp;
				break;
			case FP:
				temp_reg1 = fp;
				break;
			default:
				assert(0);
			}
			PUSH(temp_reg1);
			pc++;
			break;
		case POP_REG:
			assert(operand->reg);
			POP(temp_reg1);
			switch(operand->reg->lextype) {
			case PC:
				pc = temp_reg1;
				break;
			case SP:
				sp = temp_reg1;
			    pc++;
				break;
			case FP:
				fp = temp_reg1;
			    pc++;
				break;
			default:
				assert(0);
			}
			break;
		case SHIFT_SP:
			assert(operand->reg==NULL && operand->label==NULL && operand->is_integer_used==1);
			sp += operand->integer;
			pc++;
			break;
		case ASSIGN:
			POP(temp_reg1);
			POP(temp_reg2);
			if(temp_reg2>=STACK_AREA_OFFSET && temp_reg2<STACK_AREA_OFFSET+STACK_SIZE) {
				stack[temp_reg2 - STACK_AREA_OFFSET] = temp_reg1;
			} else if(temp_reg2>=DATA_AREA_OFFSET && temp_reg2<DATA_AREA_OFFSET+global_data_size ) {
				global_data_area[temp_reg2 - DATA_AREA_OFFSET] = temp_reg1;
			} else if ( temp_reg2>=DATA_AREA_OFFSET+global_data_size && temp_reg2<DATA_AREA_OFFSET+DATA_AREA_SIZE ) {
				fprintf(stderr, "Global Data size is not enough\n");
			} else {
				fprintf(stderr, "invalid address %d\n", temp_reg2);
			}
			pc++;
			break;
		case FETCH:
			POP(temp_reg1);
			if(temp_reg1>=STACK_AREA_OFFSET && temp_reg1<STACK_AREA_OFFSET+STACK_SIZE) {
				temp_reg2 = stack[temp_reg1 - STACK_AREA_OFFSET];
			} else if(temp_reg1>=DATA_AREA_OFFSET && temp_reg1<DATA_AREA_OFFSET+global_data_size) {
				temp_reg2 = global_data_area[temp_reg1 - DATA_AREA_OFFSET];
			} else if ( temp_reg1>=DATA_AREA_OFFSET+global_data_size && temp_reg1<DATA_AREA_OFFSET+DATA_AREA_SIZE ) {
				fprintf(stderr, "Global Data size is not enough\n");
			} else {
				fprintf(stderr, "invalid address %d\n", temp_reg1);
			}
			PUSH(temp_reg2);
			pc++;
			break;
		case READ_INT:
            fprintf(stdout, "read int:\n");
			scanf("%d", &temp_reg1);
			PUSH(temp_reg1);
			pc++;
			break;
		case READ_CHAR:
            fprintf(stdout, "read char:\n");
			temp_reg1 = 0;
			scanf("%c", &temp_reg1);
			PUSH(temp_reg1);
			pc++;
			break;
		case WRITE_INT:
			POP(temp_reg1);
			fprintf(stdout, "%d", temp_reg1);
			pc++;
			break;
		case WRITE_CHAR:
			POP(temp_reg1);
			fprintf(stdout, "%c", temp_reg1);
			pc++;
			break;
		case WRITE_STRING:
			POP(temp_reg1);
			if(temp_reg1>=STACK_AREA_OFFSET && temp_reg1<STACK_AREA_OFFSET+STACK_SIZE) {
				while(1) {
					int c = stack[temp_reg1++ - STACK_AREA_OFFSET];
					if(c==0) break;
					if(c=='\'') {
						if(c=='n') fputc('\n', stdout);
						else if(c=='t') fputc('\t', stdout);
						else fputc(c, stdout);
					} else {
						fputc(c, stdout);
					}
				}
			} else if(temp_reg1>=DATA_AREA_OFFSET && temp_reg1<DATA_AREA_OFFSET+DATA_AREA_SIZE) {
				while(1) {
					int c = global_data_area[temp_reg1++ - DATA_AREA_OFFSET];
					if(c==0) break;
					if(c=='\\') {
					    int c = global_data_area[temp_reg1++ - DATA_AREA_OFFSET];
						if(c=='n') fputc('\n', stdout);
						else if(c=='t') fputc('\t', stdout);
						else fputc(c, stdout);
					} else {
						fputc(c, stdout);
					}
				}
			} else {
				fprintf(stderr, "invalid address %d\n", temp_reg1);
                abort();
			}
			pc++;
			break;
		}
	}
}

int yyerror(char* s)
{
	fprintf(stderr,"%d:%s\n",lineno,s);
	exit (-1);
}
