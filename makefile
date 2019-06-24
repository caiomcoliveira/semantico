all: analise

analise: bison flex comp

bison: sintatico.y
	bison -d sintatico.y

flex:
	flex lexico.l

comp:
	gcc sintatico.tab.c lex.yy.c -o prog

test:
	./prog entrada.txt
	./prog entrada2.txt
	./prog entrada3.txt
	./prog entrada4.txt
	./prog entrada5.txt