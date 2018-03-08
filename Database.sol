pragma solidity ^0.4.20;

contract owned {
    address public owner;

    function owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
}

contract Database is owned {
  address[] public products;

  struct Handler {
    string _name;
    string _additionalInformation;
  }

  mapping(address => Handler) public addressToHandler;

  function Database() {}

  function () {
    // If anyone wants to send Ether to this contract, the transaction gets rejected
    revert();
  }

  /* Function to add a Handler reference
     @param _address address of the handler
     @param _name The name of the Handler
     @param _additionalInformation Additional information about the Product,
            generally as a JSON object. */
  function addHandler(address _address, string _name, string _additionalInformation) onlyOwner public{
    Handler memory handler;
    handler._name = _name;
    handler._additionalInformation = _additionalInformation;

    addressToHandler[_address] = handler;
  }

  function storeProductReference(address productAddress) public{
    products.push(productAddress);
  }

}
