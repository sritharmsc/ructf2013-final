#include "Parser.h"

function<int(Query*&, char)> Parser::modifierHandlers[] = {
	[] (Query *& query, char parameter) {
		query->AddCharToDbname(parameter);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->AddCharToTablename(parameter);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->AddCharToField(parameter);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->AddNewField();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new CreateDatabaseQuery();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new DropDatabaseQuery();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new CreateTableQuery();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new DropTableQuery();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new SelectQuery();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new InsertQuery();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new DeleteFromQuery();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->SetCompleted(false);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->SetCompleted(true);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->GetLastCondition()->AddCharToFirstOperand(parameter);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->GetLastCondition()->AddCharToSecondOperand(parameter);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->GetLastCondition()->SetMode(0);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->GetLastCondition()->SetMode(1);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->GetLastCondition()->SetOperation(0);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->GetLastCondition()->SetOperation(1);
		return 0;
	},
	[] (Query *& query, char parameter) {
		query->AddNewCondition();
		return 0;
	},
	[] (Query *& query, char parameter) {
		query = new SelectQuery(true);
		return 0;
	}
};

SymbolAutomaton::SymbolAutomaton(const JSONNode & _syntax)
{
	JSONNode syntax = _syntax.find("nodes")->as_array();
	vector<Node *> mapping(syntax.size(), NULL);
	for (auto j = syntax.begin(); j != syntax.end(); ++j)
		mapping[j->find("id")->as_int()] = new Node();
	for (auto j = syntax.begin(); j != syntax.end(); ++j)
	{
		Node * node = mapping[j->find("id")->as_int()];
		auto modifiers = j->find("modifiers")->as_array();
		for (auto k = modifiers.begin(); k != modifiers.end(); ++k)
			node->modifiers.push_back(k->as_int());
		auto transitions = j->find("transitions")->as_node();
		for (auto k = transitions.begin(); k != transitions.end(); ++k)
		{
			if (k->name().length() == 1)
			{
				char ch = k->name()[0];
				if (isalpha(ch))
				{
					node->transitions[toupper(ch)] = mapping[k->as_int()];
					node->transitions[tolower(ch)] = mapping[k->as_int()];
				}
				else
				{
					node->transitions[ch] = mapping[k->as_int()];
				}

			}
			else
			{
				if (k->name() == "alpha")
				{
					for (char c = 'a' ; c <= 'z'; ++c)
						node->transitions[c] = mapping[k->as_int()];
					for (char c = 'A' ; c <= 'Z'; ++c)
						node->transitions[c] = mapping[k->as_int()];
				}
				if (k->name() == "digit")
					for (char c = '0' ; c <= '9'; ++c)
						node->transitions[c] = mapping[k->as_int()];
				if (k->name() == "any")
					for (char c = 0x20; c <= 0x7e; ++c)
						node->transitions[c] = mapping[k->as_int()];
			}
		}
	}
	initialState = mapping[0];
}

SymbolAutomaton::~SymbolAutomaton()
{
	delete initialState;
}

vector<int> * SymbolAutomaton::Iterator::GetModifiers()
{
	if (currentState == NULL)
		return NULL;
	return &currentState->modifiers;
}

SymbolAutomaton::Iterator SymbolAutomaton::GetIterator(void)
{
	return Iterator(initialState);
}

bool SymbolAutomaton::Iterator::MoveNextState(char symbol)
{
	if (currentState == NULL)
	{
		currentState = NULL;
		return false;
	}
	if (currentState->transitions.find(symbol) == currentState->transitions.end())
	{
		currentState = NULL;
		return false;
	}
	else
	{
		currentState = currentState->transitions[symbol];
	}
	return true;
}

SymbolAutomaton * Parser::automaton = NULL;

void Parser::Initialize(const JSONNode & syntax)
{
	automaton = new SymbolAutomaton(syntax);
}

Query * Parser::Parse(const string & queryString, const string & userID)
{
	Query * query = NULL;
	SymbolAutomaton::Iterator iter = automaton->GetIterator();
	for (int i = 0; i < queryString.length(); ++i)
	{
		//cout << "Making transition with char \'" << queryString[i] << "\'" << endl;
		if (!iter.MoveNextState(queryString[i]))
		{
			delete query;
			//cout << "FUCK, SYNTAX ERROR" << endl;
			return NULL;
		}
		auto modifiers = iter.GetModifiers();
		//cout << "Got " << modifiers->size() << " modifier(s)" << endl;
		for (auto j = modifiers->begin(); j != modifiers->end(); ++j)
		{
			//cout << (*j) << ' ';
			modifierHandlers[*j](query, queryString[i]);
		}
		//cout << endl;
	}
	if (!query->IsComplete())
	{
		//cout << "Query is incomplete, you fucker!" << endl;
		delete query;
		return NULL;
	}
	if (query != NULL)
		query->SetID(userID);
	return query;
}
