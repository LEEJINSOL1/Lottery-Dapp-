const Lottery = artifacts.require("Lottery");
const assertRevert = require('./assertRevert');
const expectEvent = require('./expectEvent');
 contract('Lottery', function([deployer, user1, user2]){
    let lottery;
    let betAmount = 5 * 10 ** 15; 
    let bet_block_interval = 3;
    beforeEach(async () => {
        lottery = await Lottery.new();
    })

    

    it('getPot should return current pot', async() => {
        let pot = await lottery.getPot();
        assert.equal(pot,0)
    })

    describe('BET', function(){
            
        it('should fail when the bet money is not 0.005 ETH', async() => {
            // FAIL transaction
            await assertRevert(lottery.bet("0xab", {from:user1, value:betAmount} ))
            //transcation object {chain id , value , to , from, gaslimit , gasprice } 
        })
        
        it.only('should put the bet to the bet queue with 1 bet', async() => {
            //bet
            let receipt = await lottery.bet('0xab', {from:user1, value:betAmount})
            //console.log(receipt)

            let pot = await lottery.getPot();
            assert.equal(pot, 0);
            //check contract balance == 0.005 ETH
            let contractBalance = await web3.eth.getBalance(lottery.address);
            assert.equal(contractBalance, betAmount);
            //check bet info
            let currentBlockNumber = await web3.eth.getBlockNumber();
            bet = await lottery.getBetInfo(0);

            assert.equal(bet.answerBlockNumber, currentBlockNumber + bet_block_interval)
            assert.equal(bet.bettor, user1)
            //console.log('bet : ' , (bet.challenges))
            assert.equal(bet.challenges, '0xab')
            
            //check log
            console.log(receipt)
            await expectEvent.inLogs(receipt.logs, 'BET')
        })
    })
 });