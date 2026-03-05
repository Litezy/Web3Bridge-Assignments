// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

// contract NumberFactory {
//     event ChildAddress(address _address);

//     function registerNumber(uint _num) external {
//         bytes32 y = keccak256(abi.encodePacked(_num));
//        NumberChildren newNumber = new NumberChildren{salt: y}(_num);
//         emit ChildAddress(address(newNumber));
//     }
// }

// contract NumberChildren {
//     uint256 ownerNumber;

//     constructor(uint256 _no) {
//         ownerNumber = _no;
//     }

//     function checkHash() public view returns (bytes32 r) {
//         r = keccak256(abi.encodePacked(ownerNumber));
//     }
// }





contract NumberFactory {
    event YYY(address);

    function registerNumber(uint256 _no) external {

        // deploy clone
        bytes32 y = keccak256(abi.encodePacked(_no));
        NumberChildren n = new NumberChildren{salt: y}(_no);

        emit YYY(address(n));

    }
}

contract NumberChildren {
    uint256 ownerNumber;

    constructor(uint256 _no) {
        ownerNumber = _no;
    }

    function checkHash() public view returns(bytes32 r) {
        r = keccak256(abi.encodePacked(ownerNumber));
    }


}

