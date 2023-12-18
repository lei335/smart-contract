package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"golang.org/x/xerrors"

	com "github.com/memoio/contractsv2/common"

	"github.com/zl/smart-contract/go-contracts/recover"
)

var (
	eth   string
	hexSk string

	checkTxSleepTime = 6 // 先等待6s（出块时间加1）
	nextBlockTime    = 5 // 出块时间5s

	// input params
	access = common.HexToAddress("0x5B38Da6a701c568545dCfcB03FcB875f56beddC4")
)

func main() {
	hash := com.GetSetHash(access, access, big.NewInt(1), true)
	fmt.Println("hash:", hash)
	fmt.Println("hex-hash:", common.Bytes2Hex(hash))
	sks := "0a95533a110ee10bdaa902fed92e56f3f7709a532e22b5974c03c0251648a5d4"
	sign, err := com.Sign(hash, sks)
	if err !=nil {
		log.Fatal(err)
	}
	fmt.Println("sign:", sign)
	fmt.Println("hex-sign:", common.Bytes2Hex(sign))

	// cli-input
	inputeth := flag.String("eth", "", "eth api Address;")
	sk := flag.String("sk", "", "signature for sending transaction")

	flag.Parse()
	eth = *inputeth
	hexSk = *sk

	fmt.Println()

	// get client
	client, err := ethclient.DialContext(context.Background(), eth)
	if err != nil {
		log.Fatal(err)
	}

	// make auth to send transaction
	chainId, err := client.ChainID(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	txAuth, err := MakeAuth(chainId, hexSk)
	if err != nil {
		log.Fatal(err)
	}

	// deploy Recover.sol
	recoverAddr, tx, recoverIns, err := recover.DeployRecover(txAuth, client)
	if err != nil {
		log.Fatal("deploy Recover err:", err)
	}
	fmt.Println("recoverAddr: ", recoverAddr.Hex())
	err = CheckTx(eth, tx.Hash(), "deploy Recover")
	if err != nil {
		log.Fatal(err)
	}

	// get tx info
	receipt, err := client.TransactionReceipt(context.Background(), tx.Hash())
	if err != nil {
		log.Fatal(err)
	}
	receiptJson, err := receipt.MarshalJSON()
	if err != nil {
		log.Fatal(err)
	}
	// format input
	var str bytes.Buffer
	json.Indent(&str, receiptJson, "", " ")
	fmt.Println(str.String())
	fmt.Println("gasUsed:", receipt.GasUsed)

	// call recover()
	addr, err := recoverIns.Recover(nil, [32]byte(hash), sign)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("addr:", addr)
	err = CheckTx(eth, tx.Hash(), "deploy Recover")
	if err != nil {
		log.Fatal(err)
	}

	// get tx info
	receipt, err = client.TransactionReceipt(context.Background(), tx.Hash())
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("gasUsed:", receipt.GasUsed)
}

func MakeAuth(chainID *big.Int, hexSk string) (*bind.TransactOpts, error) {
	auth := &bind.TransactOpts{}
	sk, err := crypto.HexToECDSA(hexSk)
	if err != nil {
		return auth, err
	}

	auth, err = bind.NewKeyedTransactorWithChainID(sk, chainID)
	if err != nil {
		return nil, xerrors.Errorf("new keyed transaction failed %s", err)
	}

	auth.Value = big.NewInt(0)
	return auth, nil
}

// GetTransactionReceipt 通过交易hash获得交易详情
func GetTransactionReceipt(endPoint string, hash common.Hash) *types.Receipt {
	client, err := ethclient.Dial(endPoint)
	if err != nil {
		log.Fatal("rpc.Dial err", err)
	}
	defer client.Close()
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*3)
	defer cancel()
	receipt, err := client.TransactionReceipt(ctx, hash)
	if err != nil {
		log.Println("get transaction receipt: ", err)
	}
	return receipt
}

// CheckTx check whether transaction is successful through receipt
func CheckTx(endPoint string, txHash common.Hash, name string) error {
	var receipt *types.Receipt

	t := checkTxSleepTime
	for i := 0; i < 10; i++ {
		if i != 0 {
			t = nextBlockTime * i
		}
		time.Sleep(time.Duration(t) * time.Second)
		receipt = GetTransactionReceipt(endPoint, txHash)
		if receipt != nil {
			break
		}
	}

	if receipt == nil {
		return xerrors.Errorf("%s %s cann't get tx receipt, not packaged", name, txHash)
	}

	// 0 means fail
	if receipt.Status == 0 {
		if receipt.GasUsed != receipt.CumulativeGasUsed {
			return xerrors.Errorf("%s %s transaction exceed gas limit", name, txHash)
		}
		return xerrors.Errorf("%s %s transaction mined but execution failed, please check your tx input", name, txHash)
	}
	return nil
}
