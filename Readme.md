# Delm Compiler
Delm-compiler is an **experimental** project trying to compile Elm to Solidity.

_Delm aka Decentralized Elm._

## Motivation

Both elm and solidity are amazing projects that are solving different problems.
* Elm enables developers to write safe code _for reliable webapps_;
* Solidity enables developers to write Smart Contracts _which governs the behaviour of accounts within the Ethereum state_.

Delm tries to leverage the best of both worlds.

`Type safe code in the blockchain`

* Elm-like architecture, to manage blockchain states;
* Elm type-inference to minimize (remove?) runtime errors;
* Leverage Elm and Solidity ecosystems, where possible;
* Solidity security and tooling;
* Elm debugging.

<!-- ## Installation

#### Installation - Linux, Mac OS

(Linux) Get the binary
```
> curl -L -o delm-interpreter.gz https://github.com/sellooh/delm-compiler/raw/master/bin/v0.0.1-alpha.1/delm-interpreter-x86_64-unknown-linux-gnu.gz
```

or (Mac M1) Get the binary
```
> curl -L -o delm-interpreter.gz https://github.com/sellooh/delm-compiler/raw/master/bin/v0.0.1-alpha.1/delm-interpreter-aarch64-apple-darwin.gz
```

or (Mac Intel) Get the binary.
```
> curl -L -o delm-interpreter.gz https://github.com/sellooh/delm-compiler/raw/master/bin/v0.0.1-alpha.1/delm-interpreter-x86_64-apple-darwin.gz
```

Extract:
```
> gunzip delm-interpreter.gz
```

Give It execution permissions.
```
> chmod +x delm-interpreter
```

Move to some place on your path.
```
> sudo mv delm-interpreter /usr/local/bin/
```

#### Download - Windows executable

Windows [download](https://github.com/sellooh/delm-compiler/raw/master/bin/v0.0.1-alpha.1/delm-interpreter-x86_64-pc-windows-msvc.exe.zip).

## Usage

Initialize the project.
```
> cd ~/Documents && mkdir my-project && cd my-project

> delm-interpreter init
```

Copy the [ERC20.elm](#examples) example. Paste It into src/ERC20.elm.
```
> mkdir src && touch src/ERC20.elm
```

Run.
```
> elm-interpreter run ERC20.elm
```

Visit http://localhost:8000/index.html
The interpreter will watch changes made to your contract. Refresh to see updates. -->

## Examples

src/ERC20.elm
```elm
module ERC20.ERC20 exposing (..)

import Concept.Contract
    exposing
        ( Basic(..)
        , Contract
        , FunctionIO(..)
        , Interface(..)
        , InterfaceIO(..)
        , deploy
        )
import Concept.Core exposing (Address, Global, Requirements, throw, zeroAddress)
import Concept.DefaultValues as Default
import Concept.Mapping as Mapping exposing (Mapping(..))


main : Program () Model Msg
main =
    deploy <|
        Contract ( constructor, ITuple3 ( IString, IString, IInt ) )
            update


type alias Model =
    { balances : Mapping Address Int
    , allowances : Mapping Address (Mapping Address Int)
    , totalSupply : Int
    , name : String
    , symbol : String
    , decimals : Int
    }


constructor : Global -> FunctionIO -> Model
constructor global params =
    let
        ( name, symbol, totalSupply ) =
            case params of
                Tuple3 ( RString n, RString s, RInt ts ) ->
                    ( n, s, ts )

                _ ->
                    throw ("Oops. Invalid parameters.")
    in
    { balances = Mapping.insert global.msg.sender totalSupply (Mapping.empty Default.int)
    , allowances = Mapping.empty (Mapping.empty Default.int)
    , totalSupply = totalSupply
    , name = name
    , symbol = symbol
    , decimals = 18
    }


type Msg
    = BalanceOf Address
    | Transfer Address Int
    | GetAllowance Address Address
    | Approve Address Int
    | TransferFrom Address Address Int
    | Name
    | Symbol
    | Decimals
    | TotalSupply


update : Msg -> Global -> Model -> ( Requirements, Model, FunctionIO )
update msg global model =
    case msg of
        BalanceOf address ->
            let
                balance =
                    Mapping.get address model.balances
            in
            ( []
            , model
            , Single <| RInt balance
            )

        Transfer address amount ->
            let
                senderBalance =
                    Mapping.get global.msg.sender model.balances

                updatedBalances =
                    Mapping.insert global.msg.sender (senderBalance - amount) model.balances

                recipientBalance =
                    Mapping.get address updatedBalances
            in
            ( [ ( global.msg.sender /= zeroAddress, "ERC20: transfer from the zero address" )
              , ( address /= zeroAddress, "ERC20: transfer to the zero address" )
              , ( senderBalance >= amount, "ERC20: transfer amount exceeds balance" )
              , ( amount > 0, "ERC20: amount should be positive" )
              ]
            , { model
                | balances =
                    Mapping.insert address
                        (recipientBalance + amount)
                        updatedBalances
              }
            , Single <| RBool True
            )

        GetAllowance owner spender ->
            let
                allowancesMapping =
                    Mapping.get owner model.allowances

                allowedBalance =
                    Mapping.get spender allowancesMapping
            in
            ( [], model, Single (RInt allowedBalance) )

        Approve spender amount ->
            let
                allowancesMapping =
                    Mapping.get global.msg.sender model.allowances

                allowances =
                    Mapping.insert global.msg.sender
                        (Mapping.insert spender amount allowancesMapping)
                        model.allowances
            in
            ( [ ( global.msg.sender /= zeroAddress, "ERC20: approve from the zero address" )
              , ( spender /= zeroAddress, "ERC20: approve to the zero address" )
              ]
            , { model | allowances = allowances }
            , Single <|
                RBool True
            )

        TransferFrom sender recipient amount ->
            let
                senderBalance =
                    Mapping.get sender model.balances

                updatedBalance =
                    Mapping.insert sender (senderBalance - amount) model.balances

                recipientBalance =
                    Mapping.get recipient updatedBalance

                allowancesMapping =
                    Mapping.get sender model.allowances

                allowedBalance =
                    Mapping.get global.msg.sender allowancesMapping

                allowances =
                    Mapping.insert sender
                        (Mapping.insert global.msg.sender (allowedBalance - amount) allowancesMapping)
                        model.allowances
            in
            ( [ ( sender /= zeroAddress, "ERC20: transfer from the zero address" )
              , ( recipient /= zeroAddress, "ERC20: transfer to the zero address" )
              , ( senderBalance >= amount, "ERC20: transfer amount exceeds balance" )
              , ( allowedBalance >= amount, "ERC20: transfer amount exceeds allowance" )
              , ( amount > 0, "ERC20: amount should be positive" )
              ]
            , { model
                | allowances = allowances
                , balances =
                    Mapping.insert recipient
                        (recipientBalance + amount)
                        updatedBalance
              }
            , Single <|
                RBool True
            )

        Name ->
            ( [], model, Single <| RString model.name )

        Symbol ->
            ( [], model, Single <| RString model.symbol )

        Decimals ->
            ( [], model, Single <| RInt model.decimals )

        TotalSupply ->
            ( [], model, Single <| RInt model.totalSupply )
```

## Roadmap

This isn't a set in stone roadmap, but as of right now a path the project could take:

* Phase 0 **(current)**: Develop the Delm Interpreter. This will allow developers to experience the creation of Smart Contracts in Delm. The Interpreter will feature a web playground similar to Remix where developers can test how a Delm Smart Contract behaves.

* Phase 1: Develop the Delm Compiler. This will enable developers to generate .sol files from their .elm source code. They should be deployable-ready to any Ethereum or Ethereum-like network. Preferably they are easily readable by humans.

* Beyond: Security. Ecosystem. Community. Bytecode generation. Having Phase 1 completed the project can take many directions. As of today **the goal is**: Provide a good experience to developers looking to write reliable, secure and predictable Smart Contracts to Ethereum-compatible networks.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
