all: analise

analise: bison flex comp

bison: sintatico.y
	bison -d sintatico.y

flex:
	flex lexico.l

comp:
	gcc sintatico.tab.c lex.yy.c -o prog