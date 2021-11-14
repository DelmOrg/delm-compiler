@preprocessor typescript

@{%

const keywords = [
  "port",
  "module",
  "exposing",
  "import",
  "as",
  "(..)",
  "type",
  "alias",
  "case",
  "of",
  "_",
  "->",
  "let",
  "in",
];

%}

DECLARATION ->  "type" __ "alias" __ FUNCTION_DELCARATION __ "=" __ S_STATEMENT

			{% ([type, , alias, , dcl, , eq, , stm]) => { return { type: "TYPE_ALIAS_DECLARATION", left: dcl, right: stm } } %}


FUNCTION_DELCARATION -> ID_UNWRAPPED PARAMS

			{% ([fun, params]) => { return { fun, params: params.reverse() } } %}


PARAMS -> PARAMS __ ID_UNWRAPPED

			{% ([params, _1, id]) => { return [ id, ...params ] } %}

		| null

			{% () => [] %}


EXPRESSIONS -> EXPRESSIONS __ (IDENTIFIER {% ([id]) => id %} | LITERAL {% ([id]) => id[0] %})

				{% ([es, _, v]) => [v, ...es] %}

			| null


S_STATEMENT -> STATEMENT

				{% ([n]) => n %}


STATEMENT -> LITERAL

			{% ([n]) => [...n] %}

		| "{" RECORD_DEFINITION "}"

			{% ([_1, values, _2]) => { return [{ type: 'RECORD', values }] } %}

		| IDENTIFIER EXPRESSIONS

			{% ([id, params]) => { return params.length > 0 ? [{ type: "FUNCTION_CALL", fun: id, param: params.reverse() }] : [id] } %}


LITERAL -> "(" TUPLE ")"

			{% ([_, v, __]) => { return [{ type: 'TUPLE', value: v }] } %}

		| "(" ")"

			{% () => { return [{ type: 'TUPLE', value: null }] } %}

		| "(" _ S_STATEMENT _ ")"

			{% ([p1, _1, v, _2, p2]) => { return [v] } %}



TUPLE -> __ S_STATEMENT _ "," __ S_STATEMENT _ "," __ S_STATEMENT __

			{% ([_, st1, , comma1, __, st2, , comma2, ___, st3]) => [st1, st2, st3] %}

		| __ S_STATEMENT _ "," __ S_STATEMENT __

			{% ([_, st1, __, comma1, , st2]) => [st1, st2] %}

RECORD_DEFINITION -> __ ID_UNWRAPPED __ ":" __ S_STATEMENT _ "," RECORD_DEFINITION

			{% ([_, key, __, eq, ___, value, _e1, comma, values]) => { return [{ key, value }, ...values]} %}

		| __ ID_UNWRAPPED __ ":" __ S_STATEMENT __

			{% ([_, key, __, eq, ___, value]) => { return [{ key, value }]} %}


IDENTIFIER -> IDENTIFIER "." ID

			{% ([identf, dot, [id]]) => { return { type: 'IDENTIFIER', value: identf.value + dot + id.join("") } } %}

		| ID

			{% ([n]) => { return { type: 'IDENTIFIER', value: n[0].join("") } } %}


ID_UNWRAPPED -> ID

			{% ([n]) => { return { type: 'IDENTIFIER', value: n[0].join("") } } %}


ID -> [a-zA-Z]:+

			{% (n, _, reject) => { if ( keywords.includes(n[0].join("")) ) { return reject } else { return n } } %}

		| [a-zA-Z]:+ [0-9]:+ (ID {% ([n]) => n %} | null)

			{% ([n1, n2, [n3]]) => { return n3?.[0] ? [[...n1, ...n2, ...n3]] : [[...n1, ...n2]]} %}


_ -> " ":?  {% () => null %}
__ -> " " 	{% () => null %}

