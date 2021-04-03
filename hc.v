struct Channel {
	peer_id                 string
	init_hosted_channel     string
	last_cross_signed_state string
}

fn get_channel(peer_id string) ?Channel {
	return none
}
