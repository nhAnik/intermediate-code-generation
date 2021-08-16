%option noyywrap
%x comments
%x acomments
%x str

%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<string>
#include <cstddef>
#include "SymbolTable.cpp"
#include "y.tab.h"
 
using namespace std;

extern YYSTYPE yylval;
void yyerror(char *);
extern symbolInfo* s;
extern symbolTable *st;
extern int line_count;
extern int error_cnt;

int upp;
char* temp_yytext=(char*) malloc (20);

int yy_ind;
int str_start;
int str_len;
char str_buf[100];
char str_log[100];

%}

WHITESPACE		 [ \t\f\r\v]+ 
LETTER 			 [a-zA-Z]
LETTER_ 		 [a-zA-Z_]
DIGIT 			 [0-9]
ALPHANUMERIC	 [a-zA-Z0-9\.]
NEWLINE 		 \n

ADDOP 			 [+-] 
MULOP 			 [*/%]

IDENTIFIER 		 {LETTER_}+({LETTER_}|{DIGIT})*
INTEGER 		 {DIGIT}+
FLOAT			 {DIGIT}*(\.{DIGIT}+)?(E[+-]?{DIGIT}+)?
VALIDCHAR		 [~!#$%&*(){}_\-+|\=:<>?,/\[\]\.]

CHAR             [']({LETTER}|{DIGIT}|{VALIDCHAR})[']
SCOMMENT         [/][/]([^\r\n])*([^/])\r\n 

INVID			 {DIGIT}+{LETTER_}+({LETTER_}|{DIGIT})*
INVNUM			 {FLOAT}{LETTER}+  

%%
{WHITESPACE} {}

{NEWLINE} 	{line_count++;}

"if"		{return IF;}

"else"		{return ELSE;}

"for"		{return FOR;}

"while"		{return WHILE;}

"do"		{return DO;}

"break"		{return BREAK;}

"continue"	{return CONTINUE;}

"println"	{return PRINTLN;}

"int"		{
				symbolInfo* s= new symbolInfo(yytext);
				yylval = (YYSTYPE)s;	
				return INT;
			}

"char"		{return CHAR;}

"float"		{
				symbolInfo* s= new symbolInfo(yytext);
				yylval = (YYSTYPE)s;
				return FLOAT;
			}

"double" 	{return DOUBLE;}

"void"		{
				symbolInfo* s= new symbolInfo(yytext);
				yylval = (YYSTYPE)s;
				return VOID;
			}

"return" 	{return RETURN;}

{ADDOP}	{ 	symbolInfo* s= new symbolInfo(yytext,"ADDOP");
			yylval = (YYSTYPE)s;
			return ADDOP;
		}

{MULOP}	{	symbolInfo* s= new symbolInfo(yytext,"MULOP");
			yylval = (YYSTYPE)s;
			return MULOP;
		}

"<"		|
"<="	|
">"		|
">="	|
"==" 	|
"!="	{	symbolInfo* s= new symbolInfo(yytext,"RELOP");
			yylval = (YYSTYPE)s;
			return RELOP;
		}

"&&"	|
"||"	{	symbolInfo* s= new symbolInfo(yytext,"LOGICOP");
			yylval = (YYSTYPE)s;
			return LOGICOP;	
		}

"++"	{return INCOP;}

"--"	{return DECOP;}

"="		{return ASSIGNOP;}
		
"!"		{return NOT;}
		
"("		{return LPAREN;}

")" 	{return RPAREN;}

"{" 	{return LCURL;}

"}" 	{return RCURL;}

"[" 	{return LTHIRD;}

"]" 	{return RTHIRD;}		

";" 	{return SEMICOLON;}

"," 	{return COMMA;}

"'\\a'" {
			int c=7;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\b'" {
			int c=8;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\v'" {
			int c=11;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\f'" {
			int c=12;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\t'" {
			int c=9;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\n'" {
			int c=10;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\r'" {
			int c=13;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\\"'" {
			int c=34;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\\''" {
			int c=39;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"'\\0'" {	int c=0;
			string char_str;
			char_str[0]=(char)c;
			symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
			yylval = (YYSTYPE)s;
			return CONST_CHAR;
		}

"/*" 						{BEGIN comments;}						
<comments>([\*])+[/]		{BEGIN INITIAL;}
<comments>[^*\r\n]			{}
<comments>"*"+([^*\r\n])*	{}
<comments>\r\n   			{line_count++;}
<comments><<EOF>> 			{error_cnt++;line_count--;
							BEGIN INITIAL;}	
			
"//"					{BEGIN acomments;}
<acomments>[/]\r\n		{line_count++;}
<acomments>[^/]\r\n		{BEGIN INITIAL;line_count++;}
<acomments>[^/\r\n]		{}

\"						{BEGIN str;						 
						str_start=line_count;
						strcpy(str_buf,"");
						strcpy(str_log,"\"");}
						
<str>\"					{strcat(str_log,yytext);
						BEGIN INITIAL;}							
						                 
<str>\\n				{strcat(str_buf,"\n"); strcat(str_log,yytext); }	
<str>\\t				{strcat(str_buf,"\t"); strcat(str_log,yytext);}	
<str>\\r				{strcat(str_buf,"\r"); strcat(str_log,yytext); }	
<str>\\v				{strcat(str_buf,"\v"); strcat(str_log,yytext);}	

<str>\\\\				{strcat(str_buf,"\\"); strcat(str_log,yytext);}
<str>\\\"				{strcat(str_buf,"\"");strcat(str_log,yytext);}	
<str>\\\'				{strcat(str_buf,"\'");strcat(str_log,yytext);}

<str>\\\r\n				{strcat(str_log,yytext); line_count++;}
	
<str>([^\\\"\r\n])*		{strcat(str_buf,yytext); strcat(str_log,yytext);}

<str>\r\n 				{BEGIN INITIAL; line_count++; error_cnt++;}

{SCOMMENT}	{line_count++;}			                     
			
{IDENTIFIER} { 	s = new symbolInfo(yytext,"ID");
				yylval = (YYSTYPE)s;
				return ID; 
			}
		
{INTEGER} 	{ 	symbolInfo* s= new symbolInfo(yytext,"CONST_INT");
				yylval = (YYSTYPE)s;
				return CONST_INT; 
			}

{FLOAT} 	{ 	symbolInfo* s= new symbolInfo(yytext,"CONST_FLOAT");
				yylval = (YYSTYPE)s;
				return CONST_FLOAT; 
			}		

{CHAR} 		{		
				string char_str;
				char_str[0]=yytext[1];
				symbolInfo* s= new symbolInfo(char_str,"CONST_CHAR");
				yylval = (YYSTYPE)s;
				return CONST_CHAR; 
			}	

. 			{
				error_cnt++;
				//fprintf(logout,"\nError at line %d: Unrecognized character %s \n",yytext);
			} 

%%
