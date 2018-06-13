pragma solidity ^0.4.16;

// 
interface token {
    function transfer(address receiver, uint amount) external;
}

contract Ico {
    // 众筹账户
    address public beneficiary;
    // 众筹目标
    uint public fundingGoal;
    // 实际众筹数额
    uint public amountRaised;
    // 众筹截至日期
    uint public deadline;
    // 和以太币的兑换价格，即初始发币和以太币的价格比例
    uint public price;
    // 
    token public tokenReward;
    
    // 账户
    mapping(address => uint256) public balanceOf;
    // 众筹是否结束
    bool crowdsaleClosed = false;

    // 定义事件：众筹目标达到、转出基金
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    // 构造函数
    constructor (
        uint fundingGoalInEthers,             // 目标众筹额度，以以太币为单位
        uint durationInMinutes,               // 重筹时间
        uint etherCostOfEachToken,            // Token和以太币兑换比例
        address addressOfTokenUsedAsReward    // 收益账户
    ) public {
        // 受益人，为合约账户，即部署合约的人
        beneficiary = msg.sender;
        // 目标
        fundingGoal = fundingGoalInEthers * 1 ether;
        // 期限
        deadline = now + durationInMinutes * 1 minutes;
        // Token价格
        price = etherCostOfEachToken * 1 ether;
        // 
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    // 需要记录数据和付费
    function () public payable {
        require(!crowdsaleClosed);  // 众筹未结束
        
        uint amount = msg.value;
        // 众筹捐赠
        balanceOf[msg.sender] += amount;
        // 筹资
        amountRaised += amount;
        if (amount == 0) {
            // 如果没有打钱，就像该账户打入10
            tokenReward.transfer(msg.sender, 10);
        } else {
            // 将钱转移到
            tokenReward.transfer(msg.sender, amount / price);
        }

        emit FundTransfer(msg.sender, amount, true);
    }

    // 判断是否结束
    modifier afterDeadline() {
        if (now >= deadline) {
            _;
        }
    }

    // 判断众筹结束时是否完成目标
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            // 触发事件
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    // 取现
    function safeWithdrawal() public afterDeadline {
        // 如果未达到目标，钱沿原路返回
        if (amountRaised < fundingGoal) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
            }
        }

        if (fundingGoal <= amountRaised && beneficiary == msg.sender) {
            beneficiary.transfer(amountRaised);
            emit FundTransfer(beneficiary, amountRaised, false);
        }
    }
}