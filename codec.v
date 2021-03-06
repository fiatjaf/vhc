const (
	type_invoke_hosted_channel            = i64(65535)
	type_init_hosted_channel              = i64(65533)
	type_last_cross_signed_state          = i64(65531)
	type_state_update                     = i64(65529)
	type_state_override                   = i64(65527)

	type_hosted_channel_branding          = i64(65525)
	type_refund_pending                   = i64(65523)
	type_announcement_signature           = i64(65521)
	type_resize_channel                   = i64(65519)
	type_query_public_hosted_channels     = i64(65517)
	type_reply_public_hosted_channels_end = i64(65515)

	type_announce_gossip                  = i64(65513)
	type_announce_sync                    = i64(65511)
	type_update_gossip                    = i64(65509)
	type_update_sync                      = i64(65507)

	type_update_add_htlc                  = i64(65505)
	type_update_fulfill_htlc              = i64(65503)
	type_update_fail_htlc                 = i64(65501)
	type_update_fail_malformed_htlc       = i64(65499)
	type_error                            = i64(65497)
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

fn (t InitHostedChannel) message() string {
	return type_init_hosted_channel.hex() + t.encode().hex()
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
		buf: []byte{cap: 8 + 8 + 4 + 8 + 4 + 8 + 8}
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
	is_host               bool
	refund_script_pub_key []byte
	init_hosted_channel   InitHostedChannel
	block_day             u32
	local_balance_msat    u64
	remote_balance_msat   u64
	local_updates         u32
	remote_updates        u32
	incoming_htlcs        []UpdateAddHTLC
	outgoing_htlcs        []UpdateAddHTLC
	remote_sig_of_local   [64]byte
	local_sig_of_remote   [64]byte
}

fn (t LastCrossSignedState) message() string {
	return type_last_cross_signed_state.hex() + t.encode().hex()
}

fn (mut t LastCrossSignedState) decode(b []byte) ?int {
	mut r := Reader{
		buf: b
	}

	t.is_host = r.read_bool() ?
	t.refund_script_pub_key = r.read_dynamic() ?
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

fn (t LastCrossSignedState) encode() []byte {
	mut w := Writer{
		buf: []byte{cap: 3000}
	}

	w.write_bool(t.is_host)
	w.write_dynamic(t.refund_script_pub_key)
	w.write_encodable(t.init_hosted_channel)
	w.write_u32(t.block_day)
	w.write_u64(t.local_balance_msat)
	w.write_u64(t.remote_balance_msat)
	w.write_u32(t.local_updates)
	w.write_u32(t.remote_updates)

	w.write_u16(u16(t.incoming_htlcs.len))
	for _, incoming_htlc in t.incoming_htlcs {
		w.write_encodable(incoming_htlc)
	}
	w.write_u16(u16(t.outgoing_htlcs.len))
	for _, outgoing_htlc in t.outgoing_htlcs {
		w.write_encodable(outgoing_htlc)
	}

	w.write_64(t.remote_sig_of_local)
	w.write_64(t.local_sig_of_remote)

	return w.buf
}

struct StateUpdate {
mut:
	block_day           u32
	local_updates       u32
	remote_updates      u32
	local_sig_of_remote [64]byte
}

fn (t StateUpdate) message() string {
	return type_state_update.hex() + t.encode().hex()
}

fn (mut t StateUpdate) decode(b []byte) ?int {
	mut r := Reader{
		buf: b
	}

	t.block_day = r.read_u32() ?
	t.local_updates = r.read_u32() ?
	t.remote_updates = r.read_u32() ?
	r.read_64(mut t.local_sig_of_remote) ?

	return r.pos
}

fn (t StateUpdate) encode() []byte {
	mut w := Writer{
		buf: []byte{cap: 4 + 4 + 4 + 64}
	}

	w.write_u32(t.block_day)
	w.write_u32(t.local_updates)
	w.write_u32(t.remote_updates)
	w.write_64(t.local_sig_of_remote)

	return w.buf
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

fn (t UpdateAddHTLC) message() string {
	return type_update_add_htlc.hex() + t.encode().hex()
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

fn (t UpdateAddHTLC) encode() []byte {
	mut w := Writer{
		buf: []byte{cap: 4 + 8 + 8 + 32 + 4 + 1366}
	}

	w.write_32(t.channel_id)
	w.write_u64(t.id)
	w.write_u64(t.amount_msat)
	w.write_32(t.payment_hash)
	w.write_u32(t.cltv_expiry)
	w.write_1366(t.onion_routing_packet)

	return w.buf
}
