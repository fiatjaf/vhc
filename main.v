import x.json2
import strconv
import fiatjaf.vlightning

fn main() {
	mut plugin := vlightning.Plugin{
		name: 'vhc'
		version: '0.1'
		hooks: map{
			'custommsg':     handle_custommsg
			'htlc_accepted': handle_htlc_accepted
		}
	}
	plugin.initialize()
}

fn handle_custommsg(p vlightning.Plugin, jsonparams json2.Any) ?json2.Any {
	params := jsonparams.as_map()
	peer := params['peer_id'].str()
	payload := params['payload'].str()
	typ := strconv.parse_int(payload[0..4], 16, 64)
	message := hex_to_bytes(payload[4..])

	dump(peer)
	dump(typ)
	dump(message.hex())
	message_handling: for {
		match typ {
			type_invoke_hosted_channel {
				mut t := InvokeHostedChannel{}
				p.log('got invoke_hosted_channel from $peer')

				t.decode(message) or {
					p.log('got broken invoke_hosted_channel: $err')
					break message_handling
				}

				if channel := get_channel(peer) {
					// a hosted channel with this peer already exists
					mut last := LastCrossSignedState{}
					last.decode(hex_to_bytes(channel.last_cross_signed_state)) or {
						p.log('we had an invalid cross_signed_state stored: $err')
						break message_handling
					}

					p.client.call('dev-sendcustommsg', peer, last.message()) or {
						p.log('failed sendcustommsg last_cross_signed_state: $err')
					}
				} else {
					// create a new hosted channel
					init := default_init
					p.client.call('dev-sendcustommsg', peer, init.message()) or {
						p.log('failed sendcustommsg init_hosted_channel: $err')
					}
				}
			}
			type_state_update {
				mut t := StateUpdate{}
				p.log('got state_update from $peer')

				t.decode(message) or {
					p.log('got broken state_update: $err')
					break message_handling
				}

				// TODO
				// check sig
				// check blockday
				// store last_cross_signed_state

				state := get_current_channel_state(p, peer) or {
					p.log('failed to get current state: $err')
					break message_handling
				}

				node_key := get_node_key(p) or {
					p.log("failed to get node key, can't sign state updates: $err")
					break message_handling
				}

				signature := sign_state(reversed_state(state), node_key) or {
					p.log('failed to sign reversed state: $err')
					break message_handling
				}

				mut signature64 := [64]byte{}
				for i in 0 .. 64 {
					signature64[i] = signature[i]
				}

				state_update := StateUpdate{
					block_day: state.block_day
					local_updates: state.local_updates
					remote_updates: state.remote_updates
					local_sig_of_remote: signature64
				}

				p.client.call('dev-sendcustommsg', peer, state_update.message()) or {
					p.log('failed sendcustommsg state_update: $err')
				}
			}
			type_last_cross_signed_state {
				// this is just the client acknowledging our state. do nothing for now.
			}
			type_state_override {
				// TODO I don't understand this
			}
			type_update_add_htlc {}
			type_update_fulfill_htlc {}
			type_update_fail_htlc {}
			type_update_fail_malformed_htlc {}
			type_error {}
			else {}
		}

		break
	}

	return map{
		'result': json2.Any('continue')
	}
}

fn handle_htlc_accepted(p vlightning.Plugin, jsonparams json2.Any) ?json2.Any {
	return map{
		'result': json2.Any('continue')
	}
}
