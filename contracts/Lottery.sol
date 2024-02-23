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

      address public owner; //public 자동 getter를 생성해줌 / 
      
      uint256 private _pot; //
      uint256 constant internal BET_AMOUNT = 5 *10**15;
      uint256 constant internal BET_BLOCK_INTERVAL = 3;
      uint256 constant internal BLOCK_LIMIT  = 256;

      event BET(uint256 index, address bettor, uint256 amount , byte challenges, uint256 answerBlockNumber);
      

      constructor() public{ //컨트랙트 실행될때 가장 먼저 실행되는 함수 배포가될때 보낸사람(msg.sender)을 owner에 set해줌 
                            //msg.sender은 스마트컨트랙트 자체 전역변수
        owner = msg.sender;
      } 
 
      

      //스마트컨트랙트에 변수를 조회하기위해선 view 
      function getPot() public view returns (uint256 pot){
      return _pot;
      }

      /** 
        @dev 배팅을 한다. 유저는 0.005eth 를 보내야하고 , 글자배팅(1byte)를 보낸다.
        큐에 저장된 배팅정보는 이후 distribute 함수에서 해결된다
        @param challenges 유저가 배팅하는 글자
        @return 함수가 잘 수행되었는지 확인 bool type 
       */
      //BET 배팅 
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