contract SampleOffer {
    uint totalCosts;
    uint oneTimeCosts;
    uint dailyCosts;
    address contractor;
    bytes32 hashOfTheTerms;
    uint minDailyCosts;
    uint paidOut;
    uint dateOfSignature;
    DAO client; // address of DAO
    bool public promiseValid;
    uint public rewardDivisor;
    uint public deploymentReward;

    modifier callingRestriction {
        if (promiseValid) {
            if (msg.sender != address(client))
                throw;
        } else if (msg.sender != contractor) {
            throw;
        }
        _
    }

    modifier onlyClient {
        if (msg.sender != address(client))
            throw;
        _
    }

    function SampleOffer(
        address _contractor,
        bytes32 _hashOfTheTerms,
        uint _totalCosts,
        uint _oneTimeCosts,
        uint _minDailyCosts,
        uint _rewardDivisor,
        uint _deploymentReward
    ) {
        contractor = _contractor;
        hashOfTheTerms = _hashOfTheTerms;
        totalCosts = _totalCosts;
        oneTimeCosts = _oneTimeCosts;
        minDailyCosts = _minDailyCosts;
        dailyCosts = _minDailyCosts;
        rewardDivisor = _rewardDivisor;
        deploymentReward = _deploymentReward;
    }

    function sign() {
        if (msg.value < totalCosts || dateOfSignature != 0)
            throw;
        if (!contractor.send(oneTimeCosts))
            throw;
        client = DAO(msg.sender);
        dateOfSignature = now;
        promiseValid = true;
    }

    function setDailyCosts(uint _dailyCosts) onlyClient {
        dailyCosts = _dailyCosts;
        if (dailyCosts < minDailyCosts)
            promiseValid = false;
    }

    function returnRemainingMoney() onlyClient {
        if (client.receiveEther.value(this.balance)())
            promiseValid = false;
    }

    function getDailyPayment() {
        if (msg.sender != contractor)
            throw;
        uint amount = (now - dateOfSignature) / (1 days) * dailyCosts - paidOut;
        if (contractor.send(amount))
            paidOut += amount;
    }

    function setRewardDivisor(uint _rewardDivisor) callingRestriction {
        if (_rewardDivisor < 50)
            throw; // 2% is the default max reward
        rewardDivisor = _rewardDivisor;
    }

    function setDeploymentFee(uint _deploymentReward) callingRestriction {
        if (deploymentReward > 10 ether)
            throw; // TODO, set a max defined by Curator,
                   //   or ideally oracle (set in euro)
        deploymentReward = _deploymentReward;
    }

    function updateClientAddress(DAO _newClient) callingRestriction {
        client = _newClient;
    }

    // interface for Ethereum Computer
    function payOneTimeReward() returns(bool) {
        if (msg.value < deploymentReward)
            throw;
        if (promiseValid) {
            if (client.DAOrewardAccount().call.value(msg.value)()) {
                return true;
            } else {
                throw;
            }
        } else {
            if (contractor.send(msg.value)) {
                return true;
            } else {
                throw;
            }
        }
    }

    // pay reward
    function payReward() returns(bool) {
        if (promiseValid) {
            if (client.DAOrewardAccount().call.value(msg.value)()) {
                return true;
            } else {
                throw;
            }
        } else {
            if (contractor.send(msg.value)) {
                return true;
            } else {
                throw;
            }
        }
    }
}
