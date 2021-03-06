bison -d -y -v parser.y
# -d creates the header file y.tab.h that helps in communication(i.e. pass tokens) between parser
# and scanner; -y is something similar to -o y.tab.c, that is it creates the parser; -v creates an
# .output file containing verbose descriptions of the parser states and all the conflicts, both those
# resolved by operator precedence and the unresolved ones
echo '1'

g++ -w -c -o y.o y.tab.c
# -w stops the list of warnings from showing; -c compiles and assembles the c code, -o creates
# the y.o output file
echo '2'

flex lexer.l
# creates the lexical analyzer or scanner named lex.yy.c
echo '3'

g++ -fpermissive -w -c -o l.o lex.yy.c
echo '4'

g++ -o a.out y.o l.o -lfl -ly
# compiles the scanner and parser to create output file a.out; -lfl and -ly includes library files
# for lex and yacc(bison)

echo '5'
./a.out	inp.c code.asm Code.asm log.txt
# inp.c is the input file which will be turned into assembly code
