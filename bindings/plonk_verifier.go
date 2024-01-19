// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package bindings

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
)

// PlonkVerifierMetaData contains all meta data concerning the PlonkVerifier contract.
var PlonkVerifierMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"Verify\",\"inputs\":[{\"name\":\"vk\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"public_inputs\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"success\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"}]",
}

// PlonkVerifierABI is the input ABI used to generate the binding from.
// Deprecated: Use PlonkVerifierMetaData.ABI instead.
var PlonkVerifierABI = PlonkVerifierMetaData.ABI

// PlonkVerifier is an auto generated Go binding around an Ethereum contract.
type PlonkVerifier struct {
	PlonkVerifierCaller     // Read-only binding to the contract
	PlonkVerifierTransactor // Write-only binding to the contract
	PlonkVerifierFilterer   // Log filterer for contract events
}

// PlonkVerifierCaller is an auto generated read-only Go binding around an Ethereum contract.
type PlonkVerifierCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PlonkVerifierTransactor is an auto generated write-only Go binding around an Ethereum contract.
type PlonkVerifierTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PlonkVerifierFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type PlonkVerifierFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PlonkVerifierSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type PlonkVerifierSession struct {
	Contract     *PlonkVerifier    // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// PlonkVerifierCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type PlonkVerifierCallerSession struct {
	Contract *PlonkVerifierCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts        // Call options to use throughout this session
}

// PlonkVerifierTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type PlonkVerifierTransactorSession struct {
	Contract     *PlonkVerifierTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// PlonkVerifierRaw is an auto generated low-level Go binding around an Ethereum contract.
type PlonkVerifierRaw struct {
	Contract *PlonkVerifier // Generic contract binding to access the raw methods on
}

// PlonkVerifierCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type PlonkVerifierCallerRaw struct {
	Contract *PlonkVerifierCaller // Generic read-only contract binding to access the raw methods on
}

// PlonkVerifierTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type PlonkVerifierTransactorRaw struct {
	Contract *PlonkVerifierTransactor // Generic write-only contract binding to access the raw methods on
}

// NewPlonkVerifier creates a new instance of PlonkVerifier, bound to a specific deployed contract.
func NewPlonkVerifier(address common.Address, backend bind.ContractBackend) (*PlonkVerifier, error) {
	contract, err := bindPlonkVerifier(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &PlonkVerifier{PlonkVerifierCaller: PlonkVerifierCaller{contract: contract}, PlonkVerifierTransactor: PlonkVerifierTransactor{contract: contract}, PlonkVerifierFilterer: PlonkVerifierFilterer{contract: contract}}, nil
}

// NewPlonkVerifierCaller creates a new read-only instance of PlonkVerifier, bound to a specific deployed contract.
func NewPlonkVerifierCaller(address common.Address, caller bind.ContractCaller) (*PlonkVerifierCaller, error) {
	contract, err := bindPlonkVerifier(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &PlonkVerifierCaller{contract: contract}, nil
}

// NewPlonkVerifierTransactor creates a new write-only instance of PlonkVerifier, bound to a specific deployed contract.
func NewPlonkVerifierTransactor(address common.Address, transactor bind.ContractTransactor) (*PlonkVerifierTransactor, error) {
	contract, err := bindPlonkVerifier(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &PlonkVerifierTransactor{contract: contract}, nil
}

// NewPlonkVerifierFilterer creates a new log filterer instance of PlonkVerifier, bound to a specific deployed contract.
func NewPlonkVerifierFilterer(address common.Address, filterer bind.ContractFilterer) (*PlonkVerifierFilterer, error) {
	contract, err := bindPlonkVerifier(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &PlonkVerifierFilterer{contract: contract}, nil
}

// bindPlonkVerifier binds a generic wrapper to an already deployed contract.
func bindPlonkVerifier(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(PlonkVerifierABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PlonkVerifier *PlonkVerifierRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PlonkVerifier.Contract.PlonkVerifierCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PlonkVerifier *PlonkVerifierRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PlonkVerifier.Contract.PlonkVerifierTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PlonkVerifier *PlonkVerifierRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PlonkVerifier.Contract.PlonkVerifierTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PlonkVerifier *PlonkVerifierCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PlonkVerifier.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PlonkVerifier *PlonkVerifierTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PlonkVerifier.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PlonkVerifier *PlonkVerifierTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PlonkVerifier.Contract.contract.Transact(opts, method, params...)
}

// Verify is a free data retrieval call binding the contract method 0x2bf9db52.
//
// Solidity: function Verify(bytes vk, bytes proof, uint256[] public_inputs) view returns(bool success)
func (_PlonkVerifier *PlonkVerifierCaller) Verify(opts *bind.CallOpts, vk []byte, proof []byte, public_inputs []*big.Int) (bool, error) {
	var out []interface{}
	err := _PlonkVerifier.contract.Call(opts, &out, "Verify", vk, proof, public_inputs)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Verify is a free data retrieval call binding the contract method 0x2bf9db52.
//
// Solidity: function Verify(bytes vk, bytes proof, uint256[] public_inputs) view returns(bool success)
func (_PlonkVerifier *PlonkVerifierSession) Verify(vk []byte, proof []byte, public_inputs []*big.Int) (bool, error) {
	return _PlonkVerifier.Contract.Verify(&_PlonkVerifier.CallOpts, vk, proof, public_inputs)
}

// Verify is a free data retrieval call binding the contract method 0x2bf9db52.
//
// Solidity: function Verify(bytes vk, bytes proof, uint256[] public_inputs) view returns(bool success)
func (_PlonkVerifier *PlonkVerifierCallerSession) Verify(vk []byte, proof []byte, public_inputs []*big.Int) (bool, error) {
	return _PlonkVerifier.Contract.Verify(&_PlonkVerifier.CallOpts, vk, proof, public_inputs)
}
