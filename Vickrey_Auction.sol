pragma solidity ^0.4.0;

contract Auction {
    
    struct Bidder {
        address _address;
        uint bidAmount;
    }
    
    Bidder[5] suppliers;
    Bidder[5] consumers;
    
    uint totalConsumers;
    uint totalSuppliers;
    
    uint[3][5] public tradeMatch; // Supp, Cons, Price //Test purpose
    uint public tradeCount;
    
    address private owner;
    
    constructor() public {
        totalConsumers = 0;
        totalSuppliers = 0;
        owner = msg.sender;
        
        //Test:
        tradeCount = 0;
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    
    function supplierBid(uint bidAmount) public {
        Bidder storage bidder = suppliers[totalSuppliers];
        
        bidder._address = msg.sender;
        bidder.bidAmount = bidAmount;
        
        totalSuppliers++;
    }
    
    function consumerBid(uint bidAmount) public payable {
        require(msg.value == bidAmount * 10**18);
        Bidder storage bidder = consumers[totalConsumers];
        
        bidder._address = msg.sender;
        bidder.bidAmount = bidAmount;
        
        totalConsumers++;
    }
    
    function sortMatchBids() public ownerOnly {
        // Create memory copies
        Bidder[5] memory suppliersCopy = suppliers;
        Bidder[5] memory consumersCopy = consumers;
        
        // Sort copies
        quickSort(suppliersCopy, int(0), int(totalSuppliers - 1));
        quickSort(consumersCopy, int(0), int(totalConsumers - 1));
        
        // // Write back to original. Not really needed, since using copies for processing
        //
        // for( uint i=0; i<totalSuppliers; i++) {
        //     suppliers[i] = suppliersCopy[i];
        // }
        // for( uint j=0; j<totalConsumers; j++) {
        //     consumers[j] = consumersCopy[j];
        // }
        
        // Matching
        uint consumerIndex = 0;
        uint supplierIndex = 0;
        uint consumerPayableBid;
        
        while(consumerIndex<totalConsumers && supplierIndex<totalSuppliers) {
            consumerPayableBid = (consumerIndex == totalConsumers - 1) // if lowest bid
                                 ? consumersCopy[consumerIndex].bidAmount
                                 : consumersCopy[consumerIndex+1].bidAmount;
                                 
            if(consumerPayableBid < suppliersCopy[supplierIndex].bidAmount  )
                supplierIndex++;
            else {
                suppliersCopy[supplierIndex]._address.transfer(consumerPayableBid * 10**18);
                
                // TODO Supplier sends assets to Consumer
                
                // For test:
                tradeMatch[tradeCount][0] = supplierIndex;
                tradeMatch[tradeCount][1] = consumerIndex;
                tradeMatch[tradeCount][2] = consumerPayableBid;
                tradeCount++;
                // test ends 
                
                supplierIndex++;
                consumerIndex++;
            }
        }
        
        // TODO Refund remaining balance to the correct consumers
        // Can be acheived by keeping _balance mapping( address => uint ) 
        // Updates: add balance on placing bid, subtract on sucessful match
        // At the end, that is here, tranfer back an amount equal to balance to every consumer  
    }
    
    function quickSort(Bidder[5] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        Bidder memory pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)].bidAmount > pivot.bidAmount) i++;
            while (pivot.bidAmount > arr[uint(j)].bidAmount) j--;
            if (i <= j) {
                ( arr[uint(i)], arr[uint(j)] )  =  ( arr[uint(j)], arr[uint(i)] );
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }
}