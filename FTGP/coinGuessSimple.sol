// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Key concepts introduced:
// - Function Visibility Specifiers (external) 
//   https://docs.soliditylang.org/en/latest/cheatsheet.html?highlight=visibility#function-visibility-specifiers
// - Function modifiers (payable, external, pure)
//   https://docs.soliditylang.org/en/latest/cheatsheet.html?highlight=modifiers#modifiers
// - off chain function calls (calls vs transactions)
//   https://ethereum.stackexchange.com/questions/765/what-is-the-difference-between-a-transaction-and-a-call
// - using cryptographic hash for commitments
//   https://crypto.stackexchange.com/questions/6790/commitment-scheme-using-hash-functions

// contract for coinfip (or guess) that uses the first contract
contract CoinFlip {

    // player address variables - set player addressees to zero
    address payable player1 = payable(0x0);
    address payable player2 = payable(0x0);

    // player selection variables
    bytes32 p1selection;
    bool p2selection;

    // bet and expiration variables
    uint256 public bet;
    uint256 public expiration = 2**256-1; // set to max

    // get the hash only using solidity - Warning: don't run this on-chain as your choice will be visible!
    // this is using the "pure" modifier as it doesn't read or write to storage
    function getHash(bool choice, uint256 nonce) external pure returns (bytes32) {
        return keccak256(abi.encode(choice, nonce));
    }

    // player1 sets choice by giving a hash (hash = H(choice + nonce))
    function makeBet(bytes32 hash) external payable {
        // check if the player has already played (i.e. address not zero)
        require(player1 == payable(0x0));
        // check if bet > 0
        require(msg.value > 0);

        // get address of player 1
        player1 = payable(msg.sender);
        // save player1 selection
        p1selection = hash;
        // store the bet amount
        bet = msg.value;
    }

    // player2 sets choice
    function takeBet(bool choice) external payable {
        // check if the player has already played (i.e. address not zero)
        require(player2 == payable(0x0));
        // check if player 1 made their choise
        require(player1 != payable(0x0));
        // check if the bet is same as player 1
        require(msg.value == bet);

        // save address of player 2
        player2 = payable(msg.sender);
        // save player 2 choice
        p2selection = choice;
        // set expiration date
        expiration = block.timestamp + 24 hours;
    }

    // find out who won, player1 provides choice(0/1) and nonce(32 byte unsigned int) that match stored hash
    // note that the address of player doesn't need to be checked here, as only player should know the correct nonce
    function reveal(bool choice, uint256 nonce) external {
        // check if H(choice + nonce) is equal to stored hash
        require(keccak256(abi.encode(choice, nonce)) == p1selection);
        // check if second player played
        require(player2 != payable(0x0));
        // check if the bet hasn't expired
        require(block.timestamp < expiration);

        // players made the same choice => 2 wins
        if (p2selection == choice) {
            // player2 gets ether
            player2.transfer(address(this).balance);
        }
        // players made different choices => 1 wins
        else {
            // player1 gets ether
            player1.transfer(address(this).balance);
        }

        // reset values
        bet = 0;
        player1 = payable(0x0);
        player2 = payable(0x0);
        expiration = 2**256-1;
    }

    // player 1 can cancel bet if player2 hasn't played yet
    function cancel() external {
        // check if it is player1
        require(msg.sender == player1);
        // check if player2 hasn't played yet
        require(player2 == payable(0x0));

        // player1 gets bet back
        player1.transfer(address(this).balance);

        // reset values
        bet = 0;
        player1 = payable(0x0);
        expiration = 2**256-1;
    }

    // if player1 doesn't reveal their choice before the bet expires, palyer2 can timeout and win
    function timeout() external {
        // check if it has expired
        require(block.timestamp >= expiration);

        // player2 gets both bets
        player2.transfer(address(this).balance);

        // reset values
        bet = 0;
        player1 = payable(0x0);
        player2 = payable(0x0);
        expiration = 2**256-1;
    }
}