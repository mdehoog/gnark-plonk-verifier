pragma solidity ^0.8.19;

/// @title PlonkVerifier
/// @notice Modified version of Gnark's PlonkVerifier contract that supports passing a
///         verification key as calldata, rather than storing it in the contract. See
///         https://github.com/Consensys/gnark/blob/e93fa7645f848eed8c24eac5b2bdb44dfa86d824/backend/plonk/bn254/solidity.go
///         for the original contract template.
contract PlonkVerifier {

    uint256 private constant R_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 private constant R_MOD_MINUS_ONE = 21888242871839275222246405745257275088548364400416034343698204186575808495616;
    uint256 private constant P_MOD = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // ------------------------------------------------
    // vk offsets

    uint256 private constant G2_SRS_0_X_0 = 0x00;
    uint256 private constant G2_SRS_0_X_1 = 0x20;
    uint256 private constant G2_SRS_0_Y_0 = 0x40;
    uint256 private constant G2_SRS_0_Y_1 = 0x60;

    uint256 private constant G2_SRS_1_X_0 = 0x80;
    uint256 private constant G2_SRS_1_X_1 = 0xa0;
    uint256 private constant G2_SRS_1_Y_0 = 0xc0;
    uint256 private constant G2_SRS_1_Y_1 = 0xe0;

    uint256 private constant G1_SRS_X = 0x100;
    uint256 private constant G1_SRS_Y = 0x120;

    uint256 private constant VK_NB_PUBLIC_INPUTS = 0x140;
    uint256 private constant VK_DOMAIN_SIZE = 0x160;
    uint256 private constant VK_INV_DOMAIN_SIZE = 0x180;
    uint256 private constant VK_OMEGA = 0x1a0;
    uint256 private constant VK_QL_COM_X = 0x1c0;
    uint256 private constant VK_QL_COM_Y = 0x1e0;
    uint256 private constant VK_QR_COM_X = 0x200;
    uint256 private constant VK_QR_COM_Y = 0x220;
    uint256 private constant VK_QM_COM_X = 0x240;
    uint256 private constant VK_QM_COM_Y = 0x260;
    uint256 private constant VK_QO_COM_X = 0x280;
    uint256 private constant VK_QO_COM_Y = 0x2a0;
    uint256 private constant VK_QK_COM_X = 0x2c0;
    uint256 private constant VK_QK_COM_Y = 0x2e0;

    uint256 private constant VK_S1_COM_X = 0x300;
    uint256 private constant VK_S1_COM_Y = 0x320;

    uint256 private constant VK_S2_COM_X = 0x340;
    uint256 private constant VK_S2_COM_Y = 0x360;

    uint256 private constant VK_S3_COM_X = 0x380;
    uint256 private constant VK_S3_COM_Y = 0x3a0;
    
    uint256 private constant VK_COSET_SHIFT = 0x3c0;
    
    uint256 private constant VK_NB_CUSTOM_GATES = 0x3e0;
    uint256 private constant VK_QCP_X = 0x400;
    uint256 private constant VK_QCP_Y = 0x420;
//    uint256[] VK_QCP_X+Y;          // from (0x400) to (0x400 + 0x40 * VK_NB_CUSTOM_GATES)
//    uint256[] VK_INDEX_COMMIT_API; // from (0x400 + 0x40 * VK_NB_CUSTOM_GATES) to (0x400 + 0x60 * VK_NB_CUSTOM_GATES)

    // ------------------------------------------------

    // offset proof
    uint256 private constant PROOF_L_COM_X = 0x00;
    uint256 private constant PROOF_L_COM_Y = 0x20;
    uint256 private constant PROOF_R_COM_X = 0x40;
    uint256 private constant PROOF_R_COM_Y = 0x60;
    uint256 private constant PROOF_O_COM_X = 0x80;
    uint256 private constant PROOF_O_COM_Y = 0xa0;

    // h = h_0 + x^{n+2}h_1 + x^{2(n+2)}h_2
    uint256 private constant PROOF_H_0_X = 0xc0;
    uint256 private constant PROOF_H_0_Y = 0xe0;
    uint256 private constant PROOF_H_1_X = 0x100;
    uint256 private constant PROOF_H_1_Y = 0x120;
    uint256 private constant PROOF_H_2_X = 0x140;
    uint256 private constant PROOF_H_2_Y = 0x160;

    // wire values at zeta
    uint256 private constant PROOF_L_AT_ZETA = 0x180;
    uint256 private constant PROOF_R_AT_ZETA = 0x1a0;
    uint256 private constant PROOF_O_AT_ZETA = 0x1c0;

    //uint256[STATE_WIDTH-1] permutation_polynomials_at_zeta; // Sσ1(zeta),Sσ2(zeta)
    uint256 private constant PROOF_S1_AT_ZETA = 0x1e0; // Sσ1(zeta)
    uint256 private constant PROOF_S2_AT_ZETA = 0x200; // Sσ2(zeta)

    //Bn254.G1Point grand_product_commitment;                 // [z(x)]
    uint256 private constant PROOF_GRAND_PRODUCT_COMMITMENT_X = 0x220;
    uint256 private constant PROOF_GRAND_PRODUCT_COMMITMENT_Y = 0x240;

    uint256 private constant PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA = 0x260; // z(w*zeta)
    uint256 private constant PROOF_QUOTIENT_POLYNOMIAL_AT_ZETA = 0x280; // t(zeta)
    uint256 private constant PROOF_LINEARISED_POLYNOMIAL_AT_ZETA = 0x2a0; // r(zeta)

    // Folded proof for the opening of H, linearised poly, l, r, o, s_1, s_2, qcp
    uint256 private constant PROOF_BATCH_OPENING_AT_ZETA_X = 0x2c0; // [Wzeta]
    uint256 private constant PROOF_BATCH_OPENING_AT_ZETA_Y = 0x2e0;

    uint256 private constant PROOF_OPENING_AT_ZETA_OMEGA_X = 0x300;
    uint256 private constant PROOF_OPENING_AT_ZETA_OMEGA_Y = 0x320;

    uint256 private constant PROOF_OPENING_QCP_AT_ZETA = 0x340;

    // -> next part of proof is
    // [ openings_selector_commits || commitments_wires_commit_api]

    // -------- offset state

    // challenges to check the claimed quotient
    uint256 private constant STATE_ALPHA = 0x00;
    uint256 private constant STATE_BETA = 0x20;
    uint256 private constant STATE_GAMMA = 0x40;
    uint256 private constant STATE_ZETA = 0x60;

    // reusable value
    uint256 private constant STATE_ALPHA_SQUARE_LAGRANGE_0 = 0x80;

    // commitment to H
    uint256 private constant STATE_FOLDED_H_X = 0xa0;
    uint256 private constant STATE_FOLDED_H_Y = 0xc0;

    // commitment to the linearised polynomial
    uint256 private constant STATE_LINEARISED_POLYNOMIAL_X = 0xe0;
    uint256 private constant STATE_LINEARISED_POLYNOMIAL_Y = 0x100;

    // Folded proof for the opening of H, linearised poly, l, r, o, s_1, s_2, qcp
    uint256 private constant STATE_FOLDED_CLAIMED_VALUES = 0x120;

    // folded digests of H, linearised poly, l, r, o, s_1, s_2, qcp
    uint256 private constant STATE_FOLDED_DIGESTS_X = 0x140;
    uint256 private constant STATE_FOLDED_DIGESTS_Y = 0x160;

    uint256 private constant STATE_PI = 0x180;

    uint256 private constant STATE_ZETA_POWER_N_MINUS_ONE = 0x1a0;

    uint256 private constant STATE_GAMMA_KZG = 0x1c0;

    uint256 private constant STATE_SUCCESS = 0x1e0;
    uint256 private constant STATE_CHECK_VAR = 0x200; // /!\ this slot is used for debugging only

    uint256 private constant STATE_LAST_MEM = 0x220;

    // -------- errors
    uint256 private constant ERROR_STRING_ID = 0x08c379a000000000000000000000000000000000000000000000000000000000; // selector for function Error(string)


    // -------- utils (for hash_fr)
    uint256 private constant HASH_FR_BB = 340282366920938463463374607431768211456; // 2**128
    uint256 private constant HASH_FR_ZERO_UINT256 = 0;

    uint8 private constant HASH_FR_LEN_IN_BYTES = 48;
    uint8 private constant HASH_FR_SIZE_DOMAIN = 11;
    uint8 private constant HASH_FR_ONE = 1;
    uint8 private constant HASH_FR_TWO = 2;

    /// Verify a Plonk proof.
    /// Reverts if the proof or the public inputs are malformed.
    /// @param vk serialised verification key (using gnark-plonk-verifier's MarshalSolidity)
    /// @param proof serialised plonk proof (using gnark's MarshalSolidity)
    /// @param public_inputs (must be reduced)
    /// @return success true if the proof passes false otherwise
    function Verify(bytes calldata vk, bytes calldata proof, uint256[] calldata public_inputs)
    public view returns(bool success) {

        assembly {

            let numConstraints := calldataload(add(vk.offset, VK_NB_CUSTOM_GATES))
            let vkIndexCommitApi := add(vk.offset, add(VK_QCP_X, mul(numConstraints, 0x40)))
            let mem := mload(0x40)
            let freeMem := add(mem, STATE_LAST_MEM)

            // sanity checks
            check_number_of_public_inputs(public_inputs.length, vk.offset)
            check_inputs_size(public_inputs.length, public_inputs.offset)
            check_proof_size(proof.length, vk.offset, numConstraints)
            check_proof_openings_size(proof.offset, vk.offset, numConstraints)

            // compute the challenges
            let prev_challenge_non_reduced
            prev_challenge_non_reduced := derive_gamma(proof.offset, public_inputs.length, public_inputs.offset, vk.offset, numConstraints)
            prev_challenge_non_reduced := derive_beta(prev_challenge_non_reduced)
            prev_challenge_non_reduced := derive_alpha(proof.offset, prev_challenge_non_reduced, vk.offset, numConstraints)
            derive_zeta(proof.offset, prev_challenge_non_reduced)

            // evaluation of Z=Xⁿ-1 at ζ, we save this value
            let zeta := mload(add(mem, STATE_ZETA))
            let zeta_power_n_minus_one := addmod(pow(zeta, calldataload(add(vk.offset, VK_DOMAIN_SIZE)), freeMem), sub(R_MOD, 1), R_MOD)
            mstore(add(mem, STATE_ZETA_POWER_N_MINUS_ONE), zeta_power_n_minus_one)

            // public inputs contribution
            let l_pi := sum_pi_wo_api_commit(public_inputs.offset, public_inputs.length, freeMem, vk.offset)
            let l_wocommit := sum_pi_commit(proof.offset, public_inputs.length, freeMem, vk.offset, numConstraints, vkIndexCommitApi)
            l_pi := addmod(l_wocommit, l_pi, R_MOD)
            mstore(add(mem, STATE_PI), l_pi)

            compute_alpha_square_lagrange_0(vk.offset)
            verify_quotient_poly_eval_at_zeta(proof.offset)
            fold_h(proof.offset, vk.offset)
            compute_commitment_linearised_polynomial(proof.offset, vk.offset, numConstraints)
            compute_gamma_kzg(proof.offset, vk.offset, numConstraints)
            fold_state(proof.offset, vk.offset, numConstraints)
            batch_verify_multi_points(proof.offset, vk.offset)

            success := mload(add(mem, STATE_SUCCESS))

            // Beginning errors -------------------------------------------------

            function error_nb_public_inputs() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID) // selector for function Error(string)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x1d)
                mstore(add(ptError, 0x44), "wrong number of public inputs")
                revert(ptError, 0x64)
            }

            /// Called when an operation on Bn254 fails
            /// @dev for instance when calling EcMul on a point not on Bn254.
            function error_ec_op() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID) // selector for function Error(string)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x12)
                mstore(add(ptError, 0x44), "error ec operation")
                revert(ptError, 0x64)
            }

            /// Called when one of the public inputs is not reduced.
            function error_inputs_size() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID) // selector for function Error(string)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x18)
                mstore(add(ptError, 0x44), "inputs are bigger than r")
                revert(ptError, 0x64)
            }

            /// Called when the size proof is not as expected
            /// @dev to avoid overflow attack for instance
            function error_proof_size() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID) // selector for function Error(string)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x10)
                mstore(add(ptError, 0x44), "wrong proof size")
                revert(ptError, 0x64)
            }

            /// Called when one the openings is bigger than r
            /// The openings are the claimed evalutions of a polynomial
            /// in a Kzg proof.
            function error_proof_openings_size() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID) // selector for function Error(string)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x16)
                mstore(add(ptError, 0x44), "openings bigger than r")
                revert(ptError, 0x64)
            }

            function error_verify() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID) // selector for function Error(string)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0xc)
                mstore(add(ptError, 0x44), "error verify")
                revert(ptError, 0x64)
            }

            function error_random_generation() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID) // selector for function Error(string)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x14)
                mstore(add(ptError, 0x44), "error random gen kzg")
                revert(ptError, 0x64)
            }
            // end errors -------------------------------------------------

            // Beginning checks -------------------------------------------------

            /// @param s actual number of public inputs
            function check_number_of_public_inputs(s, avk) {
                if iszero(eq(s, calldataload(add(avk, VK_NB_PUBLIC_INPUTS)))) {
                    error_nb_public_inputs()
                }
            }

            /// Checks that the public inputs are < R_MOD.
            /// @param s number of public inputs
            /// @param p pointer to the public inputs array
            function check_inputs_size(s, p) {
                for {let i} lt(i, s) {i:=add(i,1)}
                {
                    if gt(calldataload(p), R_MOD_MINUS_ONE) {
                        error_inputs_size()
                    }
                    p := add(p, 0x20)
                }
            }

            /// Checks if the proof is of the correct size
            /// @param actual_proof_size size of the proof (not the expected size)
            function check_proof_size(actual_proof_size, avk, constraints) {
                let expected_proof_size := add(0x340, mul(constraints,0x60))
                if iszero(eq(actual_proof_size, expected_proof_size)) {
                    error_proof_size()
                }
            }

            /// Checks if the multiple openings of the polynomials are < R_MOD.
            /// @param aproof pointer to the beginning of the proof
            /// @dev the 'a' prepending proof is to have a local name
            function check_proof_openings_size(aproof, avk, constraints) {

                // linearised polynomial at zeta
                let p := add(aproof, PROOF_LINEARISED_POLYNOMIAL_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // quotient polynomial at zeta
                p := add(aproof, PROOF_QUOTIENT_POLYNOMIAL_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // PROOF_L_AT_ZETA
                p := add(aproof, PROOF_L_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // PROOF_R_AT_ZETA
                p := add(aproof, PROOF_R_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // PROOF_O_AT_ZETA
                p := add(aproof, PROOF_O_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // PROOF_S1_AT_ZETA
                p := add(aproof, PROOF_S1_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // PROOF_S2_AT_ZETA
                p := add(aproof, PROOF_S2_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA
                p := add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) {
                    error_proof_openings_size()
                }

                // PROOF_OPENING_QCP_AT_ZETA

                p := add(aproof, PROOF_OPENING_QCP_AT_ZETA)
                for {let i:=0} lt(i, constraints) {i:=add(i,1)}
                {
                    if gt(calldataload(p), R_MOD_MINUS_ONE) {
                        error_proof_openings_size()
                    }
                    p := add(p, 0x20)
                }

            }
            // end checks -------------------------------------------------

            // Beginning challenges -------------------------------------------------

            /// Derive gamma as Sha256(<transcript>)
            /// @param aproof pointer to the proof
            /// @param nb_pi number of public inputs
            /// @param pi pointer to the array of public inputs
            /// @return the challenge gamma, not reduced
            /// @notice The transcript is the concatenation (in this order) of:
            /// * the word "gamma" in ascii, equal to [0x67,0x61,0x6d, 0x6d, 0x61] and encoded as a uint256.
            /// * the commitments to the permutation polynomials S1, S2, S3, where we concatenate the coordinates of those points
            /// * the commitments of Ql, Qr, Qm, Qo, Qk
            /// * the public inputs
            /// * the commitments of the wires related to the custom gates (commitments_wires_commit_api)
            /// * commitments to L, R, O (proof_<l,r,o>_com_<x,y>)
            /// The data described above is written starting at mPtr. "gamma" lies on 5 bytes,
            /// and is encoded as a uint256 number n. In basis b = 256, the number looks like this
            /// [0 0 0 .. 0x67 0x61 0x6d, 0x6d, 0x61]. The first non zero entry is at position 27=0x1b
            /// Gamma reduced (the actual challenge) is stored at add(state, state_gamma)
            function derive_gamma(aproof, nb_pi, pi, avk, constraints)->gamma_not_reduced {

                let state := mload(0x40)
                let mPtr := add(state, STATE_LAST_MEM)

                // gamma
                // gamma in ascii is [0x67,0x61,0x6d, 0x6d, 0x61]
                // (same for alpha, beta, zeta)
                mstore(mPtr, 0x67616d6d61) // "gamma"

                mstore(add(mPtr, 0x20), calldataload(add(avk, VK_S1_COM_X)))
                mstore(add(mPtr, 0x40), calldataload(add(avk, VK_S1_COM_Y)))
                mstore(add(mPtr, 0x60), calldataload(add(avk, VK_S2_COM_X)))
                mstore(add(mPtr, 0x80), calldataload(add(avk, VK_S2_COM_Y)))
                mstore(add(mPtr, 0xa0), calldataload(add(avk, VK_S3_COM_X)))
                mstore(add(mPtr, 0xc0), calldataload(add(avk, VK_S3_COM_Y)))
                mstore(add(mPtr, 0xe0), calldataload(add(avk, VK_QL_COM_X)))
                mstore(add(mPtr, 0x100), calldataload(add(avk, VK_QL_COM_Y)))
                mstore(add(mPtr, 0x120), calldataload(add(avk, VK_QR_COM_X)))
                mstore(add(mPtr, 0x140), calldataload(add(avk, VK_QR_COM_Y)))
                mstore(add(mPtr, 0x160), calldataload(add(avk, VK_QM_COM_X)))
                mstore(add(mPtr, 0x180), calldataload(add(avk, VK_QM_COM_Y)))
                mstore(add(mPtr, 0x1a0), calldataload(add(avk, VK_QO_COM_X)))
                mstore(add(mPtr, 0x1c0), calldataload(add(avk, VK_QO_COM_Y)))
                mstore(add(mPtr, 0x1e0), calldataload(add(avk, VK_QK_COM_X)))
                mstore(add(mPtr, 0x200), calldataload(add(avk, VK_QK_COM_Y)))

                for {let i:=0} lt(i, constraints) {i:=add(i,1)}
                {
                    mstore(add(mPtr, add(544, mul(i, 64))), calldataload(add(avk, add(VK_QCP_X, mul(0x40, i)))))
                    mstore(add(mPtr, add(576, mul(i, 64))), calldataload(add(avk, add(VK_QCP_Y, mul(0x40, i)))))
                }

                // public inputs
                let _mPtr := add(mPtr, add(mul(constraints, 64), 544))
                let size_pi_in_bytes := mul(nb_pi, 0x20)
                calldatacopy(_mPtr, pi, size_pi_in_bytes)
                _mPtr := add(_mPtr, size_pi_in_bytes)

                // commitments to l, r, o
                let size_commitments_lro_in_bytes := 0xc0
                calldatacopy(_mPtr, aproof, size_commitments_lro_in_bytes)
                _mPtr := add(_mPtr, size_commitments_lro_in_bytes)

                // total size is :
                // sizegamma(=0x5) + 11*64(=0x2c0)
                // + nb_public_inputs*0x20
                // + nb_custom gates*0x40
                let size := add(0x2c5, size_pi_in_bytes)
                size := add(size, mul(constraints, 0x40))
                let l_success := staticcall(gas(), 0x2, add(mPtr, 0x1b), size, mPtr, 0x20) //0x1b -> 000.."gamma"
                if iszero(l_success) {
                    error_verify()
                }
                gamma_not_reduced := mload(mPtr)
                mstore(add(state, STATE_GAMMA), mod(gamma_not_reduced, R_MOD))
            }

            /// derive beta as Sha256<transcript>
            /// @param gamma_not_reduced the previous challenge (gamma) not reduced
            /// @return beta_not_reduced the next challenge, beta, not reduced
            /// @notice the transcript consists of the previous challenge only.
            /// The reduced version of beta is stored at add(state, state_beta)
            function derive_beta(gamma_not_reduced)->beta_not_reduced{

                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                // beta
                mstore(mPtr, 0x62657461) // "beta"
                mstore(add(mPtr, 0x20), gamma_not_reduced)
                let l_success := staticcall(gas(), 0x2, add(mPtr, 0x1c), 0x24, mPtr, 0x20) //0x1b -> 000.."gamma"
                if iszero(l_success) {
                    error_verify()
                }
                beta_not_reduced := mload(mPtr)
                mstore(add(state, STATE_BETA), mod(beta_not_reduced, R_MOD))
            }

            /// derive alpha as sha256<transcript>
            /// @param aproof pointer to the proof object
            /// @param beta_not_reduced the previous challenge (beta) not reduced
            /// @return alpha_not_reduced the next challenge, alpha, not reduced
            /// @notice the transcript consists of the previous challenge (beta)
            /// not reduced, the commitments to the wires associated to the QCP_i,
            /// and the commitment to the grand product polynomial
            function derive_alpha(aproof, beta_not_reduced, avk, constraints)->alpha_not_reduced {

                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                let full_size := 0x65 // size("alpha") + 0x20 (previous challenge)

                // alpha
                mstore(mPtr, 0x616C706861) // "alpha"
                let _mPtr := add(mPtr, 0x20)
                mstore(_mPtr, beta_not_reduced)
                _mPtr := add(_mPtr, 0x20)

                // Bsb22Commitments
                let proof_bsb_commitments := add(aproof, add(mul(constraints, 32), 832))
                let size_bsb_commitments := mul(0x40, constraints)
                calldatacopy(_mPtr, proof_bsb_commitments, size_bsb_commitments)
                _mPtr := add(_mPtr, size_bsb_commitments)
                full_size := add(full_size, size_bsb_commitments)

                // [Z], the commitment to the grand product polynomial
                calldatacopy(_mPtr, add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X), 0x40)
                let l_success := staticcall(gas(), 0x2, add(mPtr, 0x1b), full_size, mPtr, 0x20)
                if iszero(l_success) {
                    error_verify()
                }

                alpha_not_reduced := mload(mPtr)
                mstore(add(state, STATE_ALPHA), mod(alpha_not_reduced, R_MOD))
            }

            /// derive zeta as sha256<transcript>
            /// @param aproof pointer to the proof object
            /// @param alpha_not_reduced the previous challenge (alpha) not reduced
            /// The transcript consists of the previous challenge and the commitment to
            /// the quotient polynomial h.
            function derive_zeta(aproof, alpha_not_reduced) {

                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                // zeta
                mstore(mPtr, 0x7a657461) // "zeta"
                mstore(add(mPtr, 0x20), alpha_not_reduced)
                calldatacopy(add(mPtr, 0x40), add(aproof, PROOF_H_0_X), 0xc0)
                let l_success := staticcall(gas(), 0x2, add(mPtr, 0x1c), 0xe4, mPtr, 0x20)
                if iszero(l_success) {
                    error_verify()
                }
                let zeta_not_reduced := mload(mPtr)
                mstore(add(state, STATE_ZETA), mod(zeta_not_reduced, R_MOD))
            }
            // END challenges -------------------------------------------------

            // BEGINNING compute_pi -------------------------------------------------

            /// sum_pi_wo_api_commit computes the public inputs contributions,
            /// except for the public inputs coming from the custom gate
            /// @param ins pointer to the public inputs
            /// @param n number of public inputs
            /// @param mPtr free memory
            /// @return pi_wo_commit public inputs contribution (except the public inputs coming from the custom gate)
            function sum_pi_wo_api_commit(ins, n, mPtr, avk)->pi_wo_commit {

                let state := mload(0x40)
                let z := mload(add(state, STATE_ZETA))
                let zpnmo := mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE))

                let li := mPtr
                batch_compute_lagranges_at_z(z, zpnmo, n, li, avk)

                let tmp := 0
                for {let i:=0} lt(i,n) {i:=add(i,1)}
                {
                    tmp := mulmod(mload(li), calldataload(ins), R_MOD)
                    pi_wo_commit := addmod(pi_wo_commit, tmp, R_MOD)
                    li := add(li, 0x20)
                    ins := add(ins, 0x20)
                }

            }

            /// batch_compute_lagranges_at_z computes [L_0(z), .., L_{n-1}(z)]
            /// @param z point at which the Lagranges are evaluated
            /// @param zpnmo ζⁿ-1
            /// @param n number of public inputs (number of Lagranges to compute)
            /// @param mPtr pointer to which the results are stored
            function batch_compute_lagranges_at_z(z, zpnmo, n, mPtr, avk) {

                let zn := mulmod(zpnmo, calldataload(add(avk, VK_INV_DOMAIN_SIZE)), R_MOD) // 1/n * (ζⁿ - 1)

                let _w := 1
                let _mPtr := mPtr
                for {let i:=0} lt(i,n) {i:=add(i,1)}
                {
                    mstore(_mPtr, addmod(z,sub(R_MOD, _w), R_MOD))
                    _w := mulmod(_w, calldataload(add(avk, VK_OMEGA)), R_MOD)
                    _mPtr := add(_mPtr, 0x20)
                }
                batch_invert(mPtr, n, _mPtr)
                _mPtr := mPtr
                _w := 1
                for {let i:=0} lt(i,n) {i:=add(i,1)}
                {
                    mstore(_mPtr, mulmod(mulmod(mload(_mPtr), zn , R_MOD), _w, R_MOD))
                    _mPtr := add(_mPtr, 0x20)
                    _w := mulmod(_w, calldataload(add(avk, VK_OMEGA)), R_MOD)
                }
            }

            /// @notice Montgomery trick for batch inversion mod R_MOD
            /// @param ins pointer to the data to batch invert
            /// @param number of elements to batch invert
            /// @param mPtr free memory
            function batch_invert(ins, nb_ins, mPtr) {
                mstore(mPtr, 1)
                let offset := 0
                for {let i:=0} lt(i, nb_ins) {i:=add(i,1)}
                {
                    let prev := mload(add(mPtr, offset))
                    let cur := mload(add(ins, offset))
                    cur := mulmod(prev, cur, R_MOD)
                    offset := add(offset, 0x20)
                    mstore(add(mPtr, offset), cur)
                }
                ins := add(ins, sub(offset, 0x20))
                mPtr := add(mPtr, offset)
                let inv := pow(mload(mPtr), sub(R_MOD,2), add(mPtr, 0x20))
                for {let i:=0} lt(i, nb_ins) {i:=add(i,1)}
                {
                    mPtr := sub(mPtr, 0x20)
                    let tmp := mload(ins)
                    let cur := mulmod(inv, mload(mPtr), R_MOD)
                    mstore(ins, cur)
                    inv := mulmod(inv, tmp, R_MOD)
                    ins := sub(ins, 0x20)
                }
            }


            /// Public inputs (the ones coming from the custom gate) contribution
            /// @param aproof pointer to the proof
            /// @param nb_public_inputs number of public inputs
            /// @param mPtr pointer to free memory
            /// @return pi_commit custom gate public inputs contribution
            function sum_pi_commit(aproof, nb_public_inputs, mPtr, avk, constraints, VK_INDEX_COMMIT_API)->pi_commit {

                let state := mload(0x40)
                let z := mload(add(state, STATE_ZETA))
                let zpnmo := mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE))

                let p := add(aproof, add(mul(constraints, 32), 832))

                let h_fr
                let ith_lagrange

                for {let i:=0} lt(i, constraints) {i:=add(i,1)}
                {
                    h_fr := hash_fr(calldataload(p), calldataload(add(p, 0x20)), mPtr)
                    ith_lagrange := compute_ith_lagrange_at_z(z, zpnmo, add(nb_public_inputs, calldataload(add(VK_INDEX_COMMIT_API, mul(0x20, i)))), mPtr, avk)
                    pi_commit := addmod(pi_commit, mulmod(h_fr, ith_lagrange, R_MOD), R_MOD)
                    p := add(p, 0x40)
                }
            }

            /// Computes L_i(zeta) =  ωⁱ/n * (ζⁿ-1)/(ζ-ωⁱ) where:
            /// @param z zeta
            /// @param zpmno ζⁿ-1
            /// @param i i-th lagrange
            /// @param mPtr free memory
            /// @return res = ωⁱ/n * (ζⁿ-1)/(ζ-ωⁱ)
            function compute_ith_lagrange_at_z(z, zpnmo, i, mPtr, avk)->res {

                let w := pow(calldataload(add(avk, VK_OMEGA)), i, mPtr) // w**i
                i := addmod(z, sub(R_MOD, w), R_MOD) // z-w**i
                w := mulmod(w, calldataload(add(avk, VK_INV_DOMAIN_SIZE)), R_MOD) // w**i/n
                i := pow(i, sub(R_MOD,2), mPtr) // (z-w**i)**-1
                w := mulmod(w, i, R_MOD) // w**i/n*(z-w)**-1
                res := mulmod(w, zpnmo, R_MOD)

            }

            /// @dev https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-06#section-5.2
            /// @param x x coordinate of a point on Bn254(𝔽_p)
            /// @param y y coordinate of a point on Bn254(𝔽_p)
            /// @param mPtr free memory
            /// @return res an element mod R_MOD
            function hash_fr(x, y, mPtr)->res {

                // [0x00, .. , 0x00 || x, y, || 0, 48, 0, dst, HASH_FR_SIZE_DOMAIN]
                // <-  64 bytes  ->  <-64b -> <-       1 bytes each     ->

                // [0x00, .., 0x00] 64 bytes of zero
                mstore(mPtr, HASH_FR_ZERO_UINT256)
                mstore(add(mPtr, 0x20), HASH_FR_ZERO_UINT256)

                // msg =  x || y , both on 32 bytes
                mstore(add(mPtr, 0x40), x)
                mstore(add(mPtr, 0x60), y)

                // 0 || 48 || 0 all on 1 byte
                mstore8(add(mPtr, 0x80), 0)
                mstore8(add(mPtr, 0x81), HASH_FR_LEN_IN_BYTES)
                mstore8(add(mPtr, 0x82), 0)

                // "BSB22-Plonk" = [42, 53, 42, 32, 32, 2d, 50, 6c, 6f, 6e, 6b,]
                mstore8(add(mPtr, 0x83), 0x42)
                mstore8(add(mPtr, 0x84), 0x53)
                mstore8(add(mPtr, 0x85), 0x42)
                mstore8(add(mPtr, 0x86), 0x32)
                mstore8(add(mPtr, 0x87), 0x32)
                mstore8(add(mPtr, 0x88), 0x2d)
                mstore8(add(mPtr, 0x89), 0x50)
                mstore8(add(mPtr, 0x8a), 0x6c)
                mstore8(add(mPtr, 0x8b), 0x6f)
                mstore8(add(mPtr, 0x8c), 0x6e)
                mstore8(add(mPtr, 0x8d), 0x6b)

                // size domain
                mstore8(add(mPtr, 0x8e), HASH_FR_SIZE_DOMAIN)

                let l_success := staticcall(gas(), 0x2, mPtr, 0x8f, mPtr, 0x20)
                if iszero(l_success) {
                    error_verify()
                }

                let b0 := mload(mPtr)

                // [b0         || one || dst || HASH_FR_SIZE_DOMAIN]
                // <-64bytes ->  <-    1 byte each      ->
                mstore8(add(mPtr, 0x20), HASH_FR_ONE) // 1

                mstore8(add(mPtr, 0x21), 0x42) // dst
                mstore8(add(mPtr, 0x22), 0x53)
                mstore8(add(mPtr, 0x23), 0x42)
                mstore8(add(mPtr, 0x24), 0x32)
                mstore8(add(mPtr, 0x25), 0x32)
                mstore8(add(mPtr, 0x26), 0x2d)
                mstore8(add(mPtr, 0x27), 0x50)
                mstore8(add(mPtr, 0x28), 0x6c)
                mstore8(add(mPtr, 0x29), 0x6f)
                mstore8(add(mPtr, 0x2a), 0x6e)
                mstore8(add(mPtr, 0x2b), 0x6b)

                mstore8(add(mPtr, 0x2c), HASH_FR_SIZE_DOMAIN) // size domain
                l_success := staticcall(gas(), 0x2, mPtr, 0x2d, mPtr, 0x20)
                if iszero(l_success) {
                    error_verify()
                }

                // b1 is located at mPtr. We store b2 at add(mPtr, 0x20)

                // [b0^b1      || two || dst || HASH_FR_SIZE_DOMAIN]
                // <-64bytes ->  <-    1 byte each      ->
                mstore(add(mPtr, 0x20), xor(mload(mPtr), b0))
                mstore8(add(mPtr, 0x40), HASH_FR_TWO)

                mstore8(add(mPtr, 0x41), 0x42) // dst
                mstore8(add(mPtr, 0x42), 0x53)
                mstore8(add(mPtr, 0x43), 0x42)
                mstore8(add(mPtr, 0x44), 0x32)
                mstore8(add(mPtr, 0x45), 0x32)
                mstore8(add(mPtr, 0x46), 0x2d)
                mstore8(add(mPtr, 0x47), 0x50)
                mstore8(add(mPtr, 0x48), 0x6c)
                mstore8(add(mPtr, 0x49), 0x6f)
                mstore8(add(mPtr, 0x4a), 0x6e)
                mstore8(add(mPtr, 0x4b), 0x6b)

                mstore8(add(mPtr, 0x4c), HASH_FR_SIZE_DOMAIN) // size domain

                let offset := add(mPtr, 0x20)
                l_success := staticcall(gas(), 0x2, offset, 0x2d, offset, 0x20)
                if iszero(l_success) {
                    error_verify()
                }

                // at this point we have mPtr = [ b1 || b2] where b1 is on 32byes and b2 in 16bytes.
                // we interpret it as a big integer mod r in big endian (similar to regular decimal notation)
                // the result is then 2**(8*16)*mPtr[32:] + mPtr[32:48]
                res := mulmod(mload(mPtr), HASH_FR_BB, R_MOD) // <- res = 2**128 * mPtr[:32]
                let b1 := shr(128, mload(add(mPtr, 0x20))) // b1 <- [0, 0, .., 0 ||  b2[:16] ]
                res := addmod(res, b1, R_MOD)

            }

            // END compute_pi -------------------------------------------------

            /// @notice compute α² * 1/n * (ζ{n}-1)/(ζ - 1) where
            /// *  α = challenge derived in derive_gamma_beta_alpha_zeta
            /// * n = vk_domain_size
            /// * ω = vk_omega (generator of the multiplicative cyclic group of order n in (ℤ/rℤ)*)
            /// * ζ = zeta (challenge derived with Fiat Shamir)
            function compute_alpha_square_lagrange_0(avk) {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                let res := mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE))
                let den := addmod(mload(add(state, STATE_ZETA)), sub(R_MOD, 1), R_MOD)
                den := pow(den, sub(R_MOD, 2), mPtr)
                den := mulmod(den, calldataload(add(avk, VK_INV_DOMAIN_SIZE)), R_MOD)
                res := mulmod(den, res, R_MOD)

                let l_alpha := mload(add(state, STATE_ALPHA))
                res := mulmod(res, l_alpha, R_MOD)
                res := mulmod(res, l_alpha, R_MOD)
                mstore(add(state, STATE_ALPHA_SQUARE_LAGRANGE_0), res)
            }

            /// @notice follows alg. p.13 of https://eprint.iacr.org/2019/953.pdf
            /// with t₁ = t₂ = 1, and the proofs are ([digest] + [quotient] +purported evaluation):
            /// * [state_folded_state_digests], [proof_batch_opening_at_zeta_x], state_folded_evals
            /// * [proof_grand_product_commitment], [proof_opening_at_zeta_omega_x], [proof_grand_product_at_zeta_omega]
            /// @param aproof pointer to the proof
            function batch_verify_multi_points(aproof, avk) {
                let state := mload(0x40)
                let mPtr := add(state, STATE_LAST_MEM)

                // derive a random number. As there is no random generator, we
                // do an FS like challenge derivation, depending on both digests and
                // ζ to ensure that the prover cannot control the random numger.
                // Note: adding the other point ζω is not needed, as ω is known beforehand.
                mstore(mPtr, mload(add(state, STATE_FOLDED_DIGESTS_X)))
                mstore(add(mPtr, 0x20), mload(add(state, STATE_FOLDED_DIGESTS_Y)))
                mstore(add(mPtr, 0x40), calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_X)))
                mstore(add(mPtr, 0x60), calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_Y)))
                mstore(add(mPtr, 0x80), calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X)))
                mstore(add(mPtr, 0xa0), calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_Y)))
                mstore(add(mPtr, 0xc0), calldataload(add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_X)))
                mstore(add(mPtr, 0xe0), calldataload(add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_Y)))
                mstore(add(mPtr, 0x100), mload(add(state, STATE_ZETA)))
                mstore(add(mPtr, 0x120), mload(add(state, STATE_GAMMA_KZG)))
                let random := staticcall(gas(), 0x2, mPtr, 0x140, mPtr, 0x20)
                if iszero(random){
                    error_random_generation()
                }
                random := mod(mload(mPtr), R_MOD) // use the same variable as we are one variable away from getting stack-too-deep error...

                let folded_quotients := mPtr
                mPtr := add(folded_quotients, 0x40)
                mstore(folded_quotients, calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_X)))
                mstore(add(folded_quotients, 0x20), calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_Y)))
                point_acc_mul_calldata(folded_quotients, add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_X), random, mPtr)

                let folded_digests := add(state, STATE_FOLDED_DIGESTS_X)
                point_acc_mul_calldata(folded_digests, add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X), random, mPtr)

                let folded_evals := add(state, STATE_FOLDED_CLAIMED_VALUES)
                fr_acc_mul_calldata(folded_evals, add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA), random)

                let folded_evals_commit := mPtr
                mPtr := add(folded_evals_commit, 0x40)
                mstore(folded_evals_commit, calldataload(add(avk, G1_SRS_X)))
                mstore(add(folded_evals_commit, 0x20), calldataload(add(avk, G1_SRS_Y)))
                mstore(add(folded_evals_commit, 0x40), mload(folded_evals))
                let check_staticcall := staticcall(gas(), 7, folded_evals_commit, 0x60, folded_evals_commit, 0x40)
                if iszero(check_staticcall) {
                    error_verify()
                }

                let folded_evals_commit_y := add(folded_evals_commit, 0x20)
                mstore(folded_evals_commit_y, sub(P_MOD, mload(folded_evals_commit_y)))
                point_add(folded_digests, folded_digests, folded_evals_commit, mPtr)

                let folded_points_quotients := mPtr
                mPtr := add(mPtr, 0x40)
                point_mul_calldata(
                    folded_points_quotients,
                    add(aproof, PROOF_BATCH_OPENING_AT_ZETA_X),
                    mload(add(state, STATE_ZETA)),
                    mPtr
                )
                let zeta_omega := mulmod(mload(add(state, STATE_ZETA)), calldataload(add(avk, VK_OMEGA)), R_MOD)
                random := mulmod(random, zeta_omega, R_MOD)
                point_acc_mul_calldata(folded_points_quotients, add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_X), random, mPtr)

                point_add(folded_digests, folded_digests, folded_points_quotients, mPtr)

                let folded_quotients_y := add(folded_quotients, 0x20)
                mstore(folded_quotients_y, sub(P_MOD, mload(folded_quotients_y)))

                mstore(mPtr, mload(folded_digests))
                mstore(add(mPtr, 0x20), mload(add(folded_digests, 0x20)))
                mstore(add(mPtr, 0x40), calldataload(add(avk, G2_SRS_0_X_0))) // the 4 lines are the canonical G2 point on BN254
                mstore(add(mPtr, 0x60), calldataload(add(avk, G2_SRS_0_X_1)))
                mstore(add(mPtr, 0x80), calldataload(add(avk, G2_SRS_0_Y_0)))
                mstore(add(mPtr, 0xa0), calldataload(add(avk, G2_SRS_0_Y_1)))
                mstore(add(mPtr, 0xc0), mload(folded_quotients))
                mstore(add(mPtr, 0xe0), mload(add(folded_quotients, 0x20)))
                mstore(add(mPtr, 0x100), calldataload(add(avk, G2_SRS_1_X_0)))
                mstore(add(mPtr, 0x120), calldataload(add(avk, G2_SRS_1_X_1)))
                mstore(add(mPtr, 0x140), calldataload(add(avk, G2_SRS_1_Y_0)))
                mstore(add(mPtr, 0x160), calldataload(add(avk, G2_SRS_1_Y_1)))
                check_pairing_kzg(mPtr)
            }

            /// @notice check_pairing_kzg checks the result of the final pairing product of the batched
            /// kzg verification. The purpose of this function is to avoid exhausting the stack
            /// in the function batch_verify_multi_points.
            /// @param mPtr pointer storing the tuple of pairs
            function check_pairing_kzg(mPtr) {
                let state := mload(0x40)

                // TODO test the staticcall using the method from audit_4-5
                let l_success := staticcall(gas(), 8, mPtr, 0x180, 0x00, 0x20)
                let res_pairing := mload(0x00)
                let s_success := mload(add(state, STATE_SUCCESS))
                res_pairing := and(and(res_pairing, l_success), s_success)
                mstore(add(state, STATE_SUCCESS), res_pairing)
            }

            /// @notice Fold the opening proofs at ζ:
            /// * at state+state_folded_digest we store: [H] + γ[Linearised_polynomial]+γ²[L] + γ³[R] + γ⁴[O] + γ⁵[S₁] +γ⁶[S₂] + ∑ᵢγ⁶⁺ⁱ[Pi_{i}]
            /// * at state+state_folded_claimed_values we store: H(ζ) + γLinearised_polynomial(ζ)+γ²L(ζ) + γ³R(ζ)+ γ⁴O(ζ) + γ⁵S₁(ζ) +γ⁶S₂(ζ) + ∑ᵢγ⁶⁺ⁱPi_{i}(ζ)
            /// @param aproof pointer to the proof
            /// acc_gamma stores the γⁱ
            function fold_state(aproof, avk, constraints) {

                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                let mPtr20 := add(mPtr, 0x20)
                let mPtr40 := add(mPtr, 0x40)

                let l_gamma_kzg := mload(add(state, STATE_GAMMA_KZG))
                let acc_gamma := l_gamma_kzg
                let state_folded_digests := add(state, STATE_FOLDED_DIGESTS_X)

                mstore(add(state, STATE_FOLDED_DIGESTS_X), mload(add(state, STATE_FOLDED_H_X)))
                mstore(add(state, STATE_FOLDED_DIGESTS_Y), mload(add(state, STATE_FOLDED_H_Y)))
                mstore(add(state, STATE_FOLDED_CLAIMED_VALUES), calldataload(add(aproof, PROOF_QUOTIENT_POLYNOMIAL_AT_ZETA)))

                point_acc_mul(state_folded_digests, add(state, STATE_LINEARISED_POLYNOMIAL_X), acc_gamma, mPtr)
                fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_LINEARISED_POLYNOMIAL_AT_ZETA), acc_gamma)

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                point_acc_mul_calldata(add(state, STATE_FOLDED_DIGESTS_X), add(aproof, PROOF_L_COM_X), acc_gamma, mPtr)
                fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_L_AT_ZETA), acc_gamma)

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                point_acc_mul_calldata(state_folded_digests, add(aproof, PROOF_R_COM_X), acc_gamma, mPtr)
                fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_R_AT_ZETA), acc_gamma)

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                point_acc_mul_calldata(state_folded_digests, add(aproof, PROOF_O_COM_X), acc_gamma, mPtr)
                fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_O_AT_ZETA), acc_gamma)

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                mstore(mPtr, calldataload(add(avk, VK_S1_COM_X)))
                mstore(mPtr20, calldataload(add(avk, VK_S1_COM_Y)))
                point_acc_mul(state_folded_digests, mPtr, acc_gamma, mPtr40)
                fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_S1_AT_ZETA), acc_gamma)

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                mstore(mPtr, calldataload(add(avk, VK_S2_COM_X)))
                mstore(mPtr20, calldataload(add(avk, VK_S2_COM_Y)))
                point_acc_mul(state_folded_digests, mPtr, acc_gamma, mPtr40)
                fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_S2_AT_ZETA), acc_gamma)
                let poscaz := add(aproof, PROOF_OPENING_QCP_AT_ZETA)

                for {let i:=0} lt(i, constraints) {i:=add(i,1)}
                {
                    acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                    mstore(mPtr, calldataload(add(avk, add(VK_QCP_X, mul(0x40, i)))))
                    mstore(mPtr20, calldataload(add(avk, add(VK_QCP_Y, mul(0x40, i)))))
                    point_acc_mul(state_folded_digests, mPtr, acc_gamma, mPtr40)
                    fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), poscaz, acc_gamma)
                    poscaz := add(poscaz, 0x20)
                }
            }

            /// @notice generate the challenge (using Fiat Shamir) to fold the opening proofs
            /// at ζ.
            /// The process for deriving γ is the same as in derive_gamma but this time the inputs are
            /// in this order (the [] means it's a commitment):
            /// * ζ
            /// * [H] ( = H₁ + ζᵐ⁺²*H₂ + ζ²⁽ᵐ⁺²⁾*H₃ )
            /// * [Linearised polynomial]
            /// * [L], [R], [O]
            /// * [S₁] [S₂]
            /// * [Pi_{i}] (wires associated to custom gates)
            /// Then there are the purported evaluations of the previous committed polynomials:
            /// * H(ζ)
            /// * Linearised_polynomial(ζ)
            /// * L(ζ), R(ζ), O(ζ), S₁(ζ), S₂(ζ)
            /// * Pi_{i}(ζ)
            /// * Z(ζω)
            /// @param aproof pointer to the proof
            function compute_gamma_kzg(aproof, avk, constraints) {

                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                mstore(mPtr, 0x67616d6d61) // "gamma"
                mstore(add(mPtr, 0x20), mload(add(state, STATE_ZETA)))
                mstore(add(mPtr,0x40), mload(add(state, STATE_FOLDED_H_X)))
                mstore(add(mPtr,0x60), mload(add(state, STATE_FOLDED_H_Y)))
                mstore(add(mPtr,0x80), mload(add(state, STATE_LINEARISED_POLYNOMIAL_X)))
                mstore(add(mPtr,0xa0), mload(add(state, STATE_LINEARISED_POLYNOMIAL_Y)))
                calldatacopy(add(mPtr, 0xc0), add(aproof, PROOF_L_COM_X), 0xc0)
                mstore(add(mPtr,0x180), calldataload(add(avk, VK_S1_COM_X)))
                mstore(add(mPtr,0x1a0), calldataload(add(avk, VK_S1_COM_Y)))
                mstore(add(mPtr,0x1c0), calldataload(add(avk, VK_S2_COM_X)))
                mstore(add(mPtr,0x1e0), calldataload(add(avk, VK_S2_COM_Y)))

                let offset := 0x200
                for {let i:=0} lt(i, constraints) {i:=add(i,1)}
                {
                    mstore(add(mPtr,offset), calldataload(add(avk, add(VK_QCP_X, mul(0x40, i)))))
                    mstore(add(mPtr,add(offset, 0x20)), calldataload(add(avk, add(VK_QCP_Y, mul(0x40, i)))))
                    offset := add(offset, 0x40)
                }

                mstore(add(mPtr, offset), calldataload(add(aproof, PROOF_QUOTIENT_POLYNOMIAL_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0x20)), calldataload(add(aproof, PROOF_LINEARISED_POLYNOMIAL_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0x40)), calldataload(add(aproof, PROOF_L_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0x60)), calldataload(add(aproof, PROOF_R_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0x80)), calldataload(add(aproof, PROOF_O_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0xa0)), calldataload(add(aproof, PROOF_S1_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0xc0)), calldataload(add(aproof, PROOF_S2_AT_ZETA)))

                let _mPtr := add(mPtr, add(offset, 0xe0))
                let _poscaz := add(aproof, PROOF_OPENING_QCP_AT_ZETA)
                for {let i:=0} lt(i, constraints) {i:=add(i,1)}
                {
                    mstore(_mPtr, calldataload(_poscaz))
                    _poscaz := add(_poscaz, 0x20)
                    _mPtr := add(_mPtr, 0x20)
                }

                mstore(_mPtr, calldataload(add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)))

                let start_input := 0x1b // 00.."gamma"
                let size_input := add(0x17, mul(constraints,3)) // number of 32bytes elmts = 0x17 (zeta+2*7+7 for the digests+openings) + 2*constraints (for the commitments of the selectors) + constraints (for the openings of the selectors)
                size_input := add(0x5, mul(size_input, 0x20)) // size in bytes: 15*32 bytes + 5 bytes for gamma
                let check_staticcall := staticcall(gas(), 0x2, add(mPtr,start_input), size_input, add(state, STATE_GAMMA_KZG), 0x20)
                if iszero(check_staticcall) {
                    error_verify()
                }
                mstore(add(state, STATE_GAMMA_KZG), mod(mload(add(state, STATE_GAMMA_KZG)), R_MOD))
            }

            function compute_commitment_linearised_polynomial_ec(aproof, s1, s2, avk, constraints) {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                mstore(mPtr, calldataload(add(avk, VK_QL_COM_X)))
                mstore(add(mPtr, 0x20), calldataload(add(avk, VK_QL_COM_Y)))
                point_mul(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    calldataload(add(aproof, PROOF_L_AT_ZETA)),
                    add(mPtr, 0x40)
                )

                mstore(mPtr, calldataload(add(avk, VK_QR_COM_X)))
                mstore(add(mPtr, 0x20), calldataload(add(avk, VK_QR_COM_Y)))
                point_acc_mul(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    calldataload(add(aproof, PROOF_R_AT_ZETA)),
                    add(mPtr, 0x40)
                )

                let rl := mulmod(calldataload(add(aproof, PROOF_L_AT_ZETA)), calldataload(add(aproof, PROOF_R_AT_ZETA)), R_MOD)
                mstore(mPtr, calldataload(add(avk, VK_QM_COM_X)))
                mstore(add(mPtr, 0x20), calldataload(add(avk, VK_QM_COM_Y)))
                point_acc_mul(add(state, STATE_LINEARISED_POLYNOMIAL_X), mPtr, rl, add(mPtr, 0x40))

                mstore(mPtr, calldataload(add(avk, VK_QO_COM_X)))
                mstore(add(mPtr, 0x20), calldataload(add(avk, VK_QO_COM_Y)))
                point_acc_mul(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    calldataload(add(aproof, PROOF_O_AT_ZETA)),
                    add(mPtr, 0x40)
                )

                mstore(mPtr, calldataload(add(avk, VK_QK_COM_X)))
                mstore(add(mPtr, 0x20), calldataload(add(avk, VK_QK_COM_Y)))
                point_add(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    add(mPtr, 0x40)
                )

                let commits_api_at_zeta := add(aproof, PROOF_OPENING_QCP_AT_ZETA)
                let commits_api := add(aproof, add(mul(constraints, 32), 832))
                for {
                    let i := 0
                } lt(i, constraints) {
                    i := add(i, 1)
                } {
                    mstore(mPtr, calldataload(commits_api))
                    mstore(add(mPtr, 0x20), calldataload(add(commits_api, 0x20)))
                    point_acc_mul(
                        add(state, STATE_LINEARISED_POLYNOMIAL_X),
                        mPtr,
                        calldataload(commits_api_at_zeta),
                        add(mPtr, 0x40)
                    )
                    commits_api_at_zeta := add(commits_api_at_zeta, 0x20)
                    commits_api := add(commits_api, 0x40)
                }

                mstore(mPtr, calldataload(add(avk, VK_S3_COM_X)))
                mstore(add(mPtr, 0x20), calldataload(add(avk, VK_S3_COM_Y)))
                point_acc_mul(add(state, STATE_LINEARISED_POLYNOMIAL_X), mPtr, s1, add(mPtr, 0x40))

                mstore(mPtr, calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X)))
                mstore(add(mPtr, 0x20), calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_Y)))
                point_acc_mul(add(state, STATE_LINEARISED_POLYNOMIAL_X), mPtr, s2, add(mPtr, 0x40))
            }

            /// @notice Compute the commitment to the linearized polynomial equal to
            ///	L(ζ)[Qₗ]+r(ζ)[Qᵣ]+R(ζ)L(ζ)[Qₘ]+O(ζ)[Qₒ]+[Qₖ]+Σᵢqc'ᵢ(ζ)[BsbCommitmentᵢ] +
            ///	α*( Z(μζ)(L(ζ)+β*S₁(ζ)+γ)*(R(ζ)+β*S₂(ζ)+γ)[S₃]-[Z](L(ζ)+β*id_{1}(ζ)+γ)*(R(ζ)+β*id_{2(ζ)+γ)*(O(ζ)+β*id_{3}(ζ)+γ) ) +
            ///	α²*L₁(ζ)[Z]
            /// where
            /// * id_1 = id, id_2 = vk_coset_shift*id, id_3 = vk_coset_shift^{2}*id
            /// * the [] means that it's a commitment (i.e. a point on Bn254(F_p))
            /// @param aproof pointer to the proof
            function compute_commitment_linearised_polynomial(aproof, avk, constraints) {
                let state := mload(0x40)
                let l_beta := mload(add(state, STATE_BETA))
                let l_gamma := mload(add(state, STATE_GAMMA))
                let l_zeta := mload(add(state, STATE_ZETA))
                let l_alpha := mload(add(state, STATE_ALPHA))

                let u := mulmod(calldataload(add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)), l_beta, R_MOD)
                let v := mulmod(l_beta, calldataload(add(aproof, PROOF_S1_AT_ZETA)), R_MOD)
                v := addmod(v, calldataload(add(aproof, PROOF_L_AT_ZETA)), R_MOD)
                v := addmod(v, l_gamma, R_MOD)

                let w := mulmod(l_beta, calldataload(add(aproof, PROOF_S2_AT_ZETA)), R_MOD)
                w := addmod(w, calldataload(add(aproof, PROOF_R_AT_ZETA)), R_MOD)
                w := addmod(w, l_gamma, R_MOD)

                let s1 := mulmod(u, v, R_MOD)
                s1 := mulmod(s1, w, R_MOD)
                s1 := mulmod(s1, l_alpha, R_MOD)

                let coset_square := mulmod(calldataload(add(avk, VK_COSET_SHIFT)), calldataload(add(avk, VK_COSET_SHIFT)), R_MOD)
                let betazeta := mulmod(l_beta, l_zeta, R_MOD)
                u := addmod(betazeta, calldataload(add(aproof, PROOF_L_AT_ZETA)), R_MOD)
                u := addmod(u, l_gamma, R_MOD)

                v := mulmod(betazeta, calldataload(add(avk, VK_COSET_SHIFT)), R_MOD)
                v := addmod(v, calldataload(add(aproof, PROOF_R_AT_ZETA)), R_MOD)
                v := addmod(v, l_gamma, R_MOD)

                w := mulmod(betazeta, coset_square, R_MOD)
                w := addmod(w, calldataload(add(aproof, PROOF_O_AT_ZETA)), R_MOD)
                w := addmod(w, l_gamma, R_MOD)

                let s2 := mulmod(u, v, R_MOD)
                s2 := mulmod(s2, w, R_MOD)
                s2 := sub(R_MOD, s2)
                s2 := mulmod(s2, l_alpha, R_MOD)
                s2 := addmod(s2, mload(add(state, STATE_ALPHA_SQUARE_LAGRANGE_0)), R_MOD)

                // at this stage:
                // * s₁ = α*Z(μζ)(l(ζ)+β*s₁(ζ)+γ)*(r(ζ)+β*s₂(ζ)+γ)*β
                // * s₂ = -α*(l(ζ)+β*ζ+γ)*(r(ζ)+β*u*ζ+γ)*(o(ζ)+β*u²*ζ+γ) + α²*L₁(ζ)

                compute_commitment_linearised_polynomial_ec(aproof, s1, s2, avk, constraints)
            }

            /// @notice compute H₁ + ζᵐ⁺²*H₂ + ζ²⁽ᵐ⁺²⁾*H₃ and store the result at
            /// state + state_folded_h
            /// @param aproof pointer to the proof
            function fold_h(aproof, avk) {
                let state := mload(0x40)
                let n_plus_two := add(calldataload(add(avk, VK_DOMAIN_SIZE)), 2)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                let zeta_power_n_plus_two := pow(mload(add(state, STATE_ZETA)), n_plus_two, mPtr)
                point_mul_calldata(add(state, STATE_FOLDED_H_X), add(aproof, PROOF_H_2_X), zeta_power_n_plus_two, mPtr)
                point_add_calldata(add(state, STATE_FOLDED_H_X), add(state, STATE_FOLDED_H_X), add(aproof, PROOF_H_1_X), mPtr)
                point_mul(add(state, STATE_FOLDED_H_X), add(state, STATE_FOLDED_H_X), zeta_power_n_plus_two, mPtr)
                point_add_calldata(add(state, STATE_FOLDED_H_X), add(state, STATE_FOLDED_H_X), add(aproof, PROOF_H_0_X), mPtr)
            }

            /// @notice check that
            ///	L(ζ)Qₗ(ζ)+r(ζ)Qᵣ(ζ)+R(ζ)L(ζ)Qₘ(ζ)+O(ζ)Qₒ(ζ)+Qₖ(ζ)+Σᵢqc'ᵢ(ζ)BsbCommitmentᵢ(ζ) +
            ///  α*( Z(μζ)(l(ζ)+β*s₁(ζ)+γ)*(r(ζ)+β*s₂(ζ)+γ)*β*s₃(X)-Z(X)(l(ζ)+β*id_1(ζ)+γ)*(r(ζ)+β*id_2(ζ)+γ)*(o(ζ)+β*id_3(ζ)+γ) ) )
            /// + α²*L₁(ζ) =
            /// (ζⁿ-1)H(ζ)
            /// @param aproof pointer to the proof
            function verify_quotient_poly_eval_at_zeta(aproof) {
                let state := mload(0x40)

                // (l(ζ)+β*s1(ζ)+γ)
                let s1 := add(mload(0x40), STATE_LAST_MEM)
                mstore(s1, mulmod(calldataload(add(aproof, PROOF_S1_AT_ZETA)), mload(add(state, STATE_BETA)), R_MOD))
                mstore(s1, addmod(mload(s1), mload(add(state, STATE_GAMMA)), R_MOD))
                mstore(s1, addmod(mload(s1), calldataload(add(aproof, PROOF_L_AT_ZETA)), R_MOD))

                // (r(ζ)+β*s2(ζ)+γ)
                let s2 := add(s1, 0x20)
                mstore(s2, mulmod(calldataload(add(aproof, PROOF_S2_AT_ZETA)), mload(add(state, STATE_BETA)), R_MOD))
                mstore(s2, addmod(mload(s2), mload(add(state, STATE_GAMMA)), R_MOD))
                mstore(s2, addmod(mload(s2), calldataload(add(aproof, PROOF_R_AT_ZETA)), R_MOD))
                // _s2 := mload(s2)

                // (o(ζ)+γ)
                let o := add(s1, 0x40)
                mstore(o, addmod(calldataload(add(aproof, PROOF_O_AT_ZETA)), mload(add(state, STATE_GAMMA)), R_MOD))

                //  α*(Z(μζ))*(l(ζ)+β*s1(ζ)+γ)*(r(ζ)+β*s2(ζ)+γ)*(o(ζ)+γ)
                mstore(s1, mulmod(mload(s1), mload(s2), R_MOD))
                mstore(s1, mulmod(mload(s1), mload(o), R_MOD))
                mstore(s1, mulmod(mload(s1), mload(add(state, STATE_ALPHA)), R_MOD))
                mstore(s1, mulmod(mload(s1), calldataload(add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)), R_MOD))

                let computed_quotient := add(s1, 0x60)

                // linearizedpolynomial + pi(zeta)
                mstore(computed_quotient,addmod(calldataload(add(aproof, PROOF_LINEARISED_POLYNOMIAL_AT_ZETA)), mload(add(state, STATE_PI)), R_MOD))
                mstore(computed_quotient, addmod(mload(computed_quotient), mload(s1), R_MOD))
                mstore(computed_quotient,addmod(mload(computed_quotient), sub(R_MOD, mload(add(state, STATE_ALPHA_SQUARE_LAGRANGE_0))), R_MOD))
                mstore(s2,mulmod(calldataload(add(aproof, PROOF_QUOTIENT_POLYNOMIAL_AT_ZETA)),mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE)),R_MOD))

                mstore(add(state, STATE_SUCCESS), eq(mload(computed_quotient), mload(s2)))
            }

            // BEGINNING utils math functions -------------------------------------------------

            /// @param dst pointer storing the result
            /// @param p pointer to the first point
            /// @param q pointer to the second point
            /// @param mPtr pointer to free memory
            function point_add(dst, p, q, mPtr) {
                let state := mload(0x40)
                mstore(mPtr, mload(p))
                mstore(add(mPtr, 0x20), mload(add(p, 0x20)))
                mstore(add(mPtr, 0x40), mload(q))
                mstore(add(mPtr, 0x60), mload(add(q, 0x20)))
                let l_success := staticcall(gas(),6,mPtr,0x80,dst,0x40)
                if iszero(l_success) {
                    error_ec_op()
                }
            }

            /// @param dst pointer storing the result
            /// @param p pointer to the first point (calldata)
            /// @param q pointer to the second point (calladata)
            /// @param mPtr pointer to free memory
            function point_add_calldata(dst, p, q, mPtr) {
                let state := mload(0x40)
                mstore(mPtr, mload(p))
                mstore(add(mPtr, 0x20), mload(add(p, 0x20)))
                mstore(add(mPtr, 0x40), calldataload(q))
                mstore(add(mPtr, 0x60), calldataload(add(q, 0x20)))
                let l_success := staticcall(gas(), 6, mPtr, 0x80, dst, 0x40)
                if iszero(l_success) {
                    error_ec_op()
                }
            }

            /// @parma dst pointer storing the result
            /// @param src pointer to a point on Bn254(𝔽_p)
            /// @param s scalar
            /// @param mPtr free memory
            function point_mul(dst,src,s, mPtr) {
                let state := mload(0x40)
                mstore(mPtr,mload(src))
                mstore(add(mPtr,0x20),mload(add(src,0x20)))
                mstore(add(mPtr,0x40),s)
                let l_success := staticcall(gas(),7,mPtr,0x60,dst,0x40)
                if iszero(l_success) {
                    error_ec_op()
                }
            }

            /// @parma dst pointer storing the result
            /// @param src pointer to a point on Bn254(𝔽_p) on calldata
            /// @param s scalar
            /// @param mPtr free memory
            function point_mul_calldata(dst, src, s, mPtr) {
                let state := mload(0x40)
                mstore(mPtr, calldataload(src))
                mstore(add(mPtr, 0x20), calldataload(add(src, 0x20)))
                mstore(add(mPtr, 0x40), s)
                let l_success := staticcall(gas(), 7, mPtr, 0x60, dst, 0x40)
                if iszero(l_success) {
                    error_ec_op()
                }
            }

            /// @notice dst <- dst + [s]src (Elliptic curve)
            /// @param dst pointer accumulator point storing the result
            /// @param src pointer to the point to multiply and add
            /// @param s scalar
            /// @param mPtr free memory
            function point_acc_mul(dst,src,s, mPtr) {
                let state := mload(0x40)
                mstore(mPtr,mload(src))
                mstore(add(mPtr,0x20),mload(add(src,0x20)))
                mstore(add(mPtr,0x40),s)
                let l_success := staticcall(gas(),7,mPtr,0x60,mPtr,0x40)
                mstore(add(mPtr,0x40),mload(dst))
                mstore(add(mPtr,0x60),mload(add(dst,0x20)))
                l_success := and(l_success, staticcall(gas(),6,mPtr,0x80,dst, 0x40))
                if iszero(l_success) {
                    error_ec_op()
                }
            }

            /// @notice dst <- dst + [s]src (Elliptic curve)
            /// @param dst pointer accumulator point storing the result
            /// @param src pointer to the point to multiply and add (on calldata)
            /// @param s scalar
            /// @mPtr free memory
            function point_acc_mul_calldata(dst, src, s, mPtr) {
                let state := mload(0x40)
                mstore(mPtr, calldataload(src))
                mstore(add(mPtr, 0x20), calldataload(add(src, 0x20)))
                mstore(add(mPtr, 0x40), s)
                let l_success := staticcall(gas(), 7, mPtr, 0x60, mPtr, 0x40)
                mstore(add(mPtr, 0x40), mload(dst))
                mstore(add(mPtr, 0x60), mload(add(dst, 0x20)))
                l_success := and(l_success, staticcall(gas(), 6, mPtr, 0x80, dst, 0x40))
                if iszero(l_success) {
                    error_ec_op()
                }
            }

            /// @notice dst <- dst + src*s (Fr) dst,src are addresses, s is a value
            /// @param dst pointer storing the result
            /// @param src pointer to the scalar to multiply and add (on calldata)
            /// @param s scalar
            function fr_acc_mul_calldata(dst, src, s) {
                let tmp :=  mulmod(calldataload(src), s, R_MOD)
                mstore(dst, addmod(mload(dst), tmp, R_MOD))
            }

            /// @param x element to exponentiate
            /// @param e exponent
            /// @param mPtr free memory
            /// @return res x ** e mod r
            function pow(x, e, mPtr)->res {
                mstore(mPtr, 0x20)
                mstore(add(mPtr, 0x20), 0x20)
                mstore(add(mPtr, 0x40), 0x20)
                mstore(add(mPtr, 0x60), x)
                mstore(add(mPtr, 0x80), e)
                mstore(add(mPtr, 0xa0), R_MOD)
                let check_staticcall := staticcall(gas(),0x05,mPtr,0xc0,mPtr,0x20)
                if eq(check_staticcall, 0) {
                    error_verify()
                }
                res := mload(mPtr)
            }
        }
    }
}
