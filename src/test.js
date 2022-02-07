const cypherParser = require('../out/cypherParser');

const query = "MATCH () RETURN *;";

console.log(JSON.stringify(cypherParser.parse(query), null, 2));
