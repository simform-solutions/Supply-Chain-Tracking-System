pragma solidity ^0.4.20;

import "./Database.sol";

contract Product {
  address public DATABASE_CONTRACT;
  address public PRODUCT_FACTORY;

  struct Action {
    address handler;
    bytes32 description;
    uint timestamp;
    uint blockNumber;
  }

  modifier notConsumed {
    require(!isConsumed);  
    _;
  }

  address[] public parentProducts;
  
  address[] public childProducts;

  bool public isConsumed;

  bytes32 public name;

  bytes32 public additionalInformation;

  Action[] public actions;

  function Product(bytes32 _name, bytes32 _additionalInformation, address[] _parentProducts, address _DATABASE_CONTRACT, address _PRODUCT_FACTORY) public{
    name = _name;
    isConsumed = false;
    parentProducts = _parentProducts;
    additionalInformation = _additionalInformation;

    DATABASE_CONTRACT = _DATABASE_CONTRACT;
    PRODUCT_FACTORY = _PRODUCT_FACTORY;

    Action memory creation;
    creation.handler = msg.sender;
    creation.description = "Product creation";
    creation.timestamp = now;
    creation.blockNumber = block.number;

    actions.push(creation);

    Database database = Database(DATABASE_CONTRACT);
    database.storeProductReference(this);
  }

  function () {
    // If anyone wants to send Ether to this contract, the transaction gets rejected
    revert();
  }

  /* Function to add an Action to the product.
     @param _description The description of the Action.
     @param _newProductNames In case that this Action creates more products from
            this Product, the names of the new products should be provided here.
     @param _newProductsAdditionalInformation In case that this Action creates more products from
            this Product, the additional information of the new products should be provided here.
     @param _consumed True if the product becomes consumed after the action. */
  function addAction(bytes32 description, bytes32[] newProductsNames, bytes32[] newProductsAdditionalInformation, bool _consumed) public notConsumed {
    require (newProductsNames.length == newProductsAdditionalInformation.length);

    Action memory action;
    action.handler = msg.sender;
    action.description = description;
    action.timestamp = now;
    action.blockNumber = block.number;

    actions.push(action);

    ProductFactory productFactory = ProductFactory(PRODUCT_FACTORY);

    for (uint i = 0; i < newProductsNames.length; ++i) {
      parentProducts = new address[](1);
      parentProducts[0] = this;
      productFactory.createProduct(newProductsNames[i], newProductsAdditionalInformation[i], parentProducts, DATABASE_CONTRACT);
    }

    isConsumed = _consumed;
  }

  /* Function to merge some products to build a new one.
     @param otherProducts addresses of the other products to be merged.
     @param newProductsName Name of the new product resulting of the merge.
     @param newProductAdditionalInformation Additional information of the new product resulting of the merge.*/
  function merge(address[] otherProducts, bytes32 newProductName, bytes32 newProductAdditionalInformation) public notConsumed {
    ProductFactory productFactory = ProductFactory(PRODUCT_FACTORY);
    address newProduct = productFactory.createProduct(newProductName, newProductAdditionalInformation, otherProducts, DATABASE_CONTRACT);

    this.collaborateInMerge(newProduct);
    for (uint i = 0; i < otherProducts.length; ++i) {
      Product prod = Product(otherProducts[i]);
      prod.collaborateInMerge(newProduct);
    }
  }

  /* Function to collaborate in a merge with some products to build a new one.
     @param newProductsAddress Address of the new product resulting of the merge.*/
  function collaborateInMerge(address newProductAddress) public notConsumed {
    childProducts.push(newProductAddress);

    Action memory action;
    action.handler = this;
    action.description = "Collaborate in merge";
    action.timestamp = now;
    action.blockNumber = block.number;
    actions.push(action);

    this.consume();
  }

  function consume() public notConsumed {
    isConsumed = true;
  }
}

contract ProductFactory {

    function ProductFactory() {}

    function () {
      // If anyone wants to send Ether to this contract, the transaction gets rejected
      revert();
    }

    /* Function to create a Product
       @param _name The name of the Product
       @param _additionalInformation Additional information about the Product,
              generally as a JSON object.
       @param _parentProducts Addresses of the parent products of the Product.
       @param _DATABASE_CONTRACT Reference to its database contract*/
    function createProduct(bytes32 _name, bytes32 _additionalInformation, address[] _parentProducts, address DATABASE_CONTRACT) public returns(address) {
      return new Product(_name, _additionalInformation, _parentProducts, DATABASE_CONTRACT, this);
    }
}
