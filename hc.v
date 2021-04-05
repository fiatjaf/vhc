import fiatjaf.vlightning

const (
	default_init = InitHostedChannel{
		max_htlc_value_in_flight_msat: 100000000
		htlc_minimum_msat: 1000
		max_accepted_htlcs: 30
		channel_capacity_msat: 1000000000
		liability_deadline_blockdays: 360
		minimal_onchain_refund_amount_satoshis: 900000
		initial_client_balance_msat: 0
		features: []byte{}
	}
)

struct Channel {
	peer_id                 string
	init_hosted_channel     string
	last_cross_signed_state string
}

fn get_channel(peer_id string) ?Channel {
	return none
}

struct Update {
	peer_id         string
	is_in           bool
	amount_msat     u64
	update_add_htlc string
}

fn get_pending_updates(peer_id string) ?[]Update {
	return []Update{}
}

fn get_current_channel_state(p vlightning.Plugin, peer_id string) ?LastCrossSignedState {
	blockday := get_blockday(p) ?

	if channel := get_channel(peer_id) {
		// a channel exists with a state
		mut last := LastCrossSignedState{}
		last.decode(hex_to_bytes(channel.last_cross_signed_state)) ?

		// does it have pending updates?
		updates := get_pending_updates(peer_id) ?

		// current state
		for upd in updates {
			mut update_add_htlc := UpdateAddHTLC{}
			update_add_htlc.decode(hex_to_bytes(upd.update_add_htlc)) ?

			match upd.is_in {
				true {
					last.incoming_htlcs << update_add_htlc
				}
				false {
					last.outgoing_htlcs << update_add_htlc
				}
			}
		}

		last.block_day = blockday
		return last
	} else {
		// empty state
		return LastCrossSignedState{
			is_host: true
			init_hosted_channel: default_init
			block_day: blockday
			local_balance_msat: default_init.channel_capacity_msat
			remote_balance_msat: 0
			local_updates: 0
			remote_updates: 0
			incoming_htlcs: []UpdateAddHTLC{}
			outgoing_htlcs: []UpdateAddHTLC{}
		}
	}
}
