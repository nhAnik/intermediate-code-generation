%{
#include<iostream>
#include <sstream>
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<string>
#include<cmath>
#include<algorithm>
#include "SymbolTable.cpp"

#define YYSTYPE symbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

FILE *fp;
FILE *codeFp;
FILE *modCodeFp;
FILE *logFp;

symbolInfo *s;
symbolInfo *temp = NULL,*htemp = NULL;
symbolInfo *tempFnc;
symbolInfo *tempVar;
symbolInfo *tempIncr, *tempDecr;
symbolInfo *tempArg;

int befIncr,befDecr;

vector<string> paramList;
vector<string> paramType;

vector<string> argList;
vector<string> argName;
int argCnt,parIdx;

vector<symbolInfo*> declList;

int tempIdx=-1;
string type;

symbolTable *st = new symbolTable();
int line_count=1;
int error_cnt=0;
bool voidError = false;

bool isInt(float a){
	int x=(int)a;
	if (a-x == 0) {	 
		return true;
	}
	return false;
}

void yyerror(char *s)
{
	 
	fprintf(stderr,"%s\n",s);
	 
	return;
}

int labelCount=0;
int tempCount=0;

char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}

string mkstr(string s,string s1){ 
	string prod = "";
	 
	prod = s + s1;
	return prod;
}

string itos(int x){ 
	if (x==0) return "";
	char *intStr = new char[4]; 
	sprintf(intStr,"%d",x);
    return string(intStr); 
}

symbolInfo* tempSym;

string dataCode="";
string popCode="";
string retCode="";
string mainFncCode;
string mainFncCode1;
string printLnFnc;

vector<string> otherFnc;
vector<string> otherFnc1;

symbolInfo *tempArgRet;

bool printlnFlag = true;


string opt(string s){
	if (s == "") return s;
	string x,y;
	string m,n,m1,n1,m2,n2,m3,n3;
	vector<string> line,word1,word2;
	stringstream ss(s);
   	string to,to1,to2;
   	
	if (s != "")
 	{
    	while(getline(ss,to,'\n')){
    		line.push_back(to);
    	}
  	} 
  	
	bool eraseFlag, eraseFlag1; 
  	for (int i=0; i<line.size()-1; i++){
  		x = line[i];
  		y = line[i+1]; 
  		
  		stringstream ss1(x);
  		stringstream ss2(y);
  		eraseFlag = eraseFlag1 = false;
  		
  		if (ss1.str() != "" && ss2.str() != ""){
  			getline(ss1,m1,' ');
  			getline(ss2,n1,' ');
  			
  			if (m1 == "mov" && n1 == "mov"){
	  			 
	  			getline(ss1,m2,',');	  		 
	  			getline(ss1,m,' ');
	  			getline(ss1,m3);
	  		 	
	  		 	getline(ss2,n2,',');	  		 
	  			getline(ss2,n,' ');
	  			getline(ss2,n3);
	  			
	  			 
	  			if (m2[0]=='t' && n3[0]=='t' && m2==n3 && n2==m3) {
	  				eraseFlag = true; 
	  			}
	  			else if (m2==n3 && n2==m3){
	  				eraseFlag1 = true;
	  			}
	  		}
  		}
  		if (eraseFlag) {
  			line.erase(line.begin()+i);
  			line.erase(line.begin()+i);
  			i--;
  		}
  		else if (eraseFlag1){
  			line.erase(line.begin()+i+1);
  		}
  	 
  	}
  	
  	string newStr="";
  	for (int i=0; i<line.size(); i++) {
  		//cout << line[i]<<endl;
  		newStr += line[i];
  		newStr += "\n";
  	}
  	return newStr;
}

%}

%token IF ELSE FOR WHILE DO BREAK CONTINUE INT CHAR FLOAT DOUBLE VOID RETURN

%token ADDOP MULOP RELOP LOGICOP INCOP DECOP ASSIGNOP NOT SEMICOLON COMMA

%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD

%token ID CONST_INT CONST_FLOAT CONST_CHAR STRING PRINTLN

 
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start start

%%

start : program
	{	
		string initial=".model small\n.stack100h\n\n.data\n"+dataCode+"\n.code\n";
		$$->code += initial+mainFncCode; 
		
 		for (int i=0 ; i < otherFnc.size(); i++){
 			$$->code += otherFnc[i];
 			$$->code += "\n";
 		}
 		if (printLnFnc != "") $$->code += printLnFnc;
		$$->code+="\tend main";
		fprintf(codeFp,$$->getCode().c_str());
		 
		$$->code = "";
		$$->code += initial+mainFncCode1; 
		
 		for (int i=0 ; i < otherFnc1.size(); i++){
 			$$->code += otherFnc1[i];
 			$$->code += "\n";
 		}
 		if (printLnFnc != "") $$->code += printLnFnc;
		$$->code+="\tend main";
		fprintf(modCodeFp,$$->getCode().c_str());
		 
		fprintf(logFp,"\nTotal Lines : %d\n",line_count-1);
		fprintf(logFp,"\nTotal Errors : %d\n",error_cnt);
	}
	;

program : program unit
	{	
		 	 
	} 
	| 
	unit
	{
		 	 
	}
	;
	
unit : 	var_declaration
		{
			 
		}
     	| 
     	func_declaration
     	{
			 
     	}
     	| 
     	func_definition
     	{ 
     		 
     	}
     	;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
			{
				st->exitScope();
				s=new symbolInfo($2->getName(),$2->getType());
				s->isFnc=true;
				s->makeDecl();
				 
				s->addFncInfo(paramList, paramType, $1->getName());
				
				paramList.clear();
				paramType.clear();
				popCode.clear();
				
 		  		if (st->lookUpSym(s->getName()) == false) {
 		  			st->insertSym(s);
 		  			 
 		  		}
 		  		else {
 		  			//error
 		  			fprintf(logFp,"\nError at line %d : Multiple declaration of function\n%s\n",line_count,s->getName().c_str());	
 		  			 
 		  			error_cnt++;
 		  		}
 		  			
			}
		 	; 
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
			{  
				st->exitScope();
				s=new symbolInfo($2->getName(),$2->getType());
				s->isFnc=true; 
				s->addFncInfo(paramList, paramType, $1->getName());
				
 		  		if (st->lookUpSym(s->getName()) == false) {
 		  			st->insertSym(s);
 		  			
 		  			if ($2->getName() == "main") {
 		  				 
 		  				if (dataCode != "") {
 		  					mainFncCode = "main proc\n\nmov ax,@data\nmov ds,ax\n\n"+$6->code+"\nmov ah,4ch\nint 21h\nmain endp\n\n";
 		  					mainFncCode1 = "main proc\n\nmov ax,@data\nmov ds,ax\n\n"+opt($6->code)+"\nmov ah,4ch\nint 21h\nmain endp\n\n";
 		  				}
 		  				else {
 		  					mainFncCode = "main proc\n\n"+$6->code+"\nmov ah,4ch\nint 21h\nmain endp\n";
 		  					mainFncCode1 = "main proc\n\n"+opt($6->code)+"\nmov ah,4ch\nint 21h\nmain endp\n";
 		  				}
 		  			}
 		  			else {
 		  				tempFnc = st->findAndRetSym(s->getName());
 		  				
 		  				
 		  				if(tempFnc->fi->retType != "void"){
	 		  				char *temp = newTemp();
	 		  				tempFnc->setRet(string(temp));
	 		  				st->findAndUpdateSym(tempFnc->getName(), tempFnc);
	 		  				retCode = "mov "+string(temp)+",ax\n";
 		  				}
 		  				
 		  				otherFnc.push_back($2->getName()+" proc\n\n"+popCode+"\npush ax\npush bx\n\n"+$6->code+
 		  					retCode+"\npop bx\npop ax\nret \n"+$2->getName()+" endp\n\n");
 		  				otherFnc1.push_back($2->getName()+" proc\n\n"+popCode+"\npush ax\npush bx\n\n"+opt($6->code)+
 		  					retCode+"\npop bx\npop ax\nret \n"+$2->getName()+" endp\n\n");
 		  				popCode.clear();
 		  				retCode = "";
 		  				 
 		  			}
 		  			 
 		  		}
 		  		else {
 		  			tempFnc = st->findAndRetSym(s->getName());
 		  			if (tempFnc->getFncFlag() == true) {
 		  				 fprintf(logFp,"\nError at line %d : Multiple definition of function\n%s\n",line_count,s->getName().c_str());
 		  				 error_cnt++;	
 		  			}
 		  			else {
 		  				if (tempFnc->fi->retType != $1->getName()){
 		  					fprintf(logFp,"\nError at line %d : Return type mismatch with declaration of function\n%s\n",line_count,s->getName().c_str()); 
 		  					error_cnt++;
 		  				} 
 		  				 
 		  				if (paramType.size() == tempFnc->fi->paramCnt){
 		  					 
 		  					bool fncDefError = false;
 		  					for (int i=0 ;i < paramList.size(); i++){
 		  						
 		  						if (tempFnc->fi->paramType[i] != paramType[i]){
 		  							
 		  							fprintf(logFp,"\nError at line %d : %dth parameter type mismatch with declaration of function\n%s\n",line_count,i+1,s->getName().c_str()); 	
 		  							error_cnt++;
 		  							fncDefError = true;
 		  						}
 		  					}
 		  				
 		  					if (fncDefError == false){
 		  						tempFnc->makeFnc();	
 		  						st->findAndUpdateSym(tempFnc->getName() , tempFnc); 
 		  						
 		  						if(tempFnc->fi->retType != "void"){
			 		  				char *temp = newTemp();
			 		  				tempFnc->setRet(string(temp));
			 		  				st->findAndUpdateSym(tempFnc->getName(), tempFnc);
			 		  				retCode = "mov "+string(temp)+",ax\n";
 		  						}
 		  						
 		  						otherFnc.push_back($2->getName()+" proc\n\n"+popCode+"\npush ax\npush bx\n\n"+$6->code+
 		  							retCode+"\npop bx\npop ax\nret \n"+$2->getName()+" endp\n\n");
 		  						otherFnc1.push_back($2->getName()+" proc\n\n"+popCode+"\npush ax\npush bx\n\n"+opt($6->code)+
 		  							retCode+"\npop bx\npop ax\nret \n"+$2->getName()+" endp\n\n");
 		  						popCode.clear();
 		  						retCode = "";
 			  				}
 		  				}
 		  		
 		  				else { 
 		  					fprintf(logFp,"\nError at line %d : Parameter count mismatch with declaration of function\n%s\n",line_count,s->getName().c_str()); 	
 		  					error_cnt++;
 		  				}
 		  			}
 		  	
				}
				paramList.clear();
				paramType.clear();
			}		
		 	;
 		 
parameter_list  : parameters
				{
					 
				}
				|
				{
					st->enterScope(); 
				}
				;

parameters : parameters COMMA type_specifier ID
			{
				 
 		  		if (st->lookUpSymCur(s->getName()) == false) {
 		  			paramList.push_back($4->getName());
 		    		paramType.push_back($3->getName());
 		    		if ($3->getName() == "void"){
 		    			fprintf(logFp,"\nError at line %d : Parameter %s is declared void\n",line_count,$4->getName().c_str());
						error_cnt++;
						 
 		    		}    		
 		    		s->isVar=true;
 		  			st->insertSym(s);
 					dataCode += mkstr(s->getName(), st->findID(s->getName())) + " dw ?\n";
 					popCode += "pop "+ mkstr(s->getName(), st->findID(s->getName()))+"\n";
				}
				else { 
					fprintf(logFp,"\nError at line %d : Parameter named %s is already declared\n",line_count,$4->getName().c_str());
					error_cnt++;
				}
			} 
 		    | type_specifier ID
 		    { 
 		    	st->enterScope();
 		    	 
 		    	if (st->lookUpSymCur(s->getName()) == false) {
 		  			paramList.push_back($2->getName());
 		    		paramType.push_back($1->getName());
 		    		if ($1->getName() == "void"){
 		    			fprintf(logFp,"\nError at line %d : Parameter %s is declared void\n",line_count,$2->getName().c_str());
						error_cnt++;
 		    		}
 		    		
 		    		s->isVar=true;
 		  			st->insertSym(s);
 		  			dataCode += mkstr(s->getName(), st->findID(s->getName())) + " dw ?\n" ;	
 		  			popCode += "pop "+ mkstr(s->getName(), st->findID(s->getName()))+"\n";
				}
				else {
					fprintf(logFp,"\nError at line %d : Parameter named %s is already declared\n",line_count,$2->getName().c_str());
					error_cnt++;
				}
 		    } 
 		    ;
 		
compound_statement : LCURL statements RCURL
			{
				 $$=$2; 
			}
 		    | LCURL RCURL
 		    {
 		    	 
 		    }
 		    | LCURL statements error
 		    {
 		    	fprintf(logFp,"\nError at line %d : Closing braces missing\n",line_count);
 		    	error_cnt++;	
 		    }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON 
				{
					for (int i=0; i<declList.size(); i++){
						if ($1->getName()=="int") {
							declList[i]->isInt = true;
							st->insertSym(declList[i]);
							tempSym = st->findAndRetSym(declList[i]->getName());
							if (tempSym->isVar) dataCode += mkstr(tempSym->getName(),st->findID(tempSym->getName())) + " dw " + "?\n";
							
							else if (tempSym->isArr){
								 
								dataCode += mkstr(tempSym->getName(),st->findID(tempSym->getName())) + " dw "; 
								for(int j=0; j<tempSym->getSize(); j++){
									dataCode += "? ";
								}
								dataCode+="\n";
							}
						}
						else if ($1->getName()=="float") {
							declList[i]->isFloat = true;
							st->insertSym(declList[i]);
						}
						else if ($1->getName()=="void"){
							fprintf(logFp,"\nError at line %d : Variable %s cannot be declared void\n",line_count,declList[i]->getName().c_str()); 
							error_cnt++;
						}//error
						 	 
					}
					declList.clear(); 
				}
				| type_specifier declaration_list error
				{
					fprintf(logFp,"\nError at line %d : Semicolon missing after declaration\n",line_count); 
					error_cnt++;
				}
 		    	;
 		    	
 		 
type_specifier	: INT   
		{ 
			$$->setName($1->getName());
		}
 		| FLOAT 		
 		{ 
 			$$->setName($1->getName());  
 		}
 		| VOID  		
 		{ 
 			$$->setName($1->getName());	  
 		}
 		;
 		
declaration_list : declaration_list COMMA ID  
				{
					if (st->lookUpSymCur(s->getName()) ==  true) {
						fprintf(logFp,"\nError at line %d : Multiple declaration of variable\n%s\n",line_count,s->getName().c_str()); 
						error_cnt++;
					}
					else {
						s=new symbolInfo($3->getName(),$3->getType());
						s->isVar=true;
						declList.push_back(s);//st->insertSym(s); 
 		 			}
 		 		}
 		  		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
 		  		{
 		  			if (st->lookUpSymCur(s->getName()) ==  true) {
						fprintf(logFp,"\nError at line %d : Multiple declaration of array\n%s\n",line_count,s->getName().c_str()); 
						error_cnt++;
					}
					else {
 		  				s=new symbolInfo($3->getName(),$3->getType());
 		  				s->isArr=true; 
 		  				s->setSize(atoi($5->getName().c_str())); 
 		  				declList.push_back(s);//st->insertSym(s); 
 		  			}
 		  			 	
 		  		}
 		  		| ID 
 		  		{
 		  			if (st->lookUpSymCur(s->getName())== true) {
 		  				fprintf(logFp,"\nError at line %d : Multiple declaration of variable\n%s\n",line_count,s->getName().c_str()); 
 		  				error_cnt++;
 		  			} 
 		  			else {
 		  				s=new symbolInfo($1->getName(),$1->getType());
 		  				s->isVar=true;
 		  				declList.push_back(s);//st->insertSym(s); 
 		  			}
 		  			 
 		  			 
 		 		}
 		  		| ID LTHIRD CONST_INT RTHIRD 
 		  		{
 		  			if (st->lookUpSymCur(s->getName())== true) {
 		  				fprintf(logFp,"\nError at line %d : Multiple declaration of array\n%s\n",line_count,s->getName().c_str()); 
 		  				error_cnt++;	
 		  			} 
 		  			else {
 		  				s=new symbolInfo($1->getName(),$1->getType());
 		  				s->isArr=true; 
 		  				s->setSize(atoi($3->getName().c_str()));
 		  				declList.push_back(s);//st->insertSym(s); 
 		  			}
 		 		}
 		 		;
 		  
statements : statement
		{
			 $$= $1;
		}
	    | statements statement
	    {	
	    	$$=$1;
			$$->code += $2->code;  
	    }
	    ;
	   
statement : var_declaration
		{
			 
		}
		| expression_statement
		{
			$$= $1;	 
		}
	    | compound_statement
	    {
	    	$$=$1;	
	    	  	
	    }
	    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	    {
	    	 $$=$3;	
	    	 char *label1=newLabel(); 
			 char *label2=newLabel();
			 $$->code+=string(label1)+":\n";
			 
			 $$->code+=$4->code;
			 $$->code+="mov ax, "+mkstr($4->getName(),st->findID($4->getName()))+"\n";
			 $$->code+="cmp ax, 0\n";
			 $$->code+="je "+string(label2)+"\n";
			 $$->code+=$7->code;
			 $$->code+=$5->code;
			 $$->code+="jmp "+string(label1)+"\n";
			 $$->code+=string(label2)+":\n";
			  
	    }
	    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE 
	    {
	    	$$=$3;		
			char *label=newLabel();
			$$->code+="mov ax, "+mkstr($3->getName(),st->findID($4->getName()))+"\n";
			$$->code+="cmp ax, 0\n";
			$$->code+="je "+string(label)+"\n";
			$$->code+=$5->code;
			$$->code+=string(label)+":\n";
			 	
	    }
	    | IF LPAREN expression RPAREN statement ELSE statement
	    {
	    	$$=$3;		
			char *label1=newLabel(); 
			char *label2=newLabel();
			$$->code+="mov ax, "+mkstr($3->getName(),st->findID($3->getName()))+"\n";
			$$->code+="cmp ax, 0\n";
			$$->code+="je "+string(label1)+"\n";
			$$->code+=$5->code;
			$$->code+="jmp "+string(label2)+"\n";
			$$->code+=string(label1)+":\n"+$7->code;
			$$->code+=string(label2)+":\n";
			 
	    }
	    | WHILE LPAREN expression RPAREN statement
	    {  
	    	char *label1=newLabel(); 
			char *label2=newLabel();
			$$->code = string(label1)+":\n";
			
			$$->code += $3->code;
			$$->code += "mov ax, "+mkstr($3->getName(),st->findID($3->getName()))+"\n";
			$$->code += "cmp ax, 0\n";
			$$->code += "je "+string(label2)+"\n";
			$$->code += $5->code;
			$$->code += "jmp "+string(label1)+"\n";
			$$->code += string(label2)+":\n";
			
			 
	    }
	    | PRINTLN LPAREN ID RPAREN SEMICOLON
	    {
	    	tempVar = st->findAndRetSym($3->getName());
	    	if (tempVar == NULL){
	    		fprintf(logFp,"\nError at line %d : Undeclared variable\n%s\n",line_count,$3->getName().c_str()); 
 		  		error_cnt++;
	    	}
	    	else {
	    		if (printlnFlag){
	    			char *temp = newTemp(); 
					printLnFnc += "println proc\npop "+string(temp)+"\npush ax\npush dx\n\n";
					printLnFnc += "lea dx, "+string(temp)+"\n"+"mov ah,1\nint 21h\n";
					printLnFnc += "\npop dx\npop ax\nret\nprintln endp\n";
					printlnFlag = false;
				}
				$$ = new symbolInfo("","");
				$$->code += "push "+mkstr($3->getName(),st->findID($3->getName()))+"\n";
				$$->code += "call println\n";
	    	}
	    }
	    | RETURN expression SEMICOLON
	    {
	    	//char *temp = newTemp(); 
	  		$$ = $2;  
	  		$$->code += "mov ax, "+mkstr($2->getName(),st->findID($2->getName()))+"\n";
	  		//$$->code += "mov "+string(temp)+" ,ax\n";
	    }  
	    ;
	  
expression_statement 	: SEMICOLON	
			{
				 	
			}		
			| expression SEMICOLON 
			{ 
				 $$= $1;
			} 
			| expression error
			{
				fprintf(logFp,"\nError at line %d : Semicolon missing after an expression\n",line_count);
				error_cnt++;
			}
			;
	  
variable : ID
		{ 
 		  	tempVar = st->findAndRetSym($1->getName());
 		  
 		  	if (tempVar == NULL){
 		  		//error
 		  		fprintf(logFp,"\nError at line %d : Undeclared variable\n%s\n",line_count,$1->getName().c_str()); 
 		  		error_cnt++;
 		  	}
 		  	else {
 		  		if (tempVar->isArr == true){
 		  			fprintf(logFp,"\nError at line %d : No index on array\n%s\n",line_count,$1->getName().c_str()); 
 		  			error_cnt++;
 		  		}
 		  		else if (tempVar->isVar == true){
 		  			 
 		  			$$->isVar = true;
 		  			$$->code = "";
 		  			$$->isInt = tempVar->isInt;
 		  			$$->isFloat = tempVar->isFloat;
 		  		}
 		  	}
 		  	 
		}	
	 	| ID LTHIRD expression RTHIRD 
	 	{
	 		//s=$1;
	 		if (st->lookUpSym($1->getName()) == true) {
	 			
				temp = st->findAndRetSym($1->getName());
				
				if (temp->isArr != true){
					fprintf(logFp,"\nError at line %d : Index on non-array\n%s\n",line_count,$1->getName().c_str()); 
					error_cnt++;
				}
				else if (temp->isArr == true){
					
					if ($2->isVoid){
						fprintf(logFp,"\nError at line %d : Void function cannot be used in an expression\n%",line_count); 
					}
					 
					if ($3->isInt == true){
						
						$$->isArr = true;
	 					$$->code=$3->code+"mov bx, " +mkstr($3->getName(),st->findID($3->getName()))+"\nadd bx, bx\n";				
						delete $3;
						
 		  				$$->isInt = temp->isInt;
 		  				$$->isFloat = temp->isFloat;
 		  			}
 		  			else {
 		  				fprintf(logFp,"\nError at line %d : Index is not an integer for array\n%s\n",line_count,$1->getName().c_str());  
 		  				error_cnt++;
 		  			}
 		  			 
 		  		}
 		  }
 		  else {
				fprintf(logFp,"\nError at line %d : Undeclared array\n%s\n",line_count,$1->getName().c_str());  	
				error_cnt++;  
 		  }	
 		  	 
	 	}
	 	;
	 
expression : logic_expression	
	    {   
	   		$$= $1;
	   		if (voidError) {
	   			fprintf(logFp,"\nError at line %d : Void function cannot be used in an expression\n%",line_count);  
	   			error_cnt++;
				voidError = false;
	   		}
	   		$$->isVoid = $1->isVoid;
	   		  	 
	    }			
		| variable ASSIGNOP logic_expression 
		{
			temp = st->findAndRetSym($1->getName());
			 				
			if (temp != NULL) {
				 	
				if ($3->isVoid == true){
					fprintf(logFp,"\nError at line %d : Void function cannot be used in an expression\n%",line_count);  
					error_cnt++;
					voidError = false;
				}
				
				if (($1->isInt == true && $3->isFloat == true) || ($1->isFloat == true && $3->isInt == true)) {
					
					fprintf(logFp,"\nError at line %d : Type mismatch between assignment operator\n%",line_count);   
					error_cnt++;
				}
				 
				$$->code=$3->code+$1->code;
				$$->code+="mov ax, "+mkstr($3->getName(),st->findID($3->getName()))+"\n";
				
				if (temp->isVar == true) {	
					$$->code+= "mov "+mkstr($1->getName(),st->findID($1->getName()))+", ax\n";
				}
				else if (temp->isArr == true ){
					$$->code+= "mov  "+ mkstr($1->getName(),st->findID($1->getName())) +"[bx], ax\n";	 
				} 
				//delete $3;
 				 	 
			}
			
	  
		}	
	    ;
			
logic_expression : rel_expression 	
		 { 
		 	$$= $1; 
		  	$$->isInt = $1->isInt;
 			$$->isFloat = $1->isFloat; 
 			$$->isVoid = $1->isVoid;
		 }
		 | rel_expression LOGICOP rel_expression 
		 { 
		 	if ($1->isVoid == true || $3->isVoid == true) {
		 		voidError = true;
		 		$$->isVoid = true;
		 	}
		 	
		 	
		 	if ($2->getName() == "&&") {
		 		char *temp=newTemp();
				char *label1=newLabel();
				char *label2=newLabel();
				$$=$1;
				$$->code+=$3->code;
				
				$$->code+="mov ax, " + mkstr($1->getName(),st->findID($1->getName()))+"\n";
				$$->code+="cmp ax, 1\n";
				$$->code+="jne "+string(label1)+"\n";
				$$->code+="mov ax, " + mkstr($3->getName(),st->findID($3->getName()))+"\n";
				$$->code+="cmp ax, 1\n";
				$$->code+="jne "+string(label1)+"\n";
				
				$$->code+="mov "+string(temp)+", 1\n";
				$$->code+="jmp "+string(label2)+"\n";
				$$->code+=string(label1)+":\n";
				$$->code+="mov "+string(temp)+", 0\n";
				$$->code+=string(label2)+":\n";
				
				$$->setName(temp);
				 
				delete $3;
		 	}
		  			 
		  	else if ($2->getName() == "||") {
		  		char *temp=newTemp();
				char *label1=newLabel();
				char *label2=newLabel();
				$$=$1;
				$$->code+=$3->code;
				
				$$->code+="mov ax, " + mkstr($1->getName(),st->findID($1->getName()))+"\n";
				$$->code+="cmp ax, 1\n";
				$$->code+="je "+string(label1)+"\n";
				$$->code+="mov ax, " + mkstr($3->getName(),st->findID($3->getName()))+"\n";
				$$->code+="cmp ax, 1\n";
				$$->code+="je "+string(label1)+"\n";
				
				$$->code+="mov "+string(temp)+", 0\n";
				$$->code+="jmp "+string(label2)+"\n";
				$$->code+="\n"+string(label1)+":\n";
				$$->code+="mov "+string(temp)+", 1\n";
				$$->code+="\n"+string(label2)+":\n";
				
				$$->setName(temp);
				 
				delete $3;
		  	}
		   
		  	$$->isInt = true;
		  	$$->isFloat = false; 
		 }	
		 ;
			
rel_expression	: simple_expression 
		{  
			$$= $1;
			$$->isInt = $1->isInt;
 			$$->isFloat = $1->isFloat;
 			$$->isVoid = $1->isVoid;
		}
		| simple_expression RELOP simple_expression	
		{ 
			if ($1->isVoid == true || $3->isVoid == true) {
				voidError = true;
				$$->isVoid = true;
			}
			
			$$=$1;
			$$->code+=$3->code;
			$$->code+="mov ax, " + mkstr($1->getName(),st->findID($1->getName()))+"\n";
			$$->code+="cmp ax, " + mkstr($3->getName(),st->findID($3->getName()))+"\n";
			char *temp=newTemp();
			char *label1=newLabel();
			char *label2=newLabel();
		  	
		  	if ($2->getName() == "<") $$->code+="jl " + string(label1)+"\n";
		  			 
		  	else if ($2->getName() == "<=") $$->code+="jle " + string(label1)+"\n";
		  	
		  	else if ($2->getName() == ">") $$->code+="jg " + string(label1)+"\n";
		  			 
		  	else if ($2->getName() == ">=") $$->code+="jge " + string(label1)+"\n";
		  		
		  	else if ($2->getName() == "==") $$->code+="je " + string(label1)+"\n";
		  			 
		  	else if ($2->getName() == "!=") $$->code+="jne " + string(label1)+"\n";
		  	
		  	$$->code+="mov "+string(temp) +", 0\n";
			$$->code+="jmp "+string(label2) +"\n";
			$$->code+=string(label1)+":\nmov "+string(temp)+", 1\n";
			$$->code+=string(label2)+":\n";
			$$->setName(temp);
			 
		  	
		  	$$->isInt = true;
		  	$$->isFloat = false;
 
		}
		;
				
simple_expression : term
			{  
				$$= $1; 
				
		  		$$->isInt = $1->isInt;
 				$$->isFloat = $1->isFloat;
 				$$->isVoid = $1->isVoid;
			} 
		  	| simple_expression ADDOP term 
		  	{ 
		  		if ($1->isVoid == true || $3->isVoid == true) {
		  			voidError = true;
		  			$$->isVoid = true;
		  		}
		  		
		  		$$=$1;
				$$->code+=$3->code;
				$$->code += "mov ax, "+ mkstr($1->getName(),st->findID($1->getName())) +"\n";
				char *temp=newTemp();
				
		  		if ($2->getName() == "+") $$->code += "add ax, "+ mkstr($3->getName(),st->findID($3->getName()))+"\n";
		  			 
		  		else if ($2->getName() == "-") $$->code += "sub ax, "+ mkstr($3->getName(),st->findID($3->getName()))+"\n";
		  		
		  		$$->code += "mov "+ string(temp) + ", ax\n";
				$$->setName(temp);
		  		 
		  		if ($1->isInt && $3->isInt) $$->isInt = true;
		  		else $$->isInt = false;
		  		
		  		delete $3;
		  		
		  	}
		  	;
					
term :	unary_expression
	 { 
	 	$$= $1;
	 	
	 	$$->isInt = $1->isInt;
 		$$->isFloat = $1->isFloat;
 		$$->isVoid = $1->isVoid;
	 }
     |  term MULOP unary_expression
     {
		if ($1->isVoid == true || $3->isVoid == true) {
			voidError = true;
			$$->isVoid = true;
		}
		
		$$=$1;
		$$->code += $3->code;
		$$->code += "mov ax, "+ mkstr($1->getName(),st->findID($1->getName()))+"\n";
		$$->code += "mov bx, "+ mkstr($3->getName(),st->findID($3->getName())) +"\n";
		char *temp=newTemp();
		
		if ($2->getName() == "*") {
			 
			$$->code += "mul bx\n";
			$$->code += "mov "+ string(temp) + ", ax\n";
			
			if ($1->isInt && $3->isInt) $$->isInt = true;		
			else $$->isInt = false; 
		}
		
		else if ($2->getName() == "/") {
			
			$$->code += "div bx\n";
			$$->code += "mov "+ string(temp) + ", ax\n";
			
			if ($1->isInt && $3->isInt) $$->isInt = true;
			else $$->isInt = false; 
		}
		
		else if ($2->getName() == "%") {
	 
			if ($1->isInt == true && $3->isInt == true) {
				
				$$->code += "div bx\n";
				$$->code += "mov "+ string(temp) + ", dx\n";
				$$->isInt = true;
			}
			else { 
				 fprintf(logFp,"\nError at line %d : Non-integer operand for Modulus operator\n",line_count);
				 error_cnt++;
			} 
		}
		
		$$->setName(temp); 
		delete $3;
     }
     ;

unary_expression : ADDOP unary_expression 
		 {
		 	if ($1->getName() == "+") {}
		 	
		 	else if ($1->getName() == "-") {
		 		$$->code += $2->code;
		 		char *temp=newTemp();
		 		$$->code += "mov ax, "+mkstr($2->getName(),st->findID($2->getName()))+"\n";
		 		$$->code += "neg ax\n";
		 		$$->code += "mov "+ string(temp) + ", ax\n";
		 		$$->setName(temp);
		 	}
		 	 
		 	$$->isInt = $2->isInt;
 			$$->isFloat = $2->isFloat;
 			if ($2->isVoid == true) {
 				voidError = true;
 				$$->isVoid = true;
 			}
 			
 			delete $2;
		 } 
		 | NOT unary_expression
		 {  
		 	$$->code += $2->code;
			char *temp=newTemp();
			char *label1=newLabel();
			char *label2=newLabel();
	 		$$->code += "mov ax, "+mkstr($2->getName(),st->findID($2->getName()))+"\n";
	 		$$->code += "cmp ax, 0\n";
	 		$$->code+="je " + string(label1) + "\nmov " + string(temp) +", 0\njmp " + string(label2)+"\n";
			$$->code+=string(label1)+":\nmov "+string(temp) + ", 1\n" + string(label2) + ":\n";
			$$->setName(temp); 
		 		
		 	$$->isInt = true;
		 	if ($2->isVoid == true) {
		 		voidError = true;
		 		$$->isVoid = true;
		 	}
		 	
		 	delete $2;
		 	
		 } 
		 | factor 
		 { 
			$$= $1;
			
			$$->isInt = $1->isInt;
 			$$->isFloat = $1->isFloat;
 			$$->isVoid = $1->isVoid;
		 }
		 ;
	
factor	: variable 
		{  
			$$= $1; 
			
			if($$->isVar){ 
			
			}
			else if ($$->isArr){
				char *temp= newTemp();
				$$->code+="mov ax, " + mkstr($1->getName(),st->findID($1->getName())) + "[bx]\n";
				$$->code+= "mov " + string(temp) + ", ax\n";
				$$->setName(temp);
			}
			
			$$->isInt = $1->isInt;
 			$$->isFloat = $1->isFloat;
		}
		| ID LPAREN argument_list RPAREN
		{
			
			tempArg = st->findAndRetSym($1->getName());
			if (tempArg == NULL) {
				//error 
				fprintf(logFp,"\nError at line %d : Undeclared function\n%s\n",line_count,$1->getName().c_str());
				error_cnt++;
			}
			else if (tempArg->isFnc == false){
				fprintf(logFp,"\nError at line %d : Function call by non-function type identifier\n%s\n",line_count,$1->getName().c_str());	
				error_cnt++;
			}
		  	else {
				if (tempArg->getFncFlag() == true){
					cout <<$1->getName()<< tempArg->fi->paramCnt << argName.size()<<endl;
					if (tempArg->fi->paramCnt == argName.size()){
						bool argError = false;
						for(int i=0; i<argList.size(); i++){
							if (tempArg->fi->paramType[i] != argList[i]){
								//error
								fprintf(logFp,"\nError at line %d : %dth parameter type mismatch with definition of function\n%s\n",line_count,i+1,$1->getName().c_str()); 
								error_cnt++;
								argError = true;
							}
						}
						if (argError == false){
							
							$$ = $3;
							$$ ->code += "\n";
							 
							for (int i=argName.size()-1; i>=0; i--){
								$$->code += "push "+ mkstr(argName[i], st->findID(argName[i])) + "\n";
							 
							} 
							
							$$->code += "call " + $1->getName() + "\n\n";
							 
							
							tempArgRet = st->findAndRetSym($1->getName());
							if (tempArg->fi->retType != "void") $$->setName(tempArgRet->getRet());
							
							if (tempArg->fi->retType == "void") $$->isVoid = true;
							else { 
								if (tempArg->fi->retType == "int") $$->isInt = true;
								else if (tempArg->fi->retType == "float") $$->isFloat = true;
							} 
						}
					}
					else {
						//error
						fprintf(logFp,"\nError at line %d : Parameter count mismatch with definition of function\n%s\n",line_count,$1->getName().c_str()); 
						error_cnt++;
					}
				}
				else {
					fprintf(logFp,"\nError at line %d : Declared but not defined function\n%s\n",line_count,$1->getName().c_str()); 
					error_cnt++;
					//error
				}
			}
			
			argList.clear();
			argName.clear();
		 
		}
		| LPAREN expression RPAREN
		{   
			$$ = $2;
			$$->isInt = $2->isInt;
			$$->isFloat = $2->isFloat;
		}
		| CONST_INT  
		{  
			$$ = $1;
			$$->isInt =true;
		}
		| CONST_FLOAT
		{  
			$$ = $1;
			$$->isFloat = true;
		}
		| CONST_CHAR
		| variable INCOP
		{  
			tempIncr = st->findAndRetSym($1->getName());
			 
			if (tempIncr->isVar) $$->code += "mov ax, "+mkstr($1->getName(),st->findID($1->getName()))+"\n";
 			else if (tempIncr->isArr) $$->code += "mov ax, "+mkstr($1->getName(),st->findID($1->getName()))+"[bx]\n";
 			
 			char *temp=newTemp();
 			$$->code += "mov "+string(temp)+", ax\n";
 			 
 			$$->code += "inc ax\n";
 			if (tempIncr->isVar) $$->code += "mov "+mkstr($1->getName(),st->findID($1->getName()))+", ax\n";
 			else if (tempIncr->isArr) $$->code += "mov "+mkstr($1->getName(),st->findID($1->getName()))+"[bx], ax\n";
 			 
 			$$->setName(temp); 	
			
			$$->isInt = $1->isInt;
			$$->isFloat = $1->isFloat;
			$$->isVoid = $1->isVoid;
		} 
		| variable DECOP
		{ 
			tempDecr = st->findAndRetSym($1->getName());
			 
			if (tempDecr->isVar) $$->code += "mov ax, "+mkstr($1->getName(),st->findID($1->getName()))+"\n";
 			else if (tempDecr->isArr) $$->code += "mov ax, "+mkstr($1->getName(),st->findID($1->getName()))+"[bx]\n";
 			
 			char *temp=newTemp(); 
 			$$->code += "mov "+string(temp)+", ax\n";
 			
 			$$->code += "dec ax\n";
 			if (tempDecr->isVar) $$->code += "mov "+mkstr($1->getName(),st->findID($1->getName()))+", ax\n";
 			else if (tempDecr->isArr) $$->code += "mov "+mkstr($1->getName(),st->findID($1->getName()))+"[bx], ax\n";
 			 
 			$$->setName(temp); 	
			
			$$->isInt = $1->isInt;
			$$->isFloat = $1->isFloat;
			$$->isVoid = $1->isVoid;
		}
		;
	
argument_list : arguments 
				{
					$$ = $1; 
				}
                |
                {
              		$$ = new symbolInfo("","");
                }
                ;

arguments : arguments COMMA logic_expression
			{
					 
				if ($3->isInt == true) argList.push_back("int");
            	else if ($3->isFloat == true) argList.push_back("float");
            	$$ = $1; 
            	$$->code += $3->code;
            	argName.push_back($3->getName());
			}
            | logic_expression
            { 
            	if ($1->isInt == true) argList.push_back("int");
            	else if ($1->isFloat == true) argList.push_back("float");
            	$$ = $1;  
            	argName.push_back($1->getName());
            }
            ; 

%%
int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	codeFp = fopen(argv[2],"w");
	fclose(codeFp);
	modCodeFp = fopen(argv[3],"w");
	fclose(modCodeFp);
	logFp = fopen(argv[4],"w");
	fclose(logFp);
	 
	codeFp = fopen(argv[2],"a");
	modCodeFp = fopen(argv[3],"a");
	logFp = fopen(argv[4],"a");

	yyin=fp;
	yyparse();
	 
	fclose(codeFp);
	fclose(modCodeFp);
	fclose(logFp);
 
	return 0;
}
