#include<iostream>
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<string>
#include<vector>
#include<cstddef>
#include <stdlib.h>

using namespace std;

class fncInfo{
	public:
		int paramCnt;
		vector<string> paramList;
		vector<string> paramType;
		string retType;
		string retVal;
		bool isDef;
		
		fncInfo() {isDef = true;}
};

class arrInfo{
	public:
		float *arr;
        int idx;
        int arrCnt;
        int rightMostIdx;
        
        bool isMoved;
        arrInfo() {isMoved = false;}
};

class symbolInfo{
     
    private:
    	string name;
        string type;
 		int arrSize;
 		
    public:
    	int sid;
    	string code;
        arrInfo *ai;
        fncInfo *fi;
	
    	bool isVar;
    	bool isFnc;
    	bool isArr;
    	bool isInt;
    	bool isFloat;
    	bool isVoid;
    	
        symbolInfo *nextSym;
        
        symbolInfo(string x){
        	name = x;
        }
        
        symbolInfo(string x, string y) {
            name = x;
            type = y;
            code = "";
 
            isVar=isFnc=isArr=false;
            isFloat=isInt=isVoid=false;
            nextSym=NULL; 
            
            fi = new fncInfo();
            ai = new arrInfo();
            initArr();
        }
        
        symbolInfo(symbolInfo *sym){
         	name = sym->getName();
         	type = sym->getType();
         	code = sym->getCode();
         	
         	isVar=isFnc=isArr=false;
            isFloat=isInt=isVoid=false;
            nextSym=NULL; 
            
            fi = new fncInfo();
            ai = new arrInfo();
            initArr();
        }
        
        string getName() {return name;}
        string getType() {return type;}
        string getCode() {return code;}
        
        void setName(string x) {name = x;}
        void setType(string x) {type = x;}
        void setCode(string x) {code = x;}
        
        void setRet(string x){fi->retVal = x;}
        string getRet() {return fi->retVal;}
        
        void setSize(int x) {arrSize = x;}
        int getSize()       {return arrSize;}
         
        void makeDecl() {fi->isDef = false;}
        void makeFnc()  {fi->isDef = true;}
        bool getFncFlag() {return fi->isDef;}
        
        void addFncInfo(vector<string> pList, vector<string> pType, string ret){
    		fi->paramList = pList;
    		fi->paramType = pType;
    		fi->paramCnt = pList.size();
    		fi->retType = ret;
    	}
    	
    	void initArr() {
        	ai->idx=0;
            ai->rightMostIdx=0;
        }
};

class scope {
    private:
        symbolInfo **hashTable;
        int buckets;
        int id;

    public:
        scope* parScope;
        
        scope(int numOfBuckets,int idNo,scope* parent) {
            hashTable = new symbolInfo* [numOfBuckets];
            for (int i=0; i<numOfBuckets; i++)
                hashTable[i]=NULL;

            buckets=numOfBuckets;
            id=idNo;
            parScope=parent;
        }
        
        ~scope() {}

        int hashFnc(string x) {
        	int sum=0;
            for (int i=0; i<x.length(); i++){
            	sum += x[i];
            }
            return sum%buckets;
        }

        int getID() {return id;}

        bool insert(string name, string type) {
            if (find(name)== true) {
                //fprintf(" <"<<name<<","<<type<<"> already exists in current ScopeTable"<<endl;
            }
            else if (find(name)==false) {

                symbolInfo *symbol=new symbolInfo(name,type);
                symbol->sid = id;
                symbolInfo *prev=NULL;
                int idx = hashFnc(name );
                int cnt=0;

                if (hashTable[idx] == NULL) hashTable[idx]= symbol;

                else {
                    cnt=1;
                    symbolInfo *temp = hashTable[idx];
                    while (temp -> nextSym != NULL) {

                            temp = temp->nextSym;
                            cnt++;
                    }
                    temp->nextSym = symbol;
                }
                return true;
            }
            return false;
        }
        
        
        bool insert(symbolInfo *s) {
        	s->sid = id;
        	string name = s->getName();
        	if (find(name)==false){
        		symbolInfo *prev=NULL;
                int idx = hashFnc(name);
                int cnt=0;

                if (hashTable[idx] == NULL) hashTable[idx]= s;

                else {
                    cnt=1;
                    symbolInfo *temp = hashTable[idx];
                    while (temp -> nextSym != NULL) {

                            temp = temp->nextSym;
                            cnt++;
                    }
                    temp->nextSym = s;
               }
               return true;
        	}
        }
        
        bool find(string name) {

            int hashVal=hashFnc(name);
            symbolInfo *symbol = hashTable[hashVal];

            while (symbol != NULL) {
                if (symbol->getName() == name) return true;
                symbol = symbol->nextSym;
            }
            return false;
        }
        
        symbolInfo* findAndRet(string name){
        	
        	int hashVal=hashFnc(name);
            symbolInfo *symbol = hashTable[hashVal];

            while (symbol != NULL) {
                if (symbol->getName() == name) {
                	return symbol;
               }
                symbol = symbol->nextSym;
            }
            return NULL;
        }
        
        bool findAndUpdate(string name,symbolInfo *s){
        	
        	int hashVal=hashFnc(name);
            symbolInfo *symbol = hashTable[hashVal];

            while (symbol != NULL) {
                if (symbol->getName() == s->getName()) {
                	
                	symbol->setName(s->getName());
                	symbol->setType(s->getType());
                	
                	return true;
                }
                symbol = symbol->nextSym;
            }
            return false;
        }
};

class symbolTable {
    public:
        scope* cur;
        int curID;
        int sizeOfHtable;

		symbolTable() {
			sizeOfHtable=20;
			cur = new scope(sizeOfHtable, 1, NULL);
            curID=1;
		}

        void enterScope() {
            cur = new scope(sizeOfHtable, curID+1, cur);
            curID++;
        }

        void exitScope() {
            scope* temp=cur;
            cur = cur->parScope;
            delete temp;
        }

        bool insertSym(string name, string type) {
            if ((cur -> insert(name,type)) == true) {
				return true;
			}
            return false;
        }
        
        bool insertSym(symbolInfo *s){
        	if ((cur -> insert(s)) == true){
				return true;
        	}
        	return false;
        }
        
        bool lookUpSymCur(string name) {
            scope* temp=cur;

            return temp->find(name);
        }
        

		bool lookUpSym(string name) {
            scope* temp=cur;

            while(temp != NULL) {
                if ((temp->find(name)) == true) {
                        return true;
                }
                temp = temp->parScope;
            }
            return false;
        }
        
        bool findAndUpdateSym(string name, symbolInfo *s){
        	scope* temp=cur;

            while(temp != NULL) {
                if ((temp->findAndUpdate(name, s)) == true) {
                        return true;
                }
                temp = temp->parScope;
            }
            return false;
        }  
        
        symbolInfo* findAndRetSym(string name){
        	
        	symbolInfo* val;
        	scope* temp=cur;

            while(temp != NULL) {
                if ((temp->find(name)) == true) {
                	return temp->findAndRet(name);                  
                }
                temp = temp->parScope;
            }
            return NULL; 
        }
        
        string findID(string name){
        	scope* temp=cur;
        	char *intStr = new char[4]; 

            while(temp != NULL) {
                if ((temp->find(name)) == true) {
                	sprintf(intStr,"%d",temp->getID());
                	return string(intStr);                  
                }
                temp = temp->parScope;
            }
            return ""; 
        }
};
