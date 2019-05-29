%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define YYDEBUG 1
extern int yydebug;
extern FILE *yyin;
int yyerror (char *s);
int yylex ();


typedef struct simbolo {
	char name[200];
	char tipo[30];
	int usado;
	int linha;
	struct simbolo *next;
} simbolo;

int linha = 0;

simbolo *tabela_simbolos = NULL;
void putsym(char* sym_name);
simbolo* getsym(char *sym_name);

typedef struct error {
	char* name;
	struct error* next;
} error;

error *errors= NULL;
error *warnings= NULL;

void puterror(char* error_name, error **lista);
void imprimeErros(error **lista);
int tamanhoListaErros(error **lista);

void verificaVariaveisNaoUtilizadas();
void imprimeTabelaSimbolos();
void insereTiposSimbolos(char* tipo, int n);
void insereTabelaSimbolos (char * sym_name);
void verificaTabelaSimbolos (char * sym_name);


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
decl_var: TIPO {insereTiposSimbolos($1, linha--);} lista_var {;}
;
lista_cmds:	cmd			{;}
		| cmd ';' lista_cmds	{;}
;
cmd:		ID '=' exp		{verificaTabelaSimbolos($1);}
        |   leia          {;}
        |   escreva       {;}
;
leia:   LEIA '(' lista_var ')' { /*verificaTabelaSimbolos($1);*/ } /*Perguntar se "leia" é um token ou se eh definido na gramatica */
;
escreva: ESCREVA '(' lista_output ')' { /*verificaTabelaSimbolos($1);*/}
;
lista_var: 	ID 										{linha++;insereTabelaSimbolos($1);}
                | ID ',' lista_var { insereTabelaSimbolos($1);}
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
	| ID 						{verificaTabelaSimbolos($1);}
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
        if(tamanhoListaErros(&errors) > 0){
            imprimeErros(&errors);
        }else{
            verificaVariaveisNaoUtilizadas();
            imprimeErros(&warnings);
            imprimeTabelaSimbolos();
        }						
    }
}
int yyerror (char *s) /* Called by yyparse on error */
{
	printf ("Problema com a analise sintatica!\n");
}


void putsym(char *sym_name){
	simbolo *aux = (simbolo*) malloc(sizeof(simbolo));
    strcpy(aux->name, sym_name);
    aux->usado = 0;
	aux->next = tabela_simbolos;
	aux->linha = linha;
	tabela_simbolos = aux;
}

simbolo*  getsym( char * sym_name){
	simbolo *aux = tabela_simbolos;
    while(aux!= NULL){		
		if(strcmp(aux->name, sym_name) == 0)
			return aux;	
		aux = aux->next;
	}
	return 0;
}


void puterror(char *error_name, error **lista){
	error *aux = (error*) malloc(sizeof(error));
	strcpy(aux->name,error_name);
	aux->next = (*lista);
	(*lista) = aux;
}

void imprimeErros(error **lista){
	error *aux = *lista;

	while(aux!= NULL){		
		printf("%s\n", aux->name);
		aux = aux->next;
	}
	printf("\n");
}

int tamanhoListaErros(error **lista){
	int length = 0;
	error *aux = *lista;

	while(aux!= NULL){		
		aux = aux->next;
		length++;
	}
	return length;
}

void insereTabelaSimbolos (char * sym_name){

	simbolo* s = getsym(sym_name);
    printf("Inserindo nome %s\n", sym_name);
	if(!s){
        putsym (sym_name);
        
	}else{
		char message[1024];
		snprintf(message, 1024, "ERRO: A variavel %s ja foi definida!",sym_name);
		puterror(message, &errors);
	}
}

void verificaTabelaSimbolos(char * sym_name){
	simbolo* aux = getsym(sym_name);
	if(aux == 0){		
		char message[1024];
		snprintf(message, 1024, "ERRO: Uso da variavel %s sem ter sido definida.", sym_name);
		puterror(message, &errors);
	}else{
		aux->usado = 1;
	}
}

void verificaVariaveisNaoUtilizadas(){
	simbolo *aux = tabela_simbolos;


	while(aux!= NULL){	
		if(aux->usado == 0){
			char message[1024];
			snprintf(message, 1024, "WARNING: Variavel %s nao foi utilizada.", aux->name);
			puterror(message, &warnings);
		}
		aux = aux->next;
	}
}


void imprimeTabelaSimbolos(){
	simbolo *aux = tabela_simbolos;

	printf("NOME\t TIPO\t\t\tUSADA\n");

	while(aux!= NULL){		
		printf("%s\t %s \t\t\t%s\n", aux->name, aux->tipo, (aux->usado == 0) ? "nao" : "sim");
		aux = aux->next;
	}
}


void insereTiposSimbolos(char* tipo, int n){
		simbolo * aux = tabela_simbolos;
		while(aux!= NULL){		
            if(aux->linha == n){
				strcpy(aux->tipo,tipo);
			}
			aux = aux->next;
		}
}