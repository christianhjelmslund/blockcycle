pragma solidity ^0.4.20;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract BikeInsurance is usingOraclize {


  string private url;
  uint public oraclizeFee;
  address private owner;
  address public oraclizeAddress;


  event newOraclizeQuery(string description);
  event newCheckStolen(string result);

  struct Bike {
    address owner;
    uint insuredAmount;
    uint timestamp;
    uint maturityDate;
  }

  struct CallbackInfo {
    uint qType;
    string serialNo;
    uint insuredAmount;
    address Caller;
    string qResult;
  }
  
  
  mapping(bytes32 => bool) private insuredBikes;
  mapping(bytes32 => Bike) private Bikes;
  mapping(bytes32 => CallbackInfo) private cbInfo;
  mapping(bytes32 => bool) private pendingQueries;

  event Log(string info);
  event LogRenewInsurance(string info, address addr);
  event LogFallback();
  event LogInsuranceClaimed(string info, uint amount);
  event LogSuccessfulBuy(string info, address owner);


  function BikeInsurance() public payable {
    owner = msg.sender;
    oraclize_setCustomGasPrice(1000000);
    bytes32 andreas = sha256("s161765");
    bytes32 emir = sha256("s164413");
    bytes32 noah = sha256("s154407");
    bytes32 chril = sha256("s164412");
    Bikes[andreas].owner = 0xcD6E1a95a8A0CAf127aa5834B759DA44f2305E3D;
    Bikes[andreas].insuredAmount = 50000000000000000;
    Bikes[andreas].timestamp = now;
    Bikes[andreas].maturityDate = now + 1 years;
    
    Bikes[emir].owner = 0x5ABff7426203B80532c5b2D3eF2F7DDAedF02123;
    Bikes[emir].insuredAmount = 50000000000000000;
    Bikes[emir].timestamp = now;
    Bikes[emir].maturityDate = now + 1 years;
    
    Bikes[chril].owner = 0xe51d87702714767739Dce15911f910d512D2Cc46;
    Bikes[chril].insuredAmount = 50000000000000000;
    Bikes[chril].timestamp = now;
    Bikes[chril].maturityDate = now + 1 years;
    
    Bikes[noah].owner = 0xe0d7e055fb21D04Fa18df043b4bA993ad1e61c6f;
    Bikes[noah].insuredAmount = 50000000000000000;
    Bikes[noah].timestamp = now;
    Bikes[noah].maturityDate = now + 1 years;
    
    insuredBikes[sha256("s161765")] = true;
    insuredBikes[sha256("s164413")] = true;
    insuredBikes[sha256("s164412")] = true;
    insuredBikes[sha256("s154407")] = true;
    
    updateOracleFee();
    oraclizeAddress = oraclize_cbAddress();
    
    Log("BikeInsurance contract mined and running, have a nice day!");
  }
  
    function __callback(bytes32 myid, string _result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        require(pendingQueries[myid] == true);
        cbInfo[myid].qResult = _result;
        Log(cbInfo[myid].qResult);

        if(cbInfo[myid].qType == 0){
          _buyInsurance(myid);
        }
        if(cbInfo[myid].qType == 1){
          _renewInsurance(myid);
        }
        if(cbInfo[myid].qType == 2){
          _claimInsurance(myid);
        }
        
        delete pendingQueries[myid];
  }
  
  function updateOracleFee() public {
      oraclizeFee = oraclize_getPrice("URL", 10000000);
  }



  function buyInsurance(string _serialNo, uint _insuredAmount) public payable {
    if (msg.value < (_insuredAmount / 20 + oraclizeFee)) {
        Log("Insufficient funds received, please add more ETH for transaction to succeed.");
        revert();
    }
    if (insuredBikes[sha256(_serialNo)] == true) {
        Log("Bike is already insured!");
        revert();
    }

    bytes32 queryId = queryPolice(_serialNo);
    
    cbInfo[queryId].qType = 0;
    cbInfo[queryId].serialNo = _serialNo;
    cbInfo[queryId].insuredAmount = _insuredAmount;
    cbInfo[queryId].Caller = msg.sender;
    Log("Request for new insurance sent, awaiting response from database...");
    
  }
  
  function _buyInsurance(bytes32 myid) private {
      if (msg.sender != oraclize_cbAddress()) revert();
      string storage tempSerial = cbInfo[myid].serialNo;
      uint tempAmount = cbInfo[myid].insuredAmount;
      Log(cbInfo[myid].qResult);
      
      if (sha256(cbInfo[myid].qResult) == sha256("false")) {
        address(this).transfer(msg.value);
        bytes32 key = sha256(tempSerial);
        insuredBikes[key] = true;
        Bikes[key].owner = cbInfo[myid].Caller;
        Bikes[key].insuredAmount = tempAmount;
        Bikes[key].timestamp = now;
        Bikes[key].maturityDate = now + 1 years;
        LogSuccessfulBuy("Insurance registered for: ", Bikes[key].owner);
        
    } else if (sha256(cbInfo[myid].qResult) == sha256("true")) {
        Log("Bike already in police database, insurance rejected.");
    }
    
  }

  function claimInsurance(string _serialNo) public payable {
    if (msg.value < oraclizeFee) {
        Log("Insufficient ETH to process a query, please send more ETH for Tx to succeed.");
        revert();
    }
    
    if (Bikes[sha256(_serialNo)].owner == msg.sender) {
        if (Bikes[sha256(_serialNo)].maturityDate < now) {
            Log("Insurance expired, payout denied!");
            revert();
        }
        bytes32 queryId = queryPolice(_serialNo);
        cbInfo[queryId].qType = 2;
        cbInfo[queryId].serialNo = _serialNo;
        cbInfo[queryId].Caller = msg.sender;
        Log("Request for claiming insurance sent, awaiting response from database...");
    }
  } 
  

  function _claimInsurance(bytes32 myid) public payable {
      if (msg.sender != oraclize_cbAddress()) revert();
      address user = cbInfo[myid].Caller;
      bytes32 _qResult = sha256(cbInfo[myid].qResult);
      if (_qResult ==  sha256("true")) {
          bytes32 _serialNo = sha256(cbInfo[myid].serialNo);
          user.transfer(Bikes[_serialNo].insuredAmount);
          LogInsuranceClaimed("Insurance claimed! Amount of wei transfered:", Bikes[sha256(cbInfo[myid].serialNo)].insuredAmount);
          delete Bikes[_serialNo];
      } else if (_qResult == sha256("false")) {
        Log("Bike was not in Police Database, insurance claim denied.");
    }
      delete cbInfo[myid];
  } 
  
  function renewInsurance(string _serialNo) public payable {
    uint _insuredAmount = Bikes[sha256(_serialNo)].insuredAmount;
   
    require(msg.value >= (((_insuredAmount / 20 ) / 10) * 9) + oraclizeFee);

    if (msg.sender == Bikes[sha256(_serialNo)].owner) {
        bytes32 queryId = queryPolice(_serialNo);
        this.transfer(msg.value);
        cbInfo[queryId].qType = 1;
        cbInfo[queryId].serialNo = _serialNo;
        cbInfo[queryId].insuredAmount = _insuredAmount;
        cbInfo[queryId].Caller = msg.sender;
        LogRenewInsurance("Request for renewal sent, awaiting response from database...", msg.sender);
    } else {
        LogRenewInsurance("Renewal rejected!", msg.sender);
    }
}
  
    function _renewInsurance(bytes32 myid) private {
        if (msg.sender != oraclize_cbAddress()) revert();
        uint tempAmount = (cbInfo[myid].insuredAmount / 10) * 9;
        if (sha256(cbInfo[myid].qResult) == sha256("false")) {
            bytes32 key = sha256(cbInfo[myid].serialNo);
            LogRenewInsurance("Renewal of insurance successful!", Bikes[key].owner);
            Bikes[key].insuredAmount = tempAmount;
            Bikes[key].timestamp = now;
            if (Bikes[key].maturityDate < now) {
                Bikes[key].maturityDate = now + 1 years;
            } else {
                Bikes[key].maturityDate = Bikes[key].maturityDate + 1 years;
            }
        } else if (sha256(cbInfo[myid].qResult) == sha256("true")) {
            LogRenewInsurance("Renewal of insurance rejected, bike in police database!", Bikes[key].owner);
        }
    
        delete cbInfo[myid];
    }
  
  function seeInsurance(string _serialNo) public view returns (uint amount, uint expirationDate) {
    bytes32 key = sha256(_serialNo);
    if (Bikes[key].owner == msg.sender) {
      return (Bikes[key].insuredAmount, Bikes[key].maturityDate);
    } else {
      return (0, 0);
    }
  }

  function queryPolice(string _serialNo) private returns (bytes32) {
      url = strConcat("json(http://ec2-18-188-124-51.us-east-2.compute.amazonaws.com/bike-lookup/", _serialNo, ").stolen");
      Log("Oraclize query was sent, standing by for the answer..");
      bytes32 queryId = oraclize_query("URL", url, 1000000);
      pendingQueries[queryId] = true;
      return queryId;
  }
  
  function withdrawEther() public payable {
      if (msg.sender == owner) {
          msg.sender.transfer(this.balance);
      } else {
          return;
      }
  }
  
  function() payable public {
  }
}