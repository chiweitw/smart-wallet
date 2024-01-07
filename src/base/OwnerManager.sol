// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title OwnerManager - Manages admins, owners and the confirmation number.
contract OwnerManager {
    address[] public admins;
    address[] public owners;
    uint256 public confirmationNum;

	modifier onlyAdmin {
		require(isAdmin(msg.sender) == true, "Only Admin");
		_; 
	}

	modifier onlyOwner {
		require(isOwner(msg.sender) == true, "Only Owner");
		_;
	}

    /// @dev Check if an address is an admin.
    /// @param _admin Address to be checked.
    function isAdmin(address _admin) public view returns (bool) {
        for (uint i=0; i<admins.length; i++) {
            if (_admin == admins[i])
                return true;
        }
        return false;
    }

    /// @dev Check if an address is an owner.
    /// @param _owner Address to be checked.
    function isOwner(address _owner) public view returns (bool) {
		for (uint i=0; i<owners.length; i++) {
			if (_owner == owners[i])
				return true;
		}
		return false;
    }

    /// @dev Admin add an owner and change the confirmation number.
    /// @param _owner Owner to be added.
    /// @param _confirmationNum New confirmation number.
    function addOwnerAndConfirmationNumber(address _owner, uint256 _confirmationNum) public onlyAdmin {
        require(_owner != address(0) && !isOwner(_owner), "Invalid Owner");
        owners.push(_owner);
        require(_confirmationNum <= owners.length, "Invalid confirmation number");
        if (_confirmationNum != confirmationNum) {
            _changeConfirmationNum(_confirmationNum);
        }
    }

    /// @dev Admin remove an owner and change the confirmation number.
    /// @param _owner Owner to be removed.
    /// @param _confirmationNum New confirmation number.
    function removeOwnerAndConfirmationNumber(address _owner, uint256 _confirmationNum) public onlyAdmin {
        require(isOwner(_owner), "Owner not existed");
        for (uint i=0; i<owners.length; i++) {
            if (owners[i] == _owner) _removeOwner(i); 
        }
        require(_confirmationNum <= owners.length, "Invalid confirmation number");
        if (_confirmationNum != confirmationNum) {
            _changeConfirmationNum(_confirmationNum);
        }
    }

    /// @dev Admin can add an owner to admin.
    /// @param _owner Owner to be promoted.
    function addAdmin(address _owner) public onlyAdmin {
        require(isOwner(_owner), "Owner not existed");
        admins.push(_owner);
    }

    /// @dev Owner can leave the party by their self.
    function leaveParty() public onlyOwner {
        if (isAdmin(msg.sender)) {
            require(admins.length > 1, "At least one admin!"); // Must have at least one admin.
        }
        for (uint256 i=0; i<owners.length; i++) {
            if (owners[i] == msg.sender) {
                _removeOwner(i); 
            }
        }
    }

    /// @dev Change the confirmation number.
    /// @param _confirmationNum New confirmation number.
    function _changeConfirmationNum(uint256 _confirmationNum) internal {
        require(_confirmationNum <= owners.length); // must less than the number of owners
        require(_confirmationNum >= 1); // at least one owner
        confirmationNum = _confirmationNum;
    }

    /// @dev Remove an owner.
    /// @param _index Index of the owner to be removed.
    function _removeOwner(uint _index) internal {
        require(_index < owners.length, "index out of bound");
        for (uint256 i=_index; i<owners.length-1; i++) {
            owners[i] = owners[i+1];
        }
        owners.pop();
    }
}