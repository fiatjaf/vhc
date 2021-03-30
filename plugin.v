import os
import x.json2

struct Plugin {
mut:
	lightning_dir string
	rpc_file      string
	network       string

	client Client

	options map[string]json2.Any
}

fn (mut p Plugin) initialize() {
	eprintln('running vhc plugin')

	for {
		line := os.get_line()

		raw_message := json2.raw_decode(line) or { continue }

		eprintln("read json '$raw_message'")

		message := raw_message.as_map()
		match message['method'].str() {
			'getmanifest' {
				print(map{
					'jsonrpc': json2.Any('')
					'version': message['version'] or { 0 }
					'id':      message['id']
					'result':  json2.Any(map{
						'options':       json2.Any([]json2.Any{cap: 0})
						'hooks':         json2.Any([
							json2.Any(map{
								'name': json2.Any('custommsg')
							}),
						])
						'rpcmethods':    json2.Any([
							json2.Any(map{
								'name':             json2.Any('sendhconion')
								'usage':            json2.Any('')
								'description':      json2.Any('sends an onion')
								'long_description': json2.Any('')
							}),
						])
						'subscriptions': json2.Any([
							json2.Any('sendpay_success'),
							json2.Any('sendpay_failure'),
						])
						'features':      json2.Any('')
						'dynamic':       json2.Any(false)
					})
				})
				os.flush()
			}
			'init' {
				conf := message['configuration'].as_map()
				p.lightning_dir = conf['lightning-dir'].str()
				p.rpc_file = conf['rpc-file'].str()
				p.network = conf['network'].str()

				p.client = Client{p.rpc_file}
				p.options = message['options'].as_map()

				print(map{
					'jsonrpc': json2.Any('')
					'version': message['version'] or { 0 }
					'id':      message['id']
				})
				os.flush()
			}
			else {
				eprintln(message)
			}
		}
	}
}
