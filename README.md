<img height="120" align="left" src="https://github.com/ExWeb3/elixir_ethers/raw/main/assets/ethers_logo.png" alt="Ethers Elixir">

# About this fork flow

* Use `main` branch to sync with upstream changes
* Use `dev` branch to merge local quick fixes and upstream changes

# Elixir Ethers

[![example workflow](https://github.com/ExWeb3/elixir_ethers/actions/workflows/elixir.yml/badge.svg)](https://github.com/ExWeb3/elixir_ethers)
[![Coverage Status](https://coveralls.io/repos/github/ExWeb3/elixir_ethers/badge.svg?branch=main)](https://coveralls.io/github/ExWeb3/elixir_ethers?branch=main)
[![Module Version](https://img.shields.io/hexpm/v/ethers.svg)](https://hex.pm/packages/ethers)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ethers/)
[![License](https://img.shields.io/hexpm/l/ethers.svg)](https://github.com/ExWeb3/elixir_ethers/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/ExWeb3/elixir_ethers.svg)](https://github.com/ExWeb3/elixir_ethers/commits/main)

Ethers is a comprehensive Web3 library for interacting with smart contracts on the Ethereum (Or any EVM based blockchain) using Elixir.

Inspired by [ethers.js](https://github.com/ethers-io/ethers.js/) and [web3.js](https://web3js.readthedocs.io/), Ethers leverages
Elixir's amazing meta-programming capabilities to generate Elixir modules for give smart contracts from their ABI.
It also generates beautiful documentation for those modules which can further help developers.

## Installation

You can install the package by adding `ethers` (and optionally `ex_secp256k1`) to the list of
dependencies in your `mix.exs` file:

```elixir
def deps do
  [
    {:ethers, "~> 0.6.3"},
    # Uncomment next line if you want to use local signers
    # {:ex_secp256k1, "~> 0.7.2"}
  ]
end
```

The complete documentation is available on [hexdocs](https://hexdocs.pm/ethers).

### Upgrading to `0.6.x`

Version 0.6.x introduces some breaking changes to improve type safety and explicitness:

- All inputs to functions now require native Elixir types (e.g. integers) instead of hex strings
- Gas limits must be set explicitly rather than estimated automatically for all calls
- Transaction struct has been split into separate EIP-1559 and Legacy types
- Some functions have been deprecated or moved - see below

Key function changes:

- Use `Ethers.send_transaction/2` instead of `Ethers.send/2`
- Use `Ethers.Transaction.from_rpc_map/1` instead of `from_map/1`
- Specify gas limits explicitly instead of using `maybe_add_gas_limit/2`
- Use `type` instead of `tx_type` in transaction overrides, with explicit struct modules:

  ```elixir
  # Before
  Ethers.send_transaction(tx, tx_type: :eip1559)

  # After
  Ethers.send_transaction(tx, type: Ethers.Transaction.Eip1559)
  ```

Most existing code should continue to work with minimal changes. The main adjustments needed are:

1. Setting explicit gas limits
2. Using native types for inputs
3. Updating any direct transaction struct usage to the new types

## Configuration

To use Elixir Ethers, ensure you have a configured JSON-RPC endpoint.
Configure the endpoint using the following configuration parameter.

```elixir
# config.exs
config :ethers,
  rpc_client: Ethereumex.HttpClient, # Defaults to: Ethereumex.HttpClient
  keccak_module: ExKeccak, # Defaults to: ExKeccak
  json_module: Jason, # Defaults to: Jason
  secp256k1_module: ExSecp256k1, # Defaults to: ExSecp256k1
  default_signer: nil, # Defaults to: nil, see Ethers.Signer for more info
  default_signer_opts: [], # Defaults to: []
  default_gas_margin: 11000, # Precision is 0.01% (11000 = 110%)
  default_max_fee_per_gas_margin: 12000 #Precision is 0.01% (12000 = 120%)

# If using Ethereumex, you can specify a default JSON-RPC server url here for all requests.
config :ethereumex, url: "[URL_HERE]"
```

You can use one of the RPC URLs for your chain/wallet of choice or try out one of them from
[chainlist.org](https://chainlist.org/).

For more configuration options, refer to
[ethereumex](https://github.com/mana-ethereum/ethereumex#configuration).

To send transactions, you need a wallet client capable of signing transactions and exposing a
JSON-RPC endpoint.

## Usage

To use Elixir Ethers, you must have your contract's ABI in json format, which can be obtained from
[etherscan.io](https://etherscan.io). This library also contains standard contract interfaces such
as `ERC20`, `ERC721` and some more by default (refer to built-in contracts in
[hexdocs](https://hexdocs.pm/ethers)).

Create a module for your contract as follows:

```elixir
defmodule MyERC20Token do
  use Ethers.Contract,
    abi_file: "path/to/abi.json",
    default_address: "[Contract address here (optional)]"

  # You can also add more code here in this module if you wish
end
```

### Calling contract functions

After defining the module, all the functions can be called like any other Elixir module.

To fetch the results (return value(s)) of a function you can pass your function result to the
[`Ethers.call/2`](https://hexdocs.pm/ethers/Ethers.html#call/2) function.

```elixir
# Calling functions on the blockchain
iex> MyERC20Token.balance_of("0x[Address]") |> Ethers.call()
{:ok, 654294510138460920346}
```

Refer to [Ethers.call/2](https://hexdocs.pm/ethers/Ethers.html#call/2) for more information.

### Sending transaction

To send transaction (eth_sendTransaction) to the blockchain, you can use the
[`Ethers.send_transaction/2`](https://hexdocs.pm/ethers/Ethers.html#send_transaction/2) function.

Ensure that you specify a `from` option to inform your client which account to use as the signer:

```elixir
iex> MyERC20Token.transfer("0x[Recipient]", 1000) |> Ethers.send_transaction(from: "0x[Sender]")
{:ok, "0xf313ff7ff54c6db80ad44c3ad58f72ff0fea7ce88e5e9304991ebd35a6e76000"}
```

Refer to [Ethers.send_transaction/2](https://hexdocs.pm/ethers/Ethers.html#send_transaction/2) for more information.

### Getting Logs (Events)

Ethers provides functionality for creating event filters and fetching related events from the
blockchain. Each contract generated by Ethers also will have `EventFilters` module
(e.g. `MyERC20Token.EventFilters`) that can be used to create filters for events.

To create an event filter and then use
[`Ethers.get_logs/2`](https://hexdocs.pm/ethers/Ethers.html#get_logs/2) function like the below
example.

```elixir
# Create The Event Filter
# (`nil` can be used for a parameter in EventFilters functions to indicate no filtering)
iex> filter = MyERC20Token.EventFilters.transfer("0x[From Address Here]", nil)

# Then you can simply list the logs using `Ethers.get_logs/2`

iex> Ethers.get_logs(filter)
{:ok,
 [
   %Ethers.Event{
     address: "0x5883c66ca442461d406f330775d42954bfcf7d92",
     block_hash: "0x83de67fd285067b838790406ea68f21a3afbc0ade534047725b5ccfb904c9ed3",
     block_number: 17077047,
     topics: ["Transfer(address,address,uint256)",
      "0x6b75d8af000000e20b7a7ddf000ba900b4009a80",
      "0x230507f6a391ae5ac0ec124f1c5b8ce454fe3f3d"],
     topics_raw: ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
      "0x0000000000000000000000006b75d8af000000e20b7a7ddf000ba900b4009a80",
      "0x000000000000000000000000230507f6a391ae5ac0ec124f1c5b8ce454fe3f3d"],
     transaction_hash: "0xaa6fb2e1bbb27f667e76b03e8cde23db694207e06b9aa810d4c20c1f109a58e5",
     transaction_index: 0,
     data: [761112156078097834180608],
     log_index: 0,
     removed: false
   },
   %Ethers.Event{...},
    ...
 ]}
```

### Resolving Ethereum names (ENS domains) using Ethers

To resolve ENS or any other name service provider (which are ENS compatible) in the blockchain
you can simply use [`Ethers.NameService`](https://hexdocs.pm/ethers/Ethers.NameService.html) module.

```elixir
iex> Ethers.NameService.resolve("vitalik.eth")
{:ok, "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"}
```

### Built-in contract interfaces in Ethers

Ethers already includes some of the well-known contract interface standards for you to use.
Here is a list of them.

- [ERC20](https://hexdocs.pm/ethers/Ethers.Contracts.ERC20.html) - The well know fungible token standard
- [ERC165](https://hexdocs.pm/ethers/Ethers.Contracts.ERC165.html) - Standard Interface detection
- [ERC721](https://hexdocs.pm/ethers/Ethers.Contracts.ERC721.html) - Non-Fungible tokens (NFTs) standard
- [ERC777](https://hexdocs.pm/ethers/Ethers.Contracts.ERC777.html) - Improved fungible token standard
- [ERC1155](https://hexdocs.pm/ethers/Ethers.Contracts.ERC1155.html) - Multi-Token standard (Fungible, Non-Fungible or Semi-Fungible)
- [Multicall](https://hexdocs.pm/ethers/Ethers.Multicall.html) - [Multicall3](https://www.multicall3.com/)

To use them you just need to specify the target contract address (`:to` option) of your token and
call the functions. Example:

```elixir
iex> tx_data = Ethers.Contracts.ERC20.balance_of("0x[Holder Address]")
#Ethers.TxData<
  function balanceOf(
    address _owner "0x[Holder Address]"
  ) view returns (
    uint256 balance
  )
>

iex> Ethers.call(tx_data, to: "0x[Token Address]")
{:ok, 123456}
```

## Documentation

For a detailed documentation visit [Ethers hexdocs page](https://hexdocs.pm/ethers).

### Generated documentation for functions and event filters

Ethers generates documentation for all the functions and event filters based on the ABI data.
To get the documentation you can either use the `h/1` IEx helper function or generate HTML/epub
docs using ExDoc.

#### Get the documentation of a contract function

```elixir
iex(3)> h MyERC20Token.balance_of

                             def balance_of(owner)

  @spec balance_of(Ethers.Types.t_address()) :: Ethers.TxData.t()

Prepares balanceOf(address _owner) call parameters on the contract.

This function should only be called for result and never in a transaction on
its own. (Use Ethers.call/2)

State mutability: view

## Function Parameter Types

  • _owner: `:address`

## Return Types (when called with `Ethers.call/2`)

  • balance: {:uint, 256}
```

#### Inspecting TxData and EventFilter structs

One cool and potentially useful feature of Ethers is how you can inspect the call

#### Get the documentation of a event filter

```elixir
iex(4)> h MyERC20Token.EventFilters.transfer

                             def transfer(from, to)

  @spec transfer(Ethers.Types.t_address(), Ethers.Types.t_address()) ::
          Ethers.EventFilter.t()

Create event filter for Transfer(address from, address to, uint256 value)

For each indexed parameter you can either pass in the value you want to filter
or nil if you don't want to filter.

## Parameter Types (Event indexed topics)

  • from: :address
  • to: :address

## Event `data` Types (when called with `Ethers.get_logs/2`)

These are non-indexed topics (often referred to as data) of the event log.

  • value: {:uint, 256}
```

## Signing Transactions

By default, Ethers will rely on the default blockchain endpoint to handle the signing (using `eth_sendTransaction` RPC function). Obviously public endpoints cannot help you with signing the transactions since they do not hold your private keys.

To sign transactions on Ethers, You can specify a `signer` module when sending/signing transactions. A signer module is a module which implements the [Ethers.Signer](lib/ethers/signer.ex) behaviour.

Ethers has these built-in signers to use:

- `Ethers.Signer.Local`: A local signer which loads a private key from `signer_opts` and signs the transactions.
- `Ethers.Signer.JsonRPC`: Uses `eth_signTransaction` Json RPC function to sign transactions. (Using services like [Consensys/web3signer](https://github.com/Consensys/web3signer) or [geth](https://geth.ethereum.org/))

For more information on signers, visit [hexdocs](https://hexdocs.pm/ethers/Ethers.Signer.html).

### Example

```elixir
MyERC20Token.transfer("0x[Recipient]", 1000)
|> Ethers.send_transaction(
  from: "0x[Sender]",
  signer: Ethers.Signer.Local,
  signer_opts: [private_key: "0x..."]
)
```

## Switching the ex_keccak library

`ex_keccak` is a Rustler NIF that brings keccak256 hashing to elixir.
It is the default used library in `ex_abi` and `ethers`. If for some reason you need to use a
different library (e.g. target does not support rustler) you can use the Application config value
and on top of that set the environment variable `SKIP_EX_KECCAK=true` so ex_keccak is marked as
optional in hex dependencies.

```elixir
# config.exs
config :ethers, keccak_module: MyKeccakModule

# Also make sure to set SKIP_EX_KECCAK=true when fetching dependencies and building them
```

## Contributing

All contributions are very welcome (as simple as fixing typos). Please feel free to open issues and
push Pull Requests. Just remember to be respectful to everyone!

To run the tests locally, follow below steps:

- Install [ethereum](https://geth.ethereum.org/docs/getting-started/installing-geth) and [solc](https://docs.soliditylang.org/en/latest/installing-solidity.html). For example, on MacOS

```
brew install ethereum
npm install -g solc
```

- Run [anvil (from foundry)](https://book.getfoundry.sh/getting-started/installation).
  After installing anvil, just run the following in a new window

```
> anvil
```

Then you should be able to run tests through `mix test`.

## Acknowledgements

Ethers was possible to make thanks to the great contributors of the following libraries.

- [ABI](https://github.com/poanetwork/ex_abi)
- [Ethereumex](https://github.com/mana-ethereum/ethereumex)
- [ExKeccak](https://github.com/tzumby/ex_keccak)

And also all the people who contributed to this project in any ways.

## License

[Apache License 2.0](https://github.com/ExWeb3/elixir_ethers/blob/main/LICENSE)
