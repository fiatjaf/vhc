#flag -l secp256k1

#include "secp256k1.h"
#include "secp256k1_recovery.h"

fn C.secp256k1_context_create(u32) &C.secp256k1_context
fn C.secp256k1_context_destroy(&C.secp256k1_context)
fn C.secp256k1_ecdsa_sign_recoverable(&C.secp256k1_context, &C.secp256k1_ecdsa_recoverable_signature, &char, &char, voidptr, voidptr) int
fn C.secp256k1_ecdsa_recoverable_signature_serialize_compact(&C.secp256k1_context, &byte, &int, &C.secp256k1_ecdsa_recoverable_signature) int

fn sign(sighash []byte, key []byte) ?[]byte {
	unsafe {
		ctx := C.secp256k1_context_create(C.SECP256K1_CONTEXT_SIGN)
		defer {
			C.secp256k1_context_destroy(ctx)
		}

		rawsig := C.secp256k1_ecdsa_recoverable_signature([]C.byte{cap: 65})

		dump(sighash)
		dump(key)
		if 0 == C.secp256k1_ecdsa_sign_recoverable(ctx, &rawsig, &sighash[0], &key[0],
			voidptr(0), voidptr(0)) {
			return error('failed to sign')
		}

		mut serialized := malloc(64) // []C.byte{len: 64}
		mut recid := 0
		if 0 == C.secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, &serialized,
			&recid, &rawsig) {
			return error('failed to serialize signature')
		}

		return serialized.vbytes(64)
	}
}
