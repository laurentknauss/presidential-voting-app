


        // SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



/// @title A contract for token-gated voting between two candidates
/// @notice This contract allows token holders to vote for one of two candidates
/// @dev Inherits from OpenZeppelin's Ownable contract for basic access control
contract TwoCandidateVoting is
 Initializable, OwnableUpgradeable,
 UUPSUpgradeable, ReentrancyGuardUpgradeable {


    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/    
    /// @notice _requiredToken The address of the ERC20 token used for voting rights
    /// @notice _requiredBalance The minimum token balance required to vote
    /// @notice _gracePeriod The grace period after voting ends 
    /// @notice _votingEndTime The timestamp when voting ends
    /// @notice _refundStartTime The timestamp when refunds can start being claimed
    /// @notice _votingFinalized Indicates whether voting has been finalized
    /// @notice _NumVotesForCandidate1 The number of votes for candidate 1
    /// @notice _NumVotesForCandidate2 The number of votes for candidate 2
    IERC20   public requiredToken;
    uint256 public requiredBalance;
    uint256 public gracePeriod;
    uint256 public votingEndTime;
    uint256 public refundStartTime;
    bool public votingFinalized;
    uint256 public numVotesForCandidate1;
    uint256 public numVotesForCandidate2;

    /// @notice Modifier to check if a user is eligible to vote
    /// @dev Checks if the user has the required token balance
    modifier onlyEligible() {
        require(requiredToken.balanceOf(msg.sender) >= requiredBalance, "Insufficient token balance");
        _;
    }


    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public voterUSDCBalance; 

    

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Voted(address indexed voter, uint256 candidate);
    event VotingFinalized(uint256 winningCandidate);
    event Refunded(address indexed voter, uint256 amount);



        constructor()  ReentrancyGuardUpgradeable() {
            _disableInitializers(); 
        }



    function initialize(
        address _requiredToken,
        uint256 _requiredBalance,
        uint256 _gracePeriod
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        requiredToken = IERC20(_requiredToken);
        requiredBalance = _requiredBalance;
        gracePeriod = _gracePeriod;
        }



    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}


    /// @notice Allows the owner to change the required balance for voting eligibility
    /// @param _newBalance The new minimum token balance required to vote
    function setRequiredBalance(uint256 _newBalance) external onlyOwner {
        requiredBalance = _newBalance;
    }




    /// @notice Allows an eligible voter to cast their vote for one of the two candidates
    /// @param _candidateIndex The index of the candidate to vote for (0 or 1)
    /// @dev Checks eligibility and ensures each address can only vote once
    function vote(uint256 _candidateIndex) external onlyEligible {
        require(block.timestamp < votingEndTime, "Voting period ended");
        require(!hasVoted[msg.sender], "Already voted");
        require(_candidateIndex == 0 || _candidateIndex == 1, "Invalid candidate index");
        require(requiredToken.balanceOf(msg.sender) >= requiredBalance, "Insufficient USDC balance");


        if (_candidateIndex == 0) {
            numVotesForCandidate1++;
        } else {
            numVotesForCandidate2++;
        }

        hasVoted[msg.sender] = true;
        voterUSDCBalance[msg.sender] = requiredToken.balanceOf(msg.sender);
        emit Voted(msg.sender, _candidateIndex);
    }



    /// @notice Finalizes the voting process and starts the grace period
    /// @dev Can only be called by the contract owner after the voting period has ended
    function finalizeVoting() external onlyOwner {
        require(block.timestamp >= votingEndTime, "Voting period not ended");
        require(!votingFinalized, "Voting already finalized");

        uint256 winningCandidate = numVotesForCandidate1 > numVotesForCandidate2 ? 0 : 1;
        refundStartTime = block.timestamp + gracePeriod;
        votingFinalized = true;

        emit VotingFinalized(winningCandidate);
    }


    /// @notice Allows a voter to claim their USDC refund after the grace period
    /// @dev Transfers the voter's original USDC balance back to them
    function claimRefund() external nonReentrant {

        // Checks
        require(votingFinalized, "Voting not finalized");
        require(block.timestamp >= refundStartTime, "Refund period not started");
        require(hasVoted[msg.sender], "Did not vote");
        require(voterUSDCBalance[msg.sender] > 0, "Already refunded");

        /// @dev ensure the refund recipient is not the zero address 
        if (msg.sender == address(0)) {
            revert("Refund recipient cannot be the zero address");
        }

        /// @dev ensure the refund recipient is not the owner address (deployer of the contract)
        if (msg.sender == owner()) {
            revert("Refund recipient cannot be the owner address");
        }

        uint256 refundAmount = voterUSDCBalance[msg.sender];

        // Effects
        voterUSDCBalance[msg.sender] = 0;

        // Interactions 
        require(requiredToken.transfer(msg.sender, refundAmount), "Refund transfer failed");


        emit Refunded(msg.sender, refundAmount);
    }

    /// @dev This function is used to authorize an upgrade and is required to be performed by the owner of the contract only 
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Retrieves the current voting results for both candidates
    /// @return The number of votes for candidate 1 and candidate 2
    function getVotingResults() external view returns (uint256, uint256) {
        return (numVotesForCandidate1, numVotesForCandidate2);
    }
}