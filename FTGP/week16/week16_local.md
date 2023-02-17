# Local Environment Set-up:

We have been using Remix so far, which is ideal for early development, but we reached a point where it might be better to compile and run our smart contracts locally. In the following sections, we will see a way to do this using Pyhton and a library called Web3.py. This is a low-level way to achieve this and by far not the only way to do it. If you are interested in a Python framework to automate some of the things we will see, then you can check Brownie (https://eth-brownie.readthedocs.io/en/stable/).

***Note:*** The following instructions were tested and work on a computer that runs linux (Ubuntu 20.04). The following instructions should also work on different linux distributions, macOS and Windows, but have not been tested. If you are using Windows, it might be better for you to work in WSL2 (https://learn.microsoft.com/en-us/windows/wsl/install). **It is not the responsibility of the teaching staff to debug issues related to your computer's configuration**, and so we might be unavailable to help with such issues.

## Solidity Compiler:

The first thing we need is a Solidity compiler. This compiler takes our source code and produces instructions that can run on the EVM.

1. Install the solidity compiler by running in your terminal:
    ```
    pip install py-solc-x
    ```
2. Install the latest version of Solidity. Run the following in python:
    ```
    import solcx

    solcx.install_solc(version="latest") # you can also install different versions

    print(solcx.get_installed_solc_versions())
    ```
    This should print [Version('0.8.17')] or something similar if everything went okay.

## Compile contract files:

Now that we have a Solidity compiler installed, we can compile our smart contracts locally using python. The following two functions should do the job:

```
from solcx import compile_files

def compile_sol(file_path):
    
    c = compile_files([file_path], output_values=["abi", "bin"])

    return list(c.values())[0]

def compile_sol_to_file(file_path, output_file_path):

    c = compile_sol(file_path)

    with open(output_file_path, "w") as f:
        f.write(str(c))
```

The first  that takes in the name (or path) to a smart contract (.sol file), compiles it and produces the ABI and the bytecode. The second does the same, but also takes as input an output file and outputs the ABI and bytecode to that file. Feel free to use these or implement your own for you projects.

## Blockchain:

Remix provides us with a local blockchain simulator that we can use to test our smart contracts. We need to do something similar locally. The easiest approach, is to use a test provider. We can install this test provider along with the web3 library using pip:

    pip install web3[tester]

Using a test provider is perfect for learning and early prototyping, but if for more complicated things an Ethereum simulator such as Ganache is more suitable. The following section contains instructions for installing Ganache. As it might take a while, you don't have to do this now, but make sure to install Ganache after you are done with the rest of this week's lab.

<details>
<summary> Ganache </summary>

---

Before we can install Ganache, we need to install Node.js. To check if you have Node.js installed, you can type in your terminal:

    node -v

If this returns a version (e.g. v16.14.0) then you are alright, otherwise install Node.js using the instructions on their website: https://nodejs.org/en/

Node.js should come with npm (Node Package Manager). Make sure that npm is installed, by typing in your terminal:

    npm -v

Now we can use npm to install Ganache. To do this, run the following command in your terminal:

    npm install ganache --global

You should now be able to run Ganache by typing:
    
    ganache

If everything worked, your terminal window should look something like this:

    ganache v7.7.2 (@ganache/cli: 0.8.1, @ganache/core: 0.8.1)
    Starting RPC server

    Available Accounts
    ==================
    (0) 0xaFAcfebd00Cce9B9CfF187159acfc6E57D589469 (1000 ETH)
    (1) 0x4f772Cd7C23a69c32Df7F1B061aea8375C8C56be (1000 ETH)
        ...
    RPC Listening on 127.0.0.1:8545

Make sure that you keep this terminal window open when testing your smart contracts as it simulates the blockchain.

---

</details>

Finally, the most realistic way to test and interact with smart contracts (apart from running them on an actual blockchain) is to use a testnet. To do this, you can either run a full testnet node or use a remote provider service like Infura (https://www.infura.io/). We won't go into detail about testnets now, but don't worry we will work with one in the future. Saying that, if you are looking for more details, check this article: https://medium.com/coinmonks/web3-py-from-ganache-to-infura-3c16aadb0a0

## Web3 library:

Now that we have a local blockchain, we need a way to interact with it. This is where the Web3.py library (which we have already installed) comes in!

We first need to instantiate it:

    w3 = Web3(EthereumTesterProvider())

<details>
<summary> Ganache </summary>

---

If you are using Ganache, you can do the same using:

    w3 = Web3(HTTPProvider("http://127.0.0.1:8545"))

You will also need to specify a "from" address on every transaction, or set a default account using:

    w3.eth.default_account = w3.eth.accounts[0]

---

</details>

To check if this worked:

    print(w3.isConnected())

## Smart Contract Development:

Okay now that we have everything working, we can start working with smart contracts locally. We will use the following simple smart contract as an example:

    // SPDX-License-Identifier: GPL-3.0

    pragma solidity >=0.7.0 <0.9.0;

    contract Foo {
        uint public num;

        function bar(uint n) public {
            num = n;
        } 
    }

### Deploying a smart contract:

To deploy a smart contact, we need to first get the contract ABI and bytecode from the compiled data, then we can instantiate a contract instance and then deploy that contract by calling its constructor function. This can be done with the following code:

    # compile contract
    compile = compile_files(["test.sol"], output_values=["abi", "bin"])
    abi = list(compile.values())[0]["abi"]
    bin = list(compile.values())[0]["bin"]

    # instantiate contract
    Foo = w3.eth.contract(abi=abi, bytecode=bin)

    # deploy contract
    tx_hash = Foo.constructor().transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    deployedFoo = w3.eth.contract(address=tx_receipt.contractAddress, abi=abi)

### Interacting with a smart contract:

We have two ways to interact with a smart contract, one is by sending transactions and the other is by contract "calls". The difference between the two is that transactions change the state of the smart contract and thus need to be broadcasted to the network while calls only retrieve data from the blockchain (and don't have any effects) and thus only need to be performed locally (by the node we are connected to). The following code showcases both:

    # transact with contract function
    tx_hash = deployedFoo.functions.bar(10).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    # check contract state
    num = deployedFoo.functions.num().call()
    print(num)

## Conclusion:

Hopefully, the above sections will allow you to build a local testing environment for smart contract development. This will allow you to build and test smart contracts without having to rely on a third party service such as Remix. However, this is just the tip of the iceberg for what web3.py can do. Thankfully the documentation (https://web3py.readthedocs.io/en/latest/index.html) is really good and should be used as a reference in your future work. 