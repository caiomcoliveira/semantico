%{
  # include "sintatico.tab.h"
  # include <string.h>
%}
%%
([0-9]{1,})((\.)?[0-9]{1,})?		          {yylval.num = (char *) strdup(yytext); return NUM;}
("var")                                   {return VAR;}
("leia")                                  {return LEIA;}
("escreva")                               {return ESCREVA;}
("int"|"float")                           {yylval.id = (char *) strdup(yytext); return TIPO;}
[a-zA-Z][a-zA-Z0-9]*	                    {yylval.id = (char *) strdup(yytext); return ID;}
\"(\\.|[^"])*\                            {return STRING;}
[ \t\n]+			                            {;}
.			                                    {return yytext[0];}
%%
int yywrap() {
  return 1;
}