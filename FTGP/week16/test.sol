// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Foo {
    uint public num;

    function bar(uint n) public {
        num = n;
    } 
}