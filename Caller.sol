// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;

interface CalleeInterface {
    function start() external;
    function cancel() external;
}

contract Caller {
    function start(address addr) external {
        CalleeInterface contr = CalleeInterface(addr);
        contr.start();
    }

    function cancel(address addr) external {
        CalleeInterface contr = CalleeInterface(addr);
        contr.cancel();
    }
}
