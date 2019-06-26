%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define YYDEBUG 1
#define TRUE 1
#define FALSE 0
#define TYPECONVERSIONDEBUG 0
#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"

extern int yydebug;
extern FILE *yyin;
int yyerror (char *s);
int yylex ();


typedef struct symbol {
	char type[30];
	char name[200];
	int used;
	int address;
	struct symbol *next;
} symbol;

typedef struct error {
	char name[400];
	struct error* next;
} error;

char* currentType;
int typeConversion = FALSE;
int typeConversionWarning = FALSE;
int isExpression = FALSE;
char currentExpression[2][50];
char operator;
int leftMostIsFloat = FALSE;
int line = 1;
symbol *symbol_table = (symbol*)0;
error *errors= (error*)0;
error *warnings= (error*)0;
int address = 0;

void push_symbol(char* sym_name);
symbol* find_symbol(char *sym_name);

void print_color_red(){
    printf("%s", KRED);
};
void print_color_yellow(){
    printf("%s", KYEL);
};
void print_color_end(){
    printf("%s", KNRM);
};

void push_error(error **list, char* error_name);
void print_errors(error **list);
int list_length(error **list);

void print_symbol_table();
void push_symbol_table (char * sym_name);
void verify_variables_not_used();
void verify_symbol_table (char * sym_name);
void check_type_left_most (char * sym_name);
void check_type_conversion (char * sym_name);
void evaluate_expression ();
void reset ();
void throw_type_conversion ();

%}
%union {
	char *id;
	char *num;
	char opa;
}

%token LEIA
%token ESCREVA
%token OPA
%token OPM
%token STRING
%token VAR
%token OPR
%token ENQUANTO
%token SE
%token SENAO

%token <num> NUM
%token <id> ID
%token <id> TIPO

%type<id> fator termo
%type<opa> opa special_opa

%%
programa: bloco_var
         '{' { line++; } lista_cmds '}'	{ line++; }
;

bloco_var: /*empty*/
          | VAR { line++; } '{' lista_decl_var '}' { line++; }
;

lista_decl_var: decl_var ';'	            {line++;}
	      		| decl_var ';' {line++;} lista_decl_var {;}
;

decl_var:  TIPO {currentType = $1;} lista_var {;}
;

lista_cmds: cmd ';' { if(typeConversion) throw_type_conversion(); reset(); line++; }
		  | cmd ';' { if(typeConversion) throw_type_conversion(); reset(); line++; } lista_cmds	   {;}
          | cmd_bloco              {;}
          | cmd_bloco  lista_cmds  {;}
;

cmd: ID { check_type_left_most($1); }  '=' exp	{ verify_symbol_table($1); }
   | leia               {;}
   | escreva            {;}
;

cmd_bloco: enquanto {;}
         | se_entao {;}
;

leia: LEIA '(' lista_var ')' {;} 
;

escreva: ESCREVA '(' lista_output ')' {;}
;

lista_var: ID                  { push_symbol_table($1); }
         | ID ',' lista_var     { push_symbol_table($1); }
;

lista_output: output                   { ; }
            | output ',' lista_output   { ; }
;

output: exp                {;}
        /*| '"' STRING '"' {;} */
;

exp_rel: exp OPR exp {;}
;

enquanto: ENQUANTO '(' exp_rel ')' '{'lista_cmds'}' {;}
;

se_entao: SE '(' exp_rel ')' '{'lista_cmds'}'                         {;}
        | SE '(' exp_rel ')' '{'lista_cmds'}' SENAO '{'lista_cmds'}'  {;}
;

exp: termo          {;}
   | exp opa termo  {;}
;

termo: fator           	{;}
     | termo { if(!isExpression) strcpy(currentExpression[0],$1); } special_opa { isExpression = TRUE; } fator { strcpy(currentExpression[1],$5); evaluate_expression(); }
;

special_opa: '*' { $$ = '*'; operator = $$; }
		   | '/' { $$ = '/'; operator = $$; }

opa: '+' { $$ = '+'; }
   | '-' { $$ = '-'; }

fator:
      NUM           { 
	  				  check_type_conversion($1);
					  if (TYPECONVERSIONDEBUG) printf("SYMBOL: %s\n", $$);
					}
	| opa NUM       { 
					  check_type_conversion($2);
					  if (TYPECONVERSIONDEBUG) printf("SYMBOL: %s\n", $$);
					}
	| ID 			{ verify_symbol_table($1); check_type_conversion($1); }
    | '(' exp ')'   {;}
;
%%
int main (int argc, char *argv[])
{
    yydebug = 0;
    if (argc == 1) {
        yyin = fopen("entrada.txt", "r");
    }
    else{
        yyin = fopen(argv[1], "r");
    }
    if(yyin == NULL) {
        printf("Arquivo invalido\n");
        return 0;
    }
    if(!(yyparse ())) {
		verify_variables_not_used();
		print_color_yellow();
		print_errors(&warnings);
		print_color_end();
        if(list_length(&errors) > 0){
            print_color_red();
            print_errors(&errors);
            print_color_end();
			
        }	print_symbol_table();					
    }
}
int yyerror (char *s) /* Called by yyparse on error */
{
    print_color_red();
	printf ("Problema com a analise sintatica!\n");
    print_color_end();
    return 0;
}

void reset () {
	typeConversion = FALSE;
	leftMostIsFloat = FALSE;
	typeConversionWarning = FALSE;
	isExpression = FALSE;
	strcpy(currentExpression[0], "");
	strcpy(currentExpression[1], "");
}

void evaluate_expression () {
	if (strchr(currentExpression[0], '.') || strchr(currentExpression[1], '.')) {
		typeConversion = leftMostIsFloat ? FALSE : TRUE;
		sprintf(currentExpression[0], "%f", atof(currentExpression[0]) / atof(currentExpression[1]));
		strcpy(currentExpression[1], "");
	} else {
		if (operator == '/') {
			if (atoi(currentExpression[0]) % atoi(currentExpression[1])) {
				typeConversion = leftMostIsFloat ? FALSE : TRUE;
				sprintf(currentExpression[0], "%f", atof(currentExpression[0]) / atof(currentExpression[1]));
				strcpy(currentExpression[1], "");
			} else {
				sprintf(currentExpression[0], "%d", atoi(currentExpression[0]) / atoi(currentExpression[1]));
				strcpy(currentExpression[1], "");
			}
		} else {
			sprintf(currentExpression[0], "%d", atoi(currentExpression[0]) * atoi(currentExpression[1]));
			strcpy(currentExpression[1], "");
			typeConversion = leftMostIsFloat ? TRUE : FALSE;
		}
	}
}

void throw_type_conversion() {
	if (typeConversion && leftMostIsFloat && !typeConversionWarning) {
		char message[400];
		typeConversionWarning = TRUE;
		snprintf(message, 400, "WARNING: Implicit type conversion float -> int detected in line %d.", line);
		push_error(&warnings, message);
	} else if (typeConversion && !leftMostIsFloat && !typeConversionWarning) {
		char message[400];
		typeConversionWarning = TRUE;
		snprintf(message, 400, "WARNING: Implicit type conversion int -> float detected in line %d.", line);
		push_error(&warnings, message);
	}
}


void push_symbol(char *sym_name){
	symbol *aux = (symbol*) malloc(sizeof(symbol));
    strcpy(aux->name, sym_name);
    strcpy(aux->type,currentType);
	aux->address = address;
    aux->used = 0;
	aux->next = symbol_table;
	address++;
	symbol_table = aux;
}

symbol* find_symbol( char * sym_name){
	symbol *aux = symbol_table;
    while(aux!= NULL){		
		if(strcmp(aux->name, sym_name) == 0)
			return aux;	
		aux = aux->next;
	}
	return 0;
}


void push_error(error **list, char *error_name){
	error *aux = (error*) malloc(sizeof(error));
	strcpy(aux->name,error_name);
	aux->next = (*list);
	(*list) = aux;
}

void print_errors(error **list){
	error *aux = *list;
	while(aux!= NULL){		
		printf("%s\n", aux->name);
		aux = aux->next;
	}
	printf("\n");
}

int list_length(error **list){
	int length = 0;
	error *aux = *list;

	while(aux!= NULL){		
		aux = aux->next;
		length++;
	}
	return length;
}

void push_symbol_table (char * sym_name){
	symbol* s = find_symbol(sym_name);
    if(!s){
        push_symbol (sym_name);
    }else{
		char message[400];
        snprintf(message, 400, "ERROR: Variable `%s` has already been defined!", sym_name);
        push_error(&errors, message);
	}
}

void verify_symbol_table(char * sym_name){
	symbol* aux = find_symbol(sym_name);
	if(aux == 0){		
		char message[400];
		snprintf(message, 400, "ERROR: Variable  `%s` has not been declared.", sym_name);
		push_error(&errors, message);
	}else{
		aux->used = 1;
	}
}

void check_type_left_most(char * sym_name) {
	symbol* aux = find_symbol(sym_name);
	if(aux != 0) {
		leftMostIsFloat = !strcmp(aux->type, "float") ? TRUE : FALSE;
	}
}

void check_type_conversion(char * sym_name) {
	if (!typeConversion && !isExpression) {
		symbol* aux = find_symbol(sym_name);
		if(aux != 0) {
			if (!strcmp(aux->type, "float") && leftMostIsFloat) {
				typeConversion = FALSE;
			} else if (!strcmp(aux->type, "float") && !leftMostIsFloat) {
				typeConversion = TRUE;
			} else if (!strcmp(aux->type, "int") && leftMostIsFloat){
				typeConversion = TRUE;
			} else if (!strcmp(aux->type, "int") && !leftMostIsFloat) {
				typeConversion = FALSE;
			}
		} else {
			if (strchr(sym_name, '.') && leftMostIsFloat) {
				typeConversion = FALSE;
			} else if (strchr(sym_name, '.') && !leftMostIsFloat) {
				typeConversion = TRUE;
			} else if (!(strchr(sym_name, '.')) && leftMostIsFloat){
				typeConversion = TRUE;
			} else if (!(strchr(sym_name, '.')) && !leftMostIsFloat) {
				typeConversion = FALSE;
			}
		}
	}
}

void verify_variables_not_used(){
	symbol *table = symbol_table;
	while(table!= NULL){	
        if(table->used == 0){
			char message[400];
			snprintf(message, 400, "WARNING: Variable `%s` declared, but not used.", table->name);
            push_error(&warnings, message);
		}
		table = table->next;
	}
}


void print_symbol_table(){
	symbol *aux = symbol_table;
	printf("Type\t Name\t\t\tUSED\t\tAddress\n");
	while(aux!= NULL){		
		printf("%s\t%s\t\t\t%s\t\t%d\n", aux->type, aux->name, (aux->used == 0) ? "NO" : "YES", aux->address);
		aux = aux->next;
	}
}

