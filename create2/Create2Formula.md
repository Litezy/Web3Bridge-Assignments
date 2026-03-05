# CREATE2 Deterministic Address Algorithm

## The Formula
```
address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(initCode))[12:]
```

---

## Step 1 — Get the Bytecode
```
- Compile your contract
- Copy the creation bytecode (the full one, not runtime bytecode)
- In Foundry:  forge build → out/Contract.sol/Contract.json → bytecode.object
- In Hardhat:  artifacts/contracts/Contract.sol/Contract.json → bytecode
```

## Step 2 — Encode Constructor Arguments
```
- ABI encode your constructor arguments
- abi.encode(arg1, arg2, ...)
- In JS: ethers.AbiCoder.defaultAbiCoder().encode(["uint256"], [value])
- Result is a hex string — strip the leading "0x" before appending
- If no constructor args, skip this step entirely
```

## Step 3 — Build initCode
```
initCode = bytecode + encodedArgs (without 0x prefix)

- This is exactly what the EVM receives when deploying
- If no constructor args, initCode = bytecode alone
```

## Step 4 — Hash the initCode
```
initCodeHash = keccak256(initCode)

- In JS: ethers.keccak256(initCode)
- This represents the contract you want to deploy
- Same contract = same initCodeHash always
```

## Step 5 — Compute the Salt
```
- Salt is any bytes32 value you choose
- Can be a plain string:      keccak256(toUtf8Bytes("mySalt"))
- Can be a number:            keccak256(solidityPacked(["uint256"], [BigInt(num)]))
- Can be token addresses:     keccak256(solidityPacked(["address", "address"], [token0, token1]))
- The salt is what makes the address unique per deployment
- Same salt + same bytecode + same factory = same address every time
```

## Step 6 — Compute the Final Address
```
- Pass factory, salt, initCodeHash into getCreate2Address
- In JS: ethers.getCreate2Address(factoryAddress, salt, initCodeHash)
- Internally it does:
    packed  = 0xff ++ factoryAddress ++ salt ++ initCodeHash
    hashed  = keccak256(packed)
    address = last 20 bytes of hashed  (slice off first 12 bytes)
```

---

## Full Algorithm in Pseudocode
```
1. bytecode      = compiled contract creation bytecode
2. encodedArgs   = abi.encode(constructorArg1, constructorArg2, ...)
3. initCode      = bytecode + encodedArgs.slice(2)
4. initCodeHash  = keccak256(initCode)
5. salt          = keccak256(pack(yourChosenValue))
6. address       = keccak256(0xff ++ factory ++ salt ++ initCodeHash)[12:]
```

---

## Full Implementation in JavaScript
```javascript
const { ethers } = require("ethers");

const bytecode       = "0x...";                          // compiled bytecode
const factoryAddress = "0x...";                          // factory contract address
const constructorArg = 123456;                           // constructor argument

const salt = ethers.keccak256(
  ethers.solidityPacked(["uint256"], [BigInt(constructorArg)])
);

const initCode = bytecode + ethers.AbiCoder.defaultAbiCoder()
  .encode(["uint256"], [BigInt(constructorArg)])
  .slice(2);

const initCodeHash   = ethers.keccak256(initCode);
const predictedAddress = ethers.getCreate2Address(factoryAddress, salt, initCodeHash);

console.log("constructorArg:    ", constructorArg);
console.log("salt:              ", salt);
console.log("initCodeHash:      ", initCodeHash);
console.log("predictedAddress:  ", predictedAddress);
```

---

## Rules to Remember
```
✅ Same factory + same salt + same bytecode = ALWAYS same address
✅ Change any one of them = completely different address
✅ You can predict the address BEFORE deploying
✅ If no constructor args, skip step 2 and initCode = bytecode only
✅ Salt must be bytes32 — always hash your value to get bytes32
✅ Strip "0x" from encodedArgs before appending to bytecode
✅ Use keccak256 on initCode, NOT on bytecode alone
```

---

## What Changes the Address

| Input            | Effect                                      |
|------------------|---------------------------------------------|
| Factory address  | Deploy from different factory = different address |
| Salt             | Change your input value = different address |
| Bytecode         | Change contract code = different address    |
| Constructor args | Part of initCode = affects initCodeHash     |

---

## Why 0xff Prefix?
```
- Regular CREATE generates addresses using: keccak256(rlp(deployer, nonce))
- 0xff is an invalid RLP prefix
- This guarantees CREATE and CREATE2 can NEVER produce the same address
- Zero collision possibility between the two schemes
```

---

## Real World Usage — Uniswap V2
```
Uniswap uses CREATE2 to deploy pair contracts deterministically:

salt         = keccak256(token0 ++ token1)   // sorted token addresses
initCodeHash = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f

This means:
- Any USDC/WETH pair will ALWAYS deploy to the same address
- No need to store pair addresses on chain
- Anyone can compute the pair address off chain just from the two token addresses
```