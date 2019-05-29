%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define YYDEBUG 1
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
	char name[200];
	char type[30];
	int used;
	int line;
	struct symbol *next;
} symbol;

typedef struct error {
	char name[400];
	struct error* next;
} error;


int line = 0;
char* currentType;

symbol *symbol_table = (symbol*)0;
error *errors= (error*)0;
error *warnings= (error*)0;

void putsym(char* sym_name);
symbol* getsym(char *sym_name);



void print_color_red(){
    printf("%s", KRED);
};
void print_color_yellow(){
    printf("%s", KYEL);
};
void print_color_end(){
    printf("%s", KNRM);
};

void puterror(error **list, char* error_name);
void printErrors(error **list);
int errorListSize(error **list);

void variablesNotUsed();
void printSymTable();
void insertSymTypes(char* type, int n);
void insertSymTable (char * sym_name);
void verifySymTable (char * sym_name);


%}
%union {
	char *id;
}

%token NUM
%token <id> ID
%token LEIA
%token ESCREVA
%token OPA
%token OPM
%token STRING
%token <id> TIPO
%token VAR

%%

programa:	bloco_var
					'{' lista_cmds '}'	{printf ("Programa sintaticamente correto!\n");}
;
bloco_var: /*empty*/
					| VAR '{' lista_decl_var '}' {;}
;
lista_decl_var: decl_var {;}
						| decl_var ';' lista_decl_var {;}
;
decl_var: TIPO {/*insertSymTypes($1, line--);*/ currentType = $1;} lista_var {;}
;
lista_cmds:	cmd			{;}
		| cmd ';' lista_cmds	{;}
;
cmd:		ID '=' exp		{verifySymTable($1);}
        |   leia          {;}
        |   escreva       {;}
;
leia:   LEIA '(' lista_var ')' { /*verifySymTable($1);*/ } /*Perguntar se "leia" é um token ou se eh definido na gramatica */
;
escreva: ESCREVA '(' lista_output ')' { /*verifySymTable($1);*/}
;
lista_var: 	ID 										{line++;insertSymTable($1);}
                | ID ',' lista_var { insertSymTable($1);}
;
lista_output: 	output    							{;}
              | output ',' lista_output {;}
;
output: exp {;}
        /*| '"' STRING '"' {;} */
;
exp:
			termo 				{;}
    | exp opa termo {;}
		// | exp '-' termo {;}
;

termo:
			fator           	{;}
    | termo '*' fator 	{;}
		| termo '/' fator 	{;}
;

opa:
      '+' {;}
    | '-' {;}

fator:
    NUM           {;}
	| opa NUM       {;}
	| ID 						{verifySymTable($1);}
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
        if(errorListSize(&errors) > 0){
            print_color_red();
            printErrors(&errors);
            print_color_end();
        }else{
            variablesNotUsed();
            print_color_yellow();
            printErrors(&warnings);
            print_color_end();
            printSymTable();
        }						
    }
}
int yyerror (char *s) /* Called by yyparse on error */
{
	printf ("Problema com a analise sintatica!\n");
}


void putsym(char *sym_name){
	symbol *aux = (symbol*) malloc(sizeof(symbol));
    strcpy(aux->name, sym_name);
    aux->used = 0;
    strcpy(aux->type,currentType);
	aux->next = symbol_table;
	aux->line = line;
	symbol_table = aux;
}

symbol*  getsym( char * sym_name){
	symbol *aux = symbol_table;
    while(aux!= NULL){		
		if(strcmp(aux->name, sym_name) == 0)
			return aux;	
		aux = aux->next;
	}
	return 0;
}


void puterror(error **list, char *error_name){
	error *aux = (error*) malloc(sizeof(error));
	strcpy(aux->name,error_name);
	aux->next = (*list);
	(*list) = aux;
}

void printErrors(error **list){
	error *aux = *list;

	while(aux!= NULL){		
		printf("%s\n", aux->name);
		aux = aux->next;
	}
	printf("\n");
}

int errorListSize(error **list){
	int length = 0;
	error *aux = *list;

	while(aux!= NULL){		
		aux = aux->next;
		length++;
	}
	return length;
}

void insertSymTable (char * sym_name){
	symbol* s = getsym(sym_name);
    if(!s){
        putsym (sym_name);
    }else{
		char message[1024];
        snprintf(message, 1024, "ERRO: A variavel %s ja foi definida!",sym_name);
        puterror(&errors, message);
	}
}

void verifySymTable(char * sym_name){
	symbol* aux = getsym(sym_name);
	if(aux == 0){		
		char message[1024];
		snprintf(message, 1024, "ERRO: Uso da variavel %s sem ter sido definida.", sym_name);
		puterror(&errors, message);
	}else{
		aux->used = 1;
	}
}

void variablesNotUsed(){
	symbol *aux = symbol_table;
	while(aux!= NULL){	
        if(aux->used == 0){
            
			char message[1024];
			snprintf(message, 1024, "WARNING: Variavel %s nao foi utilizada.", aux->name);
            puterror(&warnings, message);
		}
        
		aux = aux->next;
	}
}


void printSymTable(){
	symbol *aux = symbol_table;

	printf("NOME\t type\t\t\tUSADA\n");

	while(aux!= NULL){		
		printf("%s\t %s \t\t\t%s\n", aux->name, aux->type, (aux->used == 0) ? "nao" : "sim");
		aux = aux->next;
	}
}


void insertSymTypes(char* type, int n){
	symbol * aux = symbol_table;
	while(aux!= NULL){		
		if(aux->line == n){
			strcpy(aux->type,type);
		}
		aux = aux->next;
	}
}