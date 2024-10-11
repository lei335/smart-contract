async function main() {
    const ethers = require("ethers");
  
    // 设置 RPC 提供者 (使用 Hardhat 内置网络，或者替换为私链节点 URL)
    const provider = new ethers.providers.JsonRpcProvider('http://xxx');;
    
    // 指定日志的合约地址和事件主题
    const targetLogAddress = '0xxxx';  // 合约地址
    const targetLogTopic = '0xxxx';  // 事件签名的哈希，比如：keccak256("Transfer(address,uint)")
  
    // 查询的区块范围
    const startBlock = 16104000;  // 起始区块号
    const endBlock = 16105000;
  
    // 遍历区块并查找交易
    for (let i = startBlock; i <= endBlock; i++) {
      // 获取区块信息
      const block = await provider.getBlockWithTransactions(i);
  
      // 遍历区块中的每个交易
      for (let tx of block.transactions) {
        if (tx.to.toLowerCase() === targetLogAddress.toLowerCase()) {
          // 获取交易的 receipt，包含日志信息
          const receipt = await provider.getTransactionReceipt(tx.hash);
          let matchingLogs = receipt.logs.filter(log =>
            log.topics.includes(targetLogTopic)
          );
  
          // 如果找到匹配的日志
          if (matchingLogs.length > 0) {
            console.log(`Block: ${block.number}, TxHash: ${tx.hash}, From: ${tx.from}, To: ${tx.to}`);
            
            // 输出匹配的日志信息
            matchingLogs.forEach((log, index) => {
              console.log(`Log ${index + 1}:`);
              console.log(`  Address: ${log.address}`);
              console.log(`  Data: ${log.data}`);
              console.log(`  Topics: ${log.topics}`);
            });
          }
        }
      }
    }
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  