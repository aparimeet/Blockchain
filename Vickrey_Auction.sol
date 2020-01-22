pragma solidity ^0.5.0;

contract Auction {
    /**Add 1 hour limit*/
    uint biddingEnds = now + 1 hours;

    struct Bidder {
        address payable _address;
        uint bidAmount;
    }

    Bidder[5] suppliers;
    Bidder[5] consumers;

    uint totalConsumers;
    uint totalSuppliers;

    address private owner;
    mapping( address => uint ) consumerBalance;

    //Timed, we need to end bidding in 1 hour
     modifier timed {
        if(now < biddingEnds) {
            _;
        }
        else
        {
            //Add exception
            revert();
        }
     }

    constructor() public {
        totalConsumers = 0;
        totalSuppliers = 0;
        owner = msg.sender;

    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    
    //End supplier bidding in 1 hour
    function supplierBid(uint bidAmount) public timed{
        Bidder storage bidder = suppliers[totalSuppliers];
        bidder._address = msg.sender;
        bidder.bidAmount = bidAmount;

        totalSuppliers++;
    }
    //End consumer bidding in 1 hour
    function consumerBid(uint bidAmount) public payable timed{
        require(msg.value == bidAmount * 10**18);
        Bidder storage bidder = consumers[totalConsumers];
        consumerBalance[msg.sender] = msg.value;
        bidder._address = msg.sender;
        bidder.bidAmount = bidAmount;

        totalConsumers++;
    }
    
    function sortMatchBids() public  ownerOnly timed{
        // Create memory copies
        Bidder[5] memory suppliersCopy = suppliers;
        Bidder[5] memory consumersCopy = consumers;

        // Sort copies
        quickSort(suppliersCopy, int(0), int(totalSuppliers - 1));
        quickSort(consumersCopy, int(0), int(totalConsumers - 1));

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
                uint value = consumerPayableBid * 10**18;
                suppliersCopy[supplierIndex]._address.transfer(value);
                consumerBalance[consumersCopy[consumerIndex]._address] -= value;

                // TODO Supplier sends assets to Consumer

                supplierIndex++;
                consumerIndex++;
            }
        }

        for(uint i=0; i<totalConsumers; i++) {
            address payable consumerAddress =  consumersCopy[i]._address;
            consumerAddress.transfer(consumerBalance[consumerAddress]);
        }

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
