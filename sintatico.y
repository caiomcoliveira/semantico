%{
#include <stdio.h>
#define YYDEBUG 1
extern int yydebug;
extern FILE *yyin;
int yyerror (char *s);
int yylex ();

#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"


typedef struct symbol {
	char* name;
	char* type;
	int used;
  int line;
	struct symbol *next;
} symbol;

typedef struct error {
	char* name;
	struct error* next;
} error;

symbol *symbol_table = (symbol*)0;

error *errors= (error *)0;
error *warnings= (error *)0;


void push_symbol(char* sym_name);
symbol* get_symbol(char *sym_name);

void push_error(error **list, char* error_name);
void print_errors(error **list);

void check_unused_variables();
void print_symbol_table();
void push_symbol_type(char* type, int line);
void push_symbol_table(char * sym_name);
void check_symbol_table(char * sym_name);

void start_red();
void start_yellow();
void end_color();

int line = 0;

%}
%token NUM
%token ID
%token LEIA
%token ESCREVA
%token OPA
%token OPM
%token STRING
%token TIPO
%token VAR




%%

programa:	bloco_var
					'{' list_cmds '}'	{printf ("Programa sintaticamente correto!\n");}
;
bloco_var: /*empty*/
					| VAR '{' list_decl_var '}' {;}
;
list_decl_var: decl_var {;}
						| decl_var ';' list_decl_var {;}
;
decl_var: TIPO list_var { /*push_symbol_type($1, line--); */}
;
list_cmds:	cmd			{;}
		| cmd ';' list_cmds	{;}
;
cmd:		ID '=' exp		{ /*line++; check_symbol_table($1); */}
        |   leia          {;}
        |   escreva       {;}
;
leia:   LEIA '(' list_var ')' {;} /*Perguntar se "leia" é um token ou se eh definido na gramatica */
;
escreva: ESCREVA '(' list_output ')' {;}
;
list_var:    	  ID 							    { /*push_symbol_table($1); */}
                | ID ',' list_var    { /*push_symbol_table($1); */}
;
list_output: 	output    							{;}
              | output ',' list_output {;}
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
	| ID 						{ /*check_symbol_table($1); */}
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
			// if(tamanhoListErros(&errors) > 0){
			// 	print_errors(&errors);
			// }else{
			// 	check_unused_variables();
			// 	print_errors(&warnings);
			// 	print_symbol_table();
			// }						
		}
}
int yyerror (char *s) /* Called by yyparse on error */
{
  start_red();
	printf ("Problema com a analise sintatica!\n");
  end_color();
}



void start_red(){
  printf("%s\n", KRED);
}
void start_yellow(){
  printf("%s\n", KYEL);
}
void end_color(){
  printf("%s\n", KNRM);
}


// void push_symbol(char *sym_name){
// 	symbol *aux = (symbol*) malloc(sizeof(symbol));
// 	aux->name = strdup( sym_name);
// 	aux->used = 0;
// 	aux->next = symbol_table;
// 	aux->line = line;
// 	symbol_table = aux;
// }

// symbol*  get_symbol( char * sym_name){
// 	symbol *table = symbol_table;
// 	while(table!= NULL){		
// 		if(strcmp(table->name, sym_name) == 0)
// 			return table;	
// 		table = table->next;
// 	}
// 	return 0;
// }


// void push_error(error **list, char *error_name){
// 	error *aux = (error*) malloc(sizeof(error));
// 	aux->name = strdup(error_name);
// 	aux->next = (*list);
// 	(*list) = aux;
// }


// void print_errors(error **list){
// 	error *aux = *list;

// 	while(aux!= NULL){		
// 		printf("%s\n", aux->name);
// 		aux = aux->next;
// 	}
// 	printf("\n");
// }


// void push_symbol_table(char * sym_name){

// 	symbol* s = get_symbol(sym_name);

// 	if(!s){
// 		push_symbol(sym_name);
// 	}else{
// 		char message[1024];
//     start_red();
// 		printf("ERRO: A variavel %s ja foi definida!",sym_name);
//     end_color();
// 		push_error(message, &errors);
// 	}
// }

// void check_symbol_table(char * sym_name){
// 	symbol* aux = getsym(sym_name);
// 	if(aux == 0){		
// 		char message[1024];
//     start_red();
// 		printf("ERRO: Uso da variavel %s sem ter sido definida.", sym_name);
//     end_color();
// 		push_error(message, &errors);
// 	}else{
// 		aux->used = 1;
// 	}
// }

// void check_unused_variables(){
// 	symbol *table = symbol_table;
// 	while(table!= NULL){	
// 		if(table->used == 0){
// 			char message[1024];
//       start_yellow();
// 			printf("WARNING: Varaible %s declared, but not used.", table->name);
//       end_color();
// 			push_error(message, &warnings);
// 		}
// 		table = table->next;
// 	}
// }


// void print_symbol_table(){
// 	symbol *table = symbol_table;
//   printf("_______________________________________________________\n");
// 	printf("|NAME\t\t |TYPE \t\t |USED\n");
// 	while(table!= NULL){		
// 		printf("|%s\t\t |%s \t\t |%s\n", table->name, table->type, (table->used == 0) ? "NO" : "YES");
// 		table = table->next;
// 	}
//   printf("---------------------------------------------------------\n");
// }


// void push_symbol_type(char* type, int n){
// 		symbol * table = symbol_table;
// 		while(table!= NULL){		
// 			if(table->line == n){
// 				table->type = strdup(type);
// 			}
// 			table = table->next;
// 		}
// }