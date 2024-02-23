// SPDX-License-Identifier: UNLICENSED
// SPDX-License-Identifier GPL-30

pragma solidity >=0.4.22 <0.7.0;

contract Lottery{
     address public owner; //public 자동 getter를 생성해줌 / 

     constructor() public{ //컨트랙트 실행될때 가장 먼저 실행되는 함수 배포가될때 보낸사람(msg.sender)을 owner에 set해줌 
                            //msg.sender은 스마트컨트랙트 자체 전역변수
        owner = msg.sender;
     } 

     function getSomeValue() public pure returns(uint256 value){ //다른밸류를 사용하지않기떄문에 pure
        return 5;
     }
}