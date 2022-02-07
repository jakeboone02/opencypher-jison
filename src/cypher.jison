/* description: Parses openCypher based on the spec from http://opencypher.org/ */
/* :tabSize=2:indentSize=2:noTabs=true: */
%lex

%options case-insensitive

%%

[/][*](.|\n)*?[*][/]                                              /* skip comments */
[/][/].*\n                                                        /* skip sql comments */
\s+                                                               /* skip whitespace */

[`][a-zA-Z_\u4e00-\u9fa5][ a-zA-Z0-9_\u4e00-\u9fa5]*[`]           return 'ESCAPED_SYMBOLIC_NAME'
[\w]+[\u4e00-\u9fa5]+[0-9a-zA-Z_\u4e00-\u9fa5]*                   return 'UNESCAPED_SYMBOLIC_NAME'
[\u4e00-\u9fa5][0-9a-zA-Z_\u4e00-\u9fa5]*                         return 'UNESCAPED_SYMBOLIC_NAME'
// [ABCDEF]                                                          return 'HEX_LETTER'
ALL                                                               return 'ALL'
ASC                                                               return 'ASC'
ASCENDING                                                         return 'ASCENDING'
BY                                                                return 'BY'
CREATE                                                            return 'CREATE'
DELETE                                                            return 'DELETE'
DESC                                                              return 'DESC'
DESCENDING                                                        return 'DESCENDING'
DETACH                                                            return 'DETACH'
EXISTS                                                            return 'EXISTS'
LIMIT                                                             return 'LIMIT'
MATCH                                                             return 'MATCH'
MERGE                                                             return 'MERGE'
ON                                                                return 'ON'
ON\s+CREATE                                                       return 'ON_CREATE'
ON\s+MATCH                                                        return 'ON_MATCH'
OPTIONAL                                                          return 'OPTIONAL'
ORDER                                                             return 'ORDER'
REMOVE                                                            return 'REMOVE'
RETURN                                                            return 'RETURN'
SET                                                               return 'SET'
SKIP                                                              return 'SKIP'
WHERE                                                             return 'WHERE'
WITH                                                              return 'WITH'
UNION                                                             return 'UNION'
UNWIND                                                            return 'UNWIND'
AND                                                               return 'AND'
AS                                                                return 'AS'
CONTAINS                                                          return 'CONTAINS'
DISTINCT                                                          return 'DISTINCT'
ENDS                                                              return 'ENDS'
IN                                                                return 'IN'
IS                                                                return 'IS'
NOT                                                               return 'NOT'
OR                                                                return 'OR'
STARTS                                                            return 'STARTS'
XOR                                                               return 'XOR'
FALSE                                                             return 'FALSE'
TRUE                                                              return 'TRUE'
NULL                                                              return 'NULL'
CONSTRAINT                                                        return 'CONSTRAINT'
DO                                                                return 'DO'
FOR                                                               return 'FOR'
REQUIRE                                                           return 'REQUIRE'
UNIQUE                                                            return 'UNIQUE'
CASE                                                              return 'CASE'
WHEN                                                              return 'WHEN'
THEN                                                              return 'THEN'
ELSE                                                              return 'ELSE'
END                                                               return 'END'
MANDATORY                                                         return 'MANDATORY'
SCALAR                                                            return 'SCALAR'
OF                                                                return 'OF'
ADD                                                               return 'ADD'
DROP                                                              return 'DROP'
YIELD                                                             return 'YIELD'

CALL                                                              return 'CALL'
COUNT                                                             return 'COUNT'
FILTER                                                            return 'FILTER'
EXTRACT                                                           return 'EXTRACT'
ANY                                                               return 'ANY'
NONE                                                              return 'NONE'
SINGLE                                                            return 'SINGLE'

[<⟨〈﹤＜]                                                         return 'LEFT_ARROW_HEAD'
[>⟩〉﹥＞]                                                         return 'RIGHT_ARROW_HEAD'
[-­‐‑‒–—―−﹘﹣－]                                                   return 'DASH'

","                                                               return ','
"="                                                               return '='
"("                                                               return '('
")"                                                               return ')'
"~"                                                               return '~'
"!="                                                              return '!='
"!"                                                               return '!'
"|"                                                               return '|'
"&"                                                               return '&'
"+"                                                               return '+'
"-"                                                               return '-'
"*"                                                               return '*'
"/"                                                               return '/'
"%"                                                               return '%'
"^"                                                               return '^'
">>"                                                              return '>>'
">="                                                              return '>='
">"                                                               return '>'
"<<"                                                              return '<<'
"<=>"                                                             return '<=>'
"<="                                                              return '<='
"<>"                                                              return '<>'
"<"                                                               return '<'
"{"                                                               return '{'
"}"                                                               return '}'
";"                                                               return ';'

['](\\.|[^'])*[']                                                 return 'STRING_LITERAL'
["](\\.|[^"])*["]                                                 return 'STRING_LITERAL'
0[x][0-9a-fA-F]+                                                  return 'HEX_INTEGER'
0[0-7]+                                                           return 'OCTAL_INTEGER'
0                                                                 return 'DECIMAL_INTEGER'
[1-9][0-9]*                                                       return 'DECIMAL_INTEGER'
[-]?[0-9]*(\.[0-9]+)?[eE][-]?[0-9]+(\.[0-9]+)?                    return 'EXPONENT_DECIMAL_REAL'
[-]?[0-9]*(\.[0-9]+)+                                             return 'REGULAR_DECIMAL_REAL'

<<EOF>>                                                           return 'EOF'
// .                                                                 return 'INVALID'

/lex

// TODO: missing section? See sql.jison section between /lex and %start main

%start cypher

%% /* language grammar */

cypher
  : statement semicolonOpt EOF { return { nodeType: 'Cypher', value: $1, hasSemicolon: $2 }; }
  ;

semicolonOpt
  : ';' { $$ = true }
  | { $$ = false }
  ;

statement
  : query { $$ = { nodeType: 'Statement', value: $1 }; }
  ;

query
  : regularQuery { $$ = $1 }
  | standaloneCall { $$ = $1 }
  ;

regularQuery
  : singleQuery { $$ = { type: 'SingleQuery', value: $1 } }
  | union { $$ = $1 }
  ;

union
  : singleQuery UNION distinctOpt singleQuery { $$ = { type: 'Union', left: $1, distinctOpt: $3, right: $4 } }
  | singleQuery UNION distinctOpt union { $$ = { type: 'Union', left: $1, distinctOpt: $3, right: $4 } }
  ;

distinctOpt
  : DISTINCT { $$ = true }
  | { $$ = false }
  ;

singleQuery
  : singlePartQuery { $$ = $1 }
  | multiPartQuery { $$ = $1 }
  ;

multiPartQuery
  : multiPartQueryClauseList singlePartQuery { $$ = { type: 'MultiPartQuery', value: $3, clauses: $1 } }
  ;
multiPartQueryClauseList
  : multiPartQueryClauseList multiPartQueryClause { $$ = $1; $1.value.push($2) }
  | multiPartQueryClause { $$ = { type: 'MultiPartQueryClauseList', value: [ $1 ] } }
  ;
multiPartQueryClause
  : readingClauseList WITH { $$ = { type: 'MultiPartQueryClause', reading: $1 } }
  | readingClauseList updatingClauseList WITH { $$ = { type: 'MultiPartQueryClause', reading: $1, updating: $2 } }
  | updatingClauseList WITH { $$ = { type: 'MultiPartQueryClause', updating: $1 } }
  | WITH { $$ = { type: 'MultiPartQueryClause' } }
  ;

singlePartQuery
  : return { $$ = { type: 'SinglePartQuery', return: $1 } }
  | readingClauseList return { $$ = { type: 'SinglePartQuery', reading: $1, return: $2 } }
  | updatingClauseList return { $$ = { type: 'SinglePartQuery', updating: $1, return: $2 } }
  | readingClauseList updatingClauseList return { $$ = { type: 'SinglePartQuery', reading: $1, updating: $2, return: $3 } }
  | updatingClauseList  { $$ = { type: 'SinglePartQuery', updating: $1 } }
  | readingClauseList updatingClauseList  { $$ = { type: 'SinglePartQuery', reading: $1, updating: $2 } }
  ;

return
  : RETURN projectionBody { $$ = { type: 'Return', value: $2 } }
  ;

updatingClauseList
  : updatingClauseList updatingClause { $$ = $1; $1.value.push($2); }
  | updatingClause { $$ = { type: 'Updating', value: [ $1 ] } }
  ;
updatingClause
  : create { $$ = $1 }
  | merge { $$ = $1 }
  | delete { $$ = $1 }
  | set { $$ = $1 }
  | remove { $$ = $1 }
  ;
create
  : CREATE pattern { $$ = { type: 'Create', value: $2 } }
  ;
merge
  : MERGE patternPart mergeActionList { $$ = { type: 'Merge', pattern: $2, actions: $3 } }
  ;
mergeActionList
  : mergeActionList mergeAction { $$ = $1; $1.value.push($2) }
  | mergeAction { $$ = { type: 'MergeActionList', value: [ $1 ] } }
  ;
mergeAction
  : ON_MATCH set { $$ = { type: 'MergeAction', on: 'MATCH', set: $2 } }
  | ON_CREATE set { $$ = { type: 'MergeAction', on: 'CREATE', set: $2 } }
  ;
delete
  : DETACH DELETE expressionList { $$ = { type: 'Delete', detach: true, value: $3 } }
  | DELETE expressionList { $$ = { type: 'Delete', detach: false, value: $2 } }
  ;
set
  : SET 'Set' { $$ = { type: 'Set', value: $2 } }
  ;
setItemList
  : setItemList ',' setItem { $$ = $1; $1.value.push($2) }
  | setItem { $$ = { type: 'SetItemList', value: [ $1 ] } }
  ;
setItem
  : propertyExpression '=' expression { $$ = { type: 'SetItem', left: $1, operator: $2, right: $3 } }
  | variable '=' expression { $$ = { type: 'SetItem', left: $1, operator: $2, right: $3 } }
  | variable '+=' expression { $$ = { type: 'SetItem', left: $1, operator: $2, right: $3 } }
  | variable nodeLabels { $$ = { type: 'SetItem', left: $1, labels: $2 } }
  ;
nodeLabels
  : nodeLabels nodeLabel { $$ = $1; $1.value.push($2) }
  | nodeLabel { $$ = { type: 'NodeLabels', value: $2 } }
  ;
nodeLabel
  : ':' schemaName { $$ = { type: 'LabelName', value: $2 } }
  ;
remove
  : REMOVE removeItemList { $$ = { type: 'Remove', value: $2 } }
  ;
removeItemList
  : removeItemList ',' removeItem { $$ = $1; $1.value.push($3) }
  | removeItem { $$ = { type: 'RemoveItemList', value: [ $1 ] } }
  ;
removeItem
  : variable nodeLabels { $$ = { type: 'RemoveItem', value: $1, labels: $2 } }
  | propertyExpression { $$ = { type: 'RemoveItem', value: $1 } }
  ;

readingClauseList
  : readingClauseList readingClause { $$ = $1; $1.value.push($2); }
  | readingClause { $$ = { type: 'Reading', value: [ $1 ] } }
  ;
readingClause
  : match { $$ = $1 }
  | unwind { $$ = $1 }
  | inQueryCall { $$ = $1 }
  ;

match
  : OPTIONAL MATCH pattern { $$ = { type: 'Match', optional: true, value: $3, where: null } }
  | MATCH pattern { $$ = { type: 'Match', optional: false, value: $2, where: null } }
  | OPTIONAL MATCH pattern where { $$ = { type: 'Match', optional: true, value: $3, where: $4 } }
  | MATCH pattern where { $$ = { type: 'Match', optional: false, value: $2, where: $3 } }
  ;
where
  : WHERE expression { $$ = { type: 'Where', value: $2 } }
  ;
unwind
  : UNWIND expression AS variable { $$ = { type: 'Unwind', value: $2, var: $4 } }
  ;
inQueryCall
  : CALL explicitProcedureInvocation { $$ = { type: 'InQueryCall', procedure: $2 } }
  | CALL explicitProcedureInvocation YIELD yieldItems { $$ = { type: 'InQueryCall', procedure: $2, yield: $4, where: null } }
  | CALL explicitProcedureInvocation YIELD yieldItems where { $$ = { type: 'InQueryCall', procedure: $2, yield: $4, where: $5 } }
  ;
yieldItems
  : yieldItems ',' yieldItem { $$ = $1; $1.value.push($3) }
  | yieldItem { $$ = { type: 'YieldItems', value: [ $1 ] } }
  ;
yieldItem
  : procedureResultField AS variable { $$ = { type: 'YieldItem', value: $1, alias: $3 } }
  // TODO: Including this line causes conflicts because `procedureResultField` and `variable` 
  // both resolve to `symbolicName`. Figure out how to support both formulations.
  // | variable  { $$ = { type: 'YieldItem', value: $1 } }
  ;
procedureResultField
  : symbolicName { $$ = { type: 'ProcedureResultField', value: $1 } }
  ;

pattern
  : patternPart { $$ = { type: 'Pattern', value: [ $1 ] } }
  | pattern ',' patternPart { $$ = $1; $1.value.push($3); }
  ;
patternPart
  : variable '=' anonymousPatternPart { $$ = { type: 'PatternPart', var: $1, value: $3 } }
  | anonymousPatternPart { $$ = { type: 'AnonymousPatternPart', value: $1 } }
  ;

variable
  : symbolicName { $$ = { type: 'Variable', value: $1 } }
  ;

symbolicName
  : UNESCAPED_SYMBOLIC_NAME { $$= { type: 'SymbolicName', value: $1 } }
  | ESCAPED_SYMBOLIC_NAME { $$= { type: 'SymbolicName', value: $1 } }
  // TODO: Why does this override "Expression"?
  // | HEX_LETTER { $$= { type: 'SymbolicName', value: $1 } }
  | COUNT { $$= { type: 'SymbolicName', value: $1 } }
  | FILTER { $$= { type: 'SymbolicName', value: $1 } }
  | EXTRACT { $$= { type: 'SymbolicName', value: $1 } }
  | ANY { $$= { type: 'SymbolicName', value: $1 } }
  | NONE { $$= { type: 'SymbolicName', value: $1 } }
  | SINGLE { $$= { type: 'SymbolicName', value: $1 } }
  ;

literal
  : numberLiteral { $$ = { type: 'NumberLiteral', value: $1 } }
  | stringLiteral { $$ = { type: 'StringLiteral', value: $1 } }
  | booleanLiteral { $$ = { type: 'BooleanLiteral', value: $1 } }
  | NULL { $$ = { type: 'NullLiteral' } }
  | mapLiteral { $$ = $1 }
  | listLiteral { $$ = $1 }
  ;
numberLiteral
  : doubleLiteral { $$ = $1 }
  | integerLiteral { $$ = $1 }
  ;
doubleLiteral
  : EXPONENT_DECIMAL_REAL { $$ = { type: 'ExponentDecimalReal', value: $1 } }
  | REGULAR_DECIMAL_REAL { $$ = { type: 'RegularDecimalReal', value: $1 } }
  ;
integerLiteral
  : HEX_INTEGER { $$ = { type: 'HexInteger', value: $1 } }
  | OCTAL_INTEGER { $$ = { type: 'OctalInteger', value: $1 } }
  | DECIMAL_INTEGER { $$ = { type: 'DecimalInteger', value: $1 } }
  ;
stringLiteral
  : STRING_LITERAL { $$ = { type: 'StringLiteral', value: $1 } }
  ;
booleanLiteral
  : TRUE { $$ = { type: 'BooleanLiteral', value: true } }
  | FALSE { $$ = { type: 'BooleanLiteral', value: false } }
  ;
mapLiteral
  : '{' '}'  { $$ = { type: 'MapLiteral', value: [] } }
  | '{' mapLiteralItemList '}'  { $$ = { type: 'MapLiteral', value: [ $2 ] } }
  ;
mapLiteralItemList
  : mapLiteralItemList ',' mapLiteralItem { $$ = $1; $1.value.push($3) }
  | mapLiteralItem { $$ = { type: 'MapLiteralItemList', value: [ $1 ] } }
  ;
mapLiteralItem
  : propertyKeyName ':' expression { $$ = { type: 'MapLiteralItem', prop: $1, expr: $3 } }
  ;
listLiteral
  : '[' expressionList ']' { $$ = { type: 'ListLiteral', value: $2 } }
  ;

expressionList
  : expressionList ',' expression { $$ = $1; $1.value.push($3) }
  | expression { $$ = { type: 'ExpressionList', value: [ $1 ] } }
  ;

propertyKeyName
  : schemaName { $$ = $1 }
  ;
schemaName
  : symbolicName { $$ = { type: 'SchemaName', value: $1 } }
  | reservedWord { $$ = { type: 'ReservedWord', value: $1 } }
  ;

projectionBody
  : distinctOpt projectionItems order skip limit { $$ = { type: 'ProjectionBody', distinctOpt: $1, items: $2, order: $3, skip: $4, limit: $5 } }
  ;
order
  : ORDER_BY sortItemList { $$ = { type: 'Order', value: $2 } }
  | { $$ = null }
  ;
sortItemList
  : sortItemList ',' sortItem { $$ = $1; $1.value.push($3) }
  | sortItem { $$ = { type: 'SortItemList', value: [ $1 ] } }
  ;
sortItem
  : expression sortDirectionOpt { $$ = { type: 'SortItem', value: $1, direction: $2 } }
  ;
sortDirectionOpt
  : ASC { $$ = { type: 'SortDirection', value: $1, asc: true } }
  | ASCENDING { $$ = { type: 'SortDirection', value: $1, asc: true } }
  | DESC { $$ = { type: 'SortDirection', value: $1, asc: false } }
  | DESCENDING { $$ = { type: 'SortDirection', value: $1, asc: false } }
  | { $$ = null }
  ;
skip
  : SKIP expression { $$ = { type: 'Skip', value: $2 } }
  | { $$ = null }
  ;
limit
  : LIMIT expression { $$ = { type: 'Limit', value: $2 } }
  | { $$ = null }
  ;
projectionItems
  : '*' { $$ = { type: 'ProjectionItems', value: [], beginsWithStar: true } }
  | '*' ',' projectionItemList { $$ = { type: 'ProjectionItems', value: $3, beginsWithStar: true } }
  | projectionItemList { $$ = { type: 'ProjectionItems', value: $1, beginsWithStar: false } }
  ;
projectionItemList
  : projectionItemList ',' projectionItem { $$ = $1; $1.value.push($3) }
  | projectionItem { $$ = { type: 'ProjectionItemList', value: [ $1 ] } }
  ;
projectionItem
  : expression AS variable { $$ = { type: 'ProjectionItem', value: $1, var: $3 } }
  | expression { $$ = { type: 'ProjectionItem', value: $1 } }
  ;

explicitProcedureInvocation
  : procedureName '(' expressionList ')' { $$ = { type: 'ExplicitProcedureInvocation', procedure: $1, params: $3 } }
  | procedureName '(' ')' { $$ = { type: 'ExplicitProcedureInvocation', procedure: $1 } }
  ;
procedureName
  : symbolicName { $$ = { type: 'ProcedureName', value: $1 } }
  | namespaces symbolicName { $$ = { type: 'ProcedureName', value: $2, namespaces: $1 } }
  ;
namespaces
  : namespaces namespace { $$ = $1; $1.value.push($2) }
  | namespace { $$ = { type: 'Namespaces', value: [ $1 ] } }
  ;
namespace
  : symbolicName '.' { $$ = { type: 'Namespace', value: $1 } }
  ;

anonymousPatternPart
  : patternElementChain { $$ = { type: 'AnonymousPatternPart', value: $1 } }
  ;
patternElementChain
  : patternElementChain relationshipPattern nodePattern { $$ = $1; $1.value.push($2, $3) }
  | nodePattern { $$ = { type: 'PatternElementChain', value: [ $1 ] } }
  ;
nodePattern
  : '(' ')' { $$ = { type: 'NodePattern', variable: null, labels: null, properties: null } }
  | '(' variable ')' { $$ = { type: 'NodePattern', variable: $2, labels: null, properties: null } }
  | '(' nodeLabels ')' { $$ = { type: 'NodePattern', variable: null, labels: $2, properties: null } }
  | '(' variable nodeLabels ')' { $$ = { type: 'NodePattern', variable: $2, labels: $3, properties: null } }
  | '(' properties ')' { $$ = { type: 'NodePattern', variable: null, labels: null, properties: $2 } }
  | '(' variable properties ')' { $$ = { type: 'NodePattern', variable: $2, labels: null, properties: $3 } }
  | '(' nodeLabels properties ')' { $$ = { type: 'NodePattern', variable: null, labels: $2, properties: $3 } }
  | '(' variable nodeLabels properties ')' { $$ = { type: 'NodePattern', variable: $2, labels: $3, properties: $4 } }
  ;
properties
  : mapLiteral { $$ = $1 }
  | parameter { $$ = $1 }
  ;
parameter
  : '$' symbolicName { $$ = { type: 'Parameter', value: $2 } }
  | '$' DECIMAL_INTEGER { $$ = { type: 'Parameter', value: $2 } }
  ;

relationshipPattern
  : LEFT_ARROW_HEAD DASH relationshipDetail DASH RIGHT_ARROW_HEAD { $$ = { type: 'RelationshipPattern', detail: $3, hasLeftArrowHead: true, hasRightArrowHead: true } }
  | LEFT_ARROW_HEAD DASH relationshipDetail DASH { $$ = { type: 'RelationshipPattern', detail: $3, hasLeftArrowHead: true, hasRightArrowHead: false } }
  | DASH relationshipDetail DASH RIGHT_ARROW_HEAD { $$ = { type: 'RelationshipPattern', detail: $2, hasLeftArrowHead: false, hasRightArrowHead: true } }
  | DASH relationshipDetail DASH { $$ = { type: 'RelationshipPattern', detail: $2, hasLeftArrowHead: false, hasRightArrowHead: false } }
  ;

// Stubs (not properly implemented yet)

relationshipDetail
  : '[' ']' { $$ = { type: 'RelationshipDetail', value: null } }
  ;

expression
  : 'Expression' { $$ = { type: 'Expression' } }
  ;

propertyExpression
  : 'PropertyExpression' { $$ = { type: 'PropertyExpression' } }
  ;

standaloneCall
  : CALL 'StandaloneCall' { $$ = { type: 'StandaloneCall' } }
  ;

reservedWord
  : ALL
  | ASC
  | ASCENDING
  | BY
  | CREATE
  | DELETE
  | DESC
  | DESCENDING
  | DETACH
  | EXISTS
  | LIMIT
  | MATCH
  | MERGE
  | ON
  | OPTIONAL
  | ORDER
  | REMOVE
  | RETURN
  | SET
  | SKIP
  | WHERE
  | WITH
  | UNION
  | UNWIND
  | AND
  | AS
  | CONTAINS
  | DISTINCT
  | ENDS
  | IN
  | IS
  | NOT
  | OR
  | STARTS
  | XOR
  | FALSE
  | TRUE
  | NULL
  | CONSTRAINT
  | DO
  | FOR
  | REQUIRE
  | UNIQUE
  | CASE
  | WHEN
  | THEN
  | ELSE
  | END
  | MANDATORY
  | SCALAR
  | OF
  | ADD
  | DROP
  ;
