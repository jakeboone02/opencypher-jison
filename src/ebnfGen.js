const { Grammars } = require("ebnf");
const fs = require("fs");

const grammar = fs.readFileSync("../reference/cypher.ebnf").toString();

const w3cParser = new Grammars.W3C.Parser(grammar);
