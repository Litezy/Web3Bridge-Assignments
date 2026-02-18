```markdown
# Solidity Data Locations: Quick Guide

## Three Data Locations

| Location | Purpose | Cost | Persistence |
|----------|---------|------|-------------|
| **storage** | Permanent blockchain state | Most expensive | Forever |
| **memory** | Temporary (function scope) | Moderate | Cleared after function |
| **calldata** | Read-only external params | Cheapest | Function only |

---

## Structs

### State Variables (Always Storage)
```solidity
struct User { string name; uint256 balance; }

User public admin;  // ✅ storage (implicit)
admin.name = "Alice";  // Permanent
```

### Local Variables (Must Specify)
```solidity
User[] public users;

// Storage reference - modifies original
User storage user = users[0];
user.balance = 500;  // ✅ Saved to storage

// Memory copy - temporary
User memory temp = users[0];
temp.balance = 500;  // ❌ NOT saved
```

**Rule:** `storage` = reference (changes persist), `memory` = copy (changes lost)

---

## Arrays

### State Variables (Always Storage)
```solidity
uint256[] public numbers;  // ✅ storage (implicit)
numbers.push(10);  // Permanent
```

### Local Variables (Must Specify)
```solidity
// Storage reference
uint256[] storage nums = numbers;
nums[0] = 100;  // ✅ Saved

// Memory array
uint256[] memory temp = new uint256[](5);
temp[0] = 100;  // ❌ NOT saved
```

### Function Parameters
```solidity
// Memory - creates copy
function process(uint[] memory data) public { }

// Calldata - cheapest, read-only
function process(uint[] calldata data) external { }
```

---

## Mappings

### Always Storage (No Choice)
```solidity
mapping(address => uint256) public balances;  // ✅ storage (only option)

balances[msg.sender] = 100;  // Direct storage write

// ❌ Cannot do:
// mapping(...) memory temp;  // ERROR
// mapping(...) storage temp = balances;  // ERROR
// function f(mapping(...) m) { }  // ERROR
```

**Critical:** Mappings can ONLY exist in storage - no memory, no calldata, no parameters.

---

## Why Mappings Don't Need Keywords

**Technical reasons:**

1. **No key tracking** - Mapping doesn't know which keys exist
2. **Hash-based storage** - Uses `keccak256(key, slot)` - only works in storage
3. **No iteration** - Can't loop through keys
4. **No size** - Can't determine length

```solidity
mapping(address => uint256) balances;

// ❌ Impossible:
// balances.length;  // Doesn't exist
// for (key in balances) { }  // No such syntax
// uint[] memory copy = balances;  // Can't copy
```

**Memory would need:** key list, size, copy method → all impossible with mappings.

**Result:** Solidity makes mappings storage-only by design.

---

## Comparison Table

| Feature | Arrays | Mappings |
|---------|--------|----------|
| **Memory?** | ✅ Yes | ❌ No |
| **Calldata?** | ✅ Yes | ❌ No |
| **Has length?** | ✅ Yes | ❌ No |
| **Can iterate?** | ✅ Yes | ❌ No |
| **Keyword needed?** | ✅ Yes (locals) | ❌ No (always storage) |

---

## Quick Reference

```solidity
contract Example {
    // STATE VARIABLES (always storage, no keyword)
    struct User { string name; }
    User public admin;                    // storage
    User[] public users;                  // storage
    mapping(address => User) userMap;     // storage (only option)
    
    function examples() public {
        // STORAGE REFERENCES (modify original)
        User storage u = users[0];
        u.name = "Alice";  // ✅ Saved
        
        // MEMORY COPIES (temporary)
        User memory temp = users[0];
        temp.name = "Bob";  // ❌ NOT saved
        
        // MAPPINGS (direct access only)
        userMap[msg.sender] = User("Charlie");  // ✅ Saved
    }
    
    // CALLDATA (cheapest for external)
    function process(uint[] calldata data) external pure {
        return data[0];  // Read-only
    }
}
```

---

## Common Mistakes

```solidity
// ❌ Memory instead of storage
User memory user = users[0];
user.balance = 100;  // Changes NOT saved

// ✅ Storage reference
User storage user = users[0];
user.balance = 100;  // Changes saved

// ❌ Trying to use mapping in memory
mapping(address => uint) memory temp;  // ERROR!

// ✅ Direct mapping access
userBalances[msg.sender] = 100;  // Correct

// ❌ Memory for external functions
function f(uint[] memory data) external { }  // Wasteful

// ✅ Calldata for external functions
function f(uint[] calldata data) external { }  // Cheaper
```

---

## Key Takeaways

1. **State variables** → always storage (no keyword)
2. **Local structs/arrays** → must specify `storage` or `memory`
3. **Mappings** → always storage (no keyword, no choice)
4. **storage** = reference (permanent changes)
5. **memory** = copy (temporary changes)
6. **calldata** = cheapest (read-only, external only)

**Why mappings are special:** They can't track keys, have no size, can't iterate → impossible to copy to memory → storage-only by design.

---

*Remember: Mappings are ALWAYS storage. No exceptions, no keywords needed.*
```
