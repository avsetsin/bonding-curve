// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title CoolDown Contract
 * @notice This contract implements a cooldown mechanism for managing cooldown times for accounts
 * @dev This contract is abstract and inherits from the Ownable2Step contract
 */
abstract contract CoolDown is Ownable2Step {
    uint256 public coolDownTime;
    mapping(address => uint256) public coolDownTimes;

    event CoolDownTimeUpdated(uint256 coolDownTime);
    event CoolDownStarted(address indexed account, uint256 coolDownToTime);

    error CoolDownNotPassed(address account, uint256 coolDownToTime);

    /**
     * @notice Initializes the CoolDown contract with the specified cooldown time
     * @param coolDownTime_ The cooldown time in seconds
     */
    constructor(uint256 coolDownTime_) {
        _updateCoolDownTime(coolDownTime_);
    }

    /**
     * @notice Updates the cooldown time
     * @dev Only the contract owner can call this function
     * @param newCoolDownTime The new cooldown time in seconds
     */
    function updateCoolDownTime(uint256 newCoolDownTime) public onlyOwner {
        _updateCoolDownTime(newCoolDownTime);
    }

    /**
     * @notice Checks if the cooldown period has passed for the specified account
     * @param account The account address to check
     * @return A boolean indicating whether the cooldown period has passed
     */
    function isCoolDownPassed(address account) public view returns (bool) {
        return block.timestamp >= coolDownTimes[account];
    }

    /**
     * @dev Checks if the cooldown period has passed for the specified account
     * @param account The account address to check
     */
    function _checkCoolDownPassed(address account) internal view {
        uint256 coolDownToTime = coolDownTimes[account];
        if (block.timestamp < coolDownToTime) {
            revert CoolDownNotPassed(account, coolDownToTime);
        }
    }

    /**
     * @dev Updates the cooldown time
     * @param newCoolDownTime The new cooldown time in seconds
     */
    function _updateCoolDownTime(uint256 newCoolDownTime) internal {
        coolDownTime = newCoolDownTime;
        emit CoolDownTimeUpdated(newCoolDownTime);
    }

    /**
     * @dev Sets the cooldown time for the specified account
     * @param account The account address to set the cooldown time for
     */
    function _setCoolDown(address account) internal {
        unchecked {
            uint256 coolDownToTime = block.timestamp + coolDownTime;
            coolDownTimes[account] = coolDownToTime;
            emit CoolDownStarted(account, coolDownToTime);
        }
    }
}
