.PHONY: bindings
bindings:
	forge clean && forge build --via-ir --extra-output-files abi
	mkdir -p bindings
	abigen --abi out/PlonkVerifier.sol/PlonkVerifier.abi.json --pkg bindings --type PlonkVerifier --out bindings/plonk_verifier.go
