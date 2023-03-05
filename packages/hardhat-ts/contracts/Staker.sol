pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping (address => uint256) public balances;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;

    bool private openForWithdraw = false;

    event Stake(address indexed from, uint256 amount);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    modifier checkWithdraw() {
        require(address(this).balance < threshold, 'the threshold is not reached');
        openForWithdraw = true;
        _;
    }

    modifier notCompleted() {
        require(exampleExternalContract.completed() == false, 'This staking is completed');
        _;
    }

    function stake() public payable {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() public notCompleted {
        if (address(this).balance >= threshold && timeLeft() == 0) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    function withdraw() public notCompleted checkWithdraw {
        require(openForWithdraw == true, 'the threshold is not reached');

        bool sendSuccess = payable(msg.sender).send(balances[msg.sender]);
        require(sendSuccess, "Send failed");
        balances[msg.sender] = 0;
    }

    function timeLeft() public view returns (uint256) {
        if(block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    receive() external payable {
        stake();
    }
}
