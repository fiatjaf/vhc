import x.json2
import strconv

fn main() {
	mut plugin := Plugin{
		hooks: map{
			'custommsg': handle_custommsg
		}
	}
	plugin.initialize()
}

fn handle_custommsg(p Plugin, jsonparams json2.Any) ?json2.Any {
	params := jsonparams.as_map()
	peer := params['peer_id'].str()
	payload := params['payload'].str()
	typ := strconv.parse_int(payload[0..4], 16, 64)
	message := hex_to_bytes(payload[4..])

	dump(peer)
	dump(typ)
	dump(message.hex())
	for {
		match typ {
			type_invoke_hosted_channel {
				mut t := InvokeHostedChannel{}

				t.decode(message) or {
					eprintln('got broken invoke_hosted_channel: $err')
					break
				}

				if channel := get_channel(peer) {
					// a hosted channel with this peer already exists
				} else {
					// create a new hosted channel
					rt := InitHostedChannel{
						max_htlc_value_in_flight_msat: 100000000
						htlc_minimum_msat: 1000
						max_accepted_htlcs: 30
						channel_capacity_msat: 1000000000
						liability_deadline_blockdays: 360
						minimal_onchain_refund_amount_satoshis: 900000
						initial_client_balance_msat: 0
						features: []byte{}
					}
					init := type_init_hosted_channel.hex() + rt.encode().hex()
					p.client.call('dev-sendcustommsg', peer, init) or {
						eprintln('failed to call dev-sendcustommsg in response to invoke_hosted_channel: $err')
					}
				}
			}
			else {}
		}

		break
	}

	return map{
		'result': json2.Any('continue')
	}
}
