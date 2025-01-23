const ethers = require('ethers');

const errorSignature = "foo()";
//const errorSelector = ethers.utils.id(errorSignature).slice(0, 10);
const errorSelector = ethers.utils.id(errorSignature);
console.log(errorSelector);