const (
	type_invoke_hosted_channel   = i64(65535)
	type_init_hosted_channel     = i64(65533)
	type_last_cross_signed_state = i64(65531)
	type_state_update            = i64(65529)
	type_state_override          = i64(65527)
)

interface HostedChannelMessageDecodable {
	decode([]byte) ?int
}

interface HostedChannelMessageEncodable {
	encode() []byte
}

struct InvokeHostedChannel {
mut:
	chainhash             [32]byte
	refund_script_pub_key []byte
	secret                []byte
}

fn (mut t InvokeHostedChannel) decode(b []byte) ?int {
	mut r := Reader{
		buf: b
	}

	r.read_32(mut t.chainhash) ?
	t.refund_script_pub_key = r.read_dynamic() ?
	t.secret = r.read_dynamic() ?

	return r.pos
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

fn (mut t InitHostedChannel) decode(b []byte) ?int {
	mut r := Reader{
		buf: b
	}

	t.max_htlc_value_in_flight_msat
	r.read_u64() ?
	t.htlc_minimum_msat = r.read_u64() ?
	t.max_accepted_htlcs = r.read_u16() ?
	t.channel_capacity_msat = r.read_u64() ?
	t.liability_deadline_blockdays = r.read_u16() ?
	t.minimal_onchain_refund_amount_satoshis = r.read_u64() ?
	t.initial_client_balance_msat = r.read_u64() ?
	t.features = r.read_dynamic() ?

	return r.pos
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

struct LastCrossSignedState {
mut:
	last_refund_scriptpubkey []byte
	init_hosted_channel      InitHostedChannel
	block_day                u32
	local_balance_msat       u64
	remote_balance_msat      u64
	local_updates            u32
	remote_updates           u32
	incoming_htlcs           []UpdateAddHTLC
	outgoing_htlcs           []UpdateAddHTLC
	remote_sig_of_local      [64]byte
	local_sig_of_remote      [64]byte
}

fn (mut t LastCrossSignedState) decode(b []byte) ?int {
	mut r := Reader{
		buf: b
	}

	t.last_refund_scriptpubkey = r.read_dynamic() ?
	r.read_decodable(mut t.init_hosted_channel) ?
	t.block_day = r.read_u32() ?
	t.local_balance_msat = r.read_u64() ?
	t.remote_balance_msat = r.read_u64() ?
	t.local_updates = r.read_u32() ?
	t.remote_updates = r.read_u32() ?

	num_incoming := r.read_u16() ?
	t.incoming_htlcs = []UpdateAddHTLC{len: int(num_incoming)}
	for i := 0; i < num_incoming; i += 1 {
		r.read_decodable(mut t.incoming_htlcs[i]) ?
	}
	num_outgoing := r.read_u16() ?
	t.outgoing_htlcs = []UpdateAddHTLC{len: int(num_outgoing)}
	for i := 0; i < num_outgoing; i += 1 {
		r.read_decodable(mut t.outgoing_htlcs[i]) ?
	}

	r.read_64(mut t.remote_sig_of_local) ?
	r.read_64(mut t.local_sig_of_remote) ?

	return r.pos
}

struct UpdateAddHTLC {
mut:
	channel_id           [32]byte
	id                   u64
	amount_msat          u64
	payment_hash         [32]byte
	cltv_expiry          u32
	onion_routing_packet [1366]byte
}

fn (mut t UpdateAddHTLC) decode(b []byte) ?int {
	mut r := Reader{
		buf: b
	}

	r.read_32(mut t.channel_id) ?
	t.id = r.read_u64() ?
	t.amount_msat = r.read_u64() ?
	r.read_32(mut t.payment_hash) ?
	t.cltv_expiry = r.read_u32() ?
	r.read_1366(mut t.onion_routing_packet) ?

	return r.pos
}
