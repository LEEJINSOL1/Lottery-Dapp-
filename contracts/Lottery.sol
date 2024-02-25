// SPDX-License-Identifier: UNLICENSED
// SPDX-License-Identifier GPL-30
pragma solidity >=0.4.22 <0.7.0;

contract Lottery{
      struct BetInfo{
         uint256 answerBlockNumber; //정답블록넘버
         address payable bettor; //배팅한사람 주소
         byte challenges; // ex) 0xab 
      }
      uint256 private _tail;
      uint256 private _head;
      mapping (uint256 => BetInfo) private _bets;

      address payable public owner; //public 자동 getter를 생성해줌 / 
      bool private mode = false; //false: use answer for test , true : use real block hash
      uint256 private _pot; //
      bytes32 public answerForTest;
      uint256 constant internal BET_AMOUNT = 5 *10**15;
      uint256 constant internal BET_BLOCK_INTERVAL = 3;
      uint256 constant internal BLOCK_LIMIT  = 256;

      enum BlockStatus { Checkable, NotRevealed, BlockLimitPassed }
      enum BettingResult {Fail, Win, Draw}

      event BET(uint256 index, address bettor, uint256 amount , byte challenges, uint256 answerBlockNumber);
      event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
      event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
      event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
      event REFUND(uint256 index, address bettor, uint256 amount, byte challenges,  uint256 answerBlockNumber);


      constructor() public{ //컨트랙트 실행될때 가장 먼저 실행되는 함수 배포가될때 보낸사람(msg.sender)을 owner에 set해줌 
                            //msg.sender은 스마트컨트랙트 자체 전역변수
        owner = msg.sender;
      } 
 
      

      //스마트컨트랙트에 변수를 조회하기위해선 view 
      function getPot() public view returns (uint256 pot){
      return _pot;
      }



      /** 
        @dev 배팅과 정답을 체크한다. 유저는 0.005eth 를 보내야하고 , 글자배팅(1byte)를 보낸다.
        큐에 저장된 배팅정보는 이후 distribute 함수에서 해결된다
        @param challenges 유저가 배팅하는 글자
        @return 함수가 잘 수행되었는지 확인 bool type 
       */
      function betAndDistribute(byte challenges) public payable returns (bool result){
         bet(challenges);

         distribute();

         return true;
      }

      //BET 배팅
      /** 
        @dev 배팅을 한다. 유저는 0.005eth 를 보내야하고 , 글자배팅(1byte)를 보낸다.
        큐에 저장된 배팅정보는 이후 distribute 함수에서 해결된다
        @param challenges 유저가 배팅하는 글자
        @return 함수가 잘 수행되었는지 확인 bool type 
       */
      function bet(byte challenges) public  payable returns  (bool result){
         //check the proper ether is sent
         require(msg.value == BET_AMOUNT, "Not enough ETH"); 
         //push bet to the queue
         require(pushBet(challenges), "Fail to add a new Bet");
         //emit event
         emit BET(_tail-1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

         
         return true;
      }
         

      // Distribute 검증
      /**
      @dev 배팅 결과값을 확인하고 팟머니를 분배한다.
      정답 실패 : 팟머니축적 , 정답맞춤 : 팟머니획득, 한글자맞춤 or 정답확인불가 : 배팅금액 돌려받음
       */
      function distribute() public {
         //큐에 저장된 배팅정보가  3(head),4,5,6,7,8,9,10(tail)
         uint256 cur; 
         uint256 transferAmount;

         BetInfo memory b;
         BlockStatus currentBlockStatus; 
         BettingResult currentBettingResult;


         for (cur=_head; cur<_tail; cur++){
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            

            // checkable : block.number > Answerblocknumber && block.number < block_limit + answerblocknumber / 1
            if(currentBlockStatus == BlockStatus.Checkable){
               bytes32 answerBlockHash =  getAnswerBlockHash(b.answerBlockNumber);
               currentBettingResult = isMatch(b.challenges,answerBlockHash);
               //if win => bettor gets pot
               if(currentBettingResult == BettingResult.Win){
                  //transfer pot
                  transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT );
                  // pot = 0 
                  _pot = 0;
                  // emit Win
                  emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                  
               }
               //if fail => bettor's money goes pot 
               if(currentBettingResult == BettingResult.Fail){
                  //pot = pot + betamount 
                  _pot = _pot + BET_AMOUNT;
                  // emit Fail
                  emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                  

               }
               //if draw  refund bettor's money 
               if(currentBettingResult == BettingResult.Draw){
                  // transfer only betamount 
                  transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT );

                  // emit Draw
                  emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
               }
            }
            // not revealed  : 마이닝이 안된상황 : block.number <= answerblocknumber 2
            if(currentBlockStatus == BlockStatus.NotRevealed){
               break;
            }
            // block limit passed : block.number >= answerblocknumber + blocklimit 3
            if(currentBlockStatus == BlockStatus.BlockLimitPassed){
               //refund
               transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT );
               //emit refund 
               emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }         
            //check the answer
            popBet(cur);
         }
         _head = cur;
      }
      function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256){
         uint256 fee = 0;

         uint256 amountWithoutFee = amount - fee; //1%

         // transfer to addr
         addr.transfer(amountWithoutFee);
         
         // transfer to owner
         owner.transfer(fee);

         // call , send , transfer 

         return amountWithoutFee;
      }

      function setAnswerForTest(bytes32 answer) public  returns(bool result) {
         require(msg.sender == owner, "only owner can set the answer for test mode");
         answerForTest = answer;
         return true;
      }
      function getAnswerBlockHash(uint256 answerBlockNumber ) internal view returns(bytes32 answer) {
         return mode ? blockhash(answerBlockNumber) : answerForTest;
      }

      /**
      * @dev 배팅글자와 정답을 확인한다.
        @param challenges 배팅 글자
        @param answer 블락해쉬
        @return 
       */
      function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult){
         // challenges 0xab
         // answer 0xab....ff 32 bytes

         byte c1 = challenges;
         byte c2 = challenges;

         byte a1 = answer[0];
         byte a2 = answer[0];

         // get first number
         c1 = c1 >> 4; //0xab -> 0x0a
         c1 = c1 << 4; // 0xab -> 0xa0

         a1 = a1 >> 4;
         a1 = a1 << 4;

         ///get second number
         c2 = c2 << 4; //0xab -> 0xb0
         c2 = c2 >> 4; //0xb0 -> 0x0b

         a2 = a2 << 4;
         a2 = a2 >> 4; 

         if(a1 == c1 && a2 == c2){
            return BettingResult.Win;
         }
         if(a1 == c1 || a2 == c2 ){
            return BettingResult.Draw;
         }
         return BettingResult.Fail;

      }

      function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus ){
         if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber){
            return BlockStatus.Checkable;
         }
         if(block.number <= answerBlockNumber){
            return BlockStatus.NotRevealed;
         }
         if(block.number >= answerBlockNumber + BLOCK_LIMIT){
            return BlockStatus.BlockLimitPassed;
         }
         return BlockStatus.BlockLimitPassed;

      }

      //결과값을 검증하는 큐

        //값이 틀리면 팟머니에 넣고 맞으면 돌려주는  

      function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor , byte challenges){
         BetInfo memory b = _bets[index]; 
         answerBlockNumber = b.answerBlockNumber;
         bettor = b.bettor;
         challenges = b.challenges;
      }

      //push
      function pushBet(byte challenges) internal returns (bool){
         BetInfo memory b;
         b.bettor = msg.sender; //https://docs.soliditylang.org/en/v0.8.24/units-and-global-variables.html 참고(전역변수)
         b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; //block.number => 해당트랜잭션이 들어가는 블락넘버 return 
         b.challenges = challenges;

         _bets[_tail] = b;
         _tail++;

         return true;
      }

      //pop
      function popBet(uint256 index) internal returns (bool){
         delete _bets[index];
         return true;
      }
}