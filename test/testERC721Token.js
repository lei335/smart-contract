const ERC721Token = artifacts.require("ERC721Token");

// 测试是否触发合约revert
async function assertRevert (promise) {
    try {
        await promise;
    } catch (error) {
        console.log("tx error info:", error.reason);
        const revertFound = error.message.search('revert') >= 0;
        assert(revertFound, `Expected "revert", got ${error} insted`);
        return;
    }
    assert.fail('Expected revert not received');
}

contract("ERC721Token", async accounts => {
    it("should mint token correctly", async () => {
        let instance = await ERC721Token.deployed();
        let _owner = await instance.owner.call();
        console.log("owner is:", _owner);
        let balance = await instance.balanceOf.call(accounts[0]);
        assert.equal(balance.valueOf(), 0);

        // mint
        let tokenId = 0;
        let tokenURI = "https://memo.ethdrive/xxxxxxxx0";
        let tokenData = {keyword:"animal", description:"this is a dog"};
        await instance.safeMint(accounts[0], tokenId, tokenURI, tokenData);

        // get balanceOf
        balance = await instance.balanceOf.call(accounts[0]);
        assert.equal(balance.valueOf(), 1);

        // get tokenURI
        let _tokenURI = await instance.tokenURI.call(tokenId);
        assert.equal(_tokenURI, tokenURI);

        // get tokenData
        let _tokenData = await instance.tokenData.call(tokenId);
        assert.equal(_tokenData[0], tokenData.keyword);
        assert.equal(_tokenData[1], tokenData.description);

        // get ownerOf
        let _tokenOwner = await instance.ownerOf(tokenId);
        assert.equal(_tokenOwner, accounts[0]);

        // get totalSupply
        let _totalSupply = await instance.totalSupply.call();
        assert.equal(_totalSupply, 1);

        // get tokenOfOwnerByIndex
        let _tokenId = await instance.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(_tokenId, tokenId);

        // get tokenByIndex
        _tokenId = await instance.tokenByIndex(0);
        assert.equal(_tokenId, tokenId);

        // mint 
        tokenId = 1;
        tokenURI = "https://memo.ethdrive/xxxxxxxx1";
        tokenData = {keyword:"animal", description:"this is a cat"};
        await instance.safeMint(accounts[0], tokenId, tokenURI, tokenData);
    });
    it("mint and burn and transfer should fail if paused", async () => {
        let instance = await ERC721Token.deployed();
        
        // accounts[1] paused, should fail
        await assertRevert(instance.pause({from: accounts[1]}));

        let _paused = await instance.paused();
        assert.equal(_paused, false);
    });
    it("should approve correctly", async () => {
        let instance = await ERC721Token.deployed();

        // mint
        let tokenId = 0;

        // get approved
        let _approvedAddress = await instance.getApproved(tokenId);
        assert.equal(_approvedAddress, 0x0);

        // approve
        await instance.approve(accounts[1], tokenId);
        _approvedAddress = await instance.getApproved(tokenId);
        assert.equal(_approvedAddress, accounts[1]);

        // get isApprovedForAll
        let _isApprovedForAll = await instance.isApprovedForAll(accounts[0], accounts[1]);
        assert.equal(_isApprovedForAll, false);

        // approve for all
        await instance.setApprovalForAll(accounts[1], true);
        _isApprovedForAll = await instance.isApprovedForAll(accounts[0], accounts[1]);
        assert.equal(_isApprovedForAll, true);
    });
});