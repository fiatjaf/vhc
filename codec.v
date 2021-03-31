const (
	type_invoke_hosted_channel   = i64(65535)
	type_init_hosted_channel     = i64(65533)
	type_last_cross_signed_state = i64(65531)
	type_state_update            = i64(65529)
	type_state_override          = i64(65527)
)

struct InvokeHostedChannel {
mut:
	chainhash             [32]byte
	refund_script_pub_key []byte
	secret                []byte
}

fn (mut t InvokeHostedChannel) decode(b []byte) {
	mut r := Reader{
		buf: b
	}
	t.chainhash = r.read_32()
	t.refund_script_pub_key = r.read_dynamic()
	t.secret = r.read_dynamic()
}

struct InitHostedChannel {
mut:
	max_htlc_value_in_flight_msat          u64
	htlc_minimum_msat                      u64
	max_accepted_htlcs                     u16
	channel_capacity_msat                  u64
	liability_deadline_blockdays           u16
	minimal_onchain_refund_amount_satoshis u64
	initial_client_balance_msat            u64
	features                               []byte
}

fn (t InitHostedChannel) encode() []byte {
	mut w := Writer{
		buf: []byte{}
	}

	w.write_u64(t.max_htlc_value_in_flight_msat)
	w.write_u64(t.htlc_minimum_msat)
	w.write_u16(t.max_accepted_htlcs)
	w.write_u64(t.channel_capacity_msat)
	w.write_u16(t.liability_deadline_blockdays)
	w.write_u64(t.minimal_onchain_refund_amount_satoshis)
	w.write_u64(t.initial_client_balance_msat)
	w.write_dynamic(t.features)

	return w.buf
}
