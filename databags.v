import crypto.sha256

fn reversed_state(t LastCrossSignedState) LastCrossSignedState {
	return {
		...t
		local_balance_msat: t.remote_balance_msat
		remote_balance_msat: t.local_balance_msat
		local_updates: t.remote_updates
		remote_updates: t.local_updates
		incoming_htlcs: t.outgoing_htlcs
		outgoing_htlcs: t.incoming_htlcs
		local_sig_of_remote: t.remote_sig_of_local
		remote_sig_of_local: t.local_sig_of_remote
	}
}

fn sign_state(t LastCrossSignedState) []byte {
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

	return sha256.sum256(w.buf)
}
