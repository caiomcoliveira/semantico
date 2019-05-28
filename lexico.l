%{
  # include "sintatico.tab.h"
%}
%%
([0-9]{1,})((\.)?[0-9]{1,})?		{return NUM;}
("var")                                   {return VAR;}
("leia")                                  {return LEIA;}
("escreva")                               {return ESCREVA;}
("int"|"float")                           {return TIPO;}
[a-zA-Z][a-zA-Z0-9]*	                    {return ID;}
\"(\\.|[^"])*\                            {return STRING;}
[ \t\n]+			                            {;}
.			                                    {return yytext[0];}
%%
int yywrap() {
  return 1;
}