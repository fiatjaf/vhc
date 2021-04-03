import os
import crypto.hmac
import crypto.sha256
import fiatjaf.vlightning

fn get_node_key(p vlightning.Plugin) ?[32]byte {
	hsm_secret := os.read_bytes(p.lightning_dir + '/hsm_secret') or {
		return error('failed to read ${p.lightning_dir + '/hsm_secret'}: $err')
	}

	// fake hkdf with fixed params
	salt := [byte(0)]
	info := 'nodeid'.bytes()
	prk := hmac.new(salt, hsm_secret, sha256.sum256, 32)
	mut output_block := []byte{}

	mut buf := []byte{}
	buf << output_block
	buf << info
	buf << byte(0)
	output := hmac.new(prk, buf, sha256.sum256, 32)

	mut res := [32]byte{}
	for i := 0; i < 32; i++ {
		res[i] = output[i]
	}
	return res
}

fn reversed_state(t LastCrossSignedState) LastCrossSignedState {
	return {
		...t
		local_balance_msat: t.remote_balance_msat
		remote_balance_msat: t.local_balance_msat
		local_updates: t.remote_updates
		remote_updates: t.local_updates
		incoming_htlcs: t.outgoing_htlcs
		outgoing_htlcs: t.incoming_htlcs
	}
}

fn sign_state(t LastCrossSignedState, node_key [32]byte) ?[]byte {
	cap_needed := (t.refund_script_pub_key.len + 4 * 3 + 8 * 5 + (4 + 8 + 8 + 32 + 4 +
		1366) * (t.incoming_htlcs.len + t.outgoing_htlcs.len))

	mut w := Writer{
		buf: []byte{cap: cap_needed}
	}

	w.buf << t.refund_script_pub_key
	w.write_little_u16(t.init_hosted_channel.liability_deadline_blockdays)
	w.write_little_u64(t.init_hosted_channel.minimal_onchain_refund_amount_satoshis)
	w.write_little_u64(t.init_hosted_channel.channel_capacity_msat)
	w.write_little_u64(t.init_hosted_channel.initial_client_balance_msat)
	w.write_little_u32(t.block_day)
	w.write_little_u64(t.local_balance_msat)
	w.write_little_u64(t.remote_balance_msat)
	w.write_little_u32(t.local_updates)
	w.write_little_u32(t.remote_updates)

	for _, incoming_htlc in t.incoming_htlcs {
		w.write_encodable(incoming_htlc)
	}
	for _, outgoing_htlc in t.outgoing_htlcs {
		w.write_encodable(outgoing_htlc)
	}

	return sign(sha256.sum256(w.buf), node_key)
}
