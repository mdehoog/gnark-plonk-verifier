# gnark-plonk-verifier

Solidity verifier contract for [gnark](https://github.com/Consensys/gnark) `bn254` PLONK proofs.
Based on [gnark's version](https://github.com/Consensys/gnark/blob/e93fa7645f848eed8c24eac5b2bdb44dfa86d824/backend/plonk/bn254/solidity.go)
but with support for passing in the verification key as calldata.

## Usage

```golang
import (
	"math/big"

	"github.com/consensys/gnark-crypto/ecc/bn254/fr"
	"github.com/consensys/gnark/backend/plonk"
	bn254 "github.com/consensys/gnark/backend/plonk/bn254"
	"github.com/consensys/gnark/backend/witness"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	verifier "github.com/mdehoog/gnark-plonk-verifier/backend/plonk/bn254"
	"github.com/mdehoog/gnark-plonk-verifier/bindings"
)

func Verify(pv *bindings.PlonkVerifier, vk plonk.VerifyingKey, proof plonk.Proof, publicWitness witness.Witness) (bool, error) {
	pr := proof.(*bn254.Proof).MarshalSolidity()
	pw := make([]*big.Int, len(publicWitness.Vector().(fr.Vector)))
	for i := 0; i < len(pw); i++ {
		pw[i] = publicWitness.Vector().(fr.Vector)[i].BigInt(big.NewInt(0))
	}
	vkb, err := verifier.VerifyingKey{VerifyingKey: vk.(*bn254.VerifyingKey)}.MarshalSolidity()
	if err != nil {
		return false, err
	}
	return pv.Verify(&bind.CallOpts{}, vkb, pr, pw)
}
```
