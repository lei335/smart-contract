// 根据输入的数字i，创建i个账户，并输出它们的地址和私钥
// 使用：node create-account.js i
const { ethers } = require("hardhat");

//const hre = require("hardhat");
require("@nomiclabs/hardhat-ethers");

async function main() {
    const args = process.argv.slice(2);
    const num = args[0];
    var array = [];
    for(var i=0;i<num;i++){
        const account = ethers.Wallet.createRandom();
        array.push(account);
    }
    console.log("");
    for(var i=0;i<num;i++){
        console.log(array[i].address);
    }
    console.log("");
    for(var i=0;i<num;i++){
        console.log(array[i].publicKey.substring(2));
    }
    console.log("");
    for(var i=0;i<num;i++){
        console.log(array[i].privateKey.substring(2));
    }
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
  });