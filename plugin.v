import os
import x.json2

struct Plugin {
mut:
	lightning_dir string
	rpc_file      string
	network       string
	options       map[string]json2.Any

	client        Client
	hooks         map[string]HookHandler = map{}
	subscriptions map[string]SubscriptionHandler = map{}
}

type HookHandler = fn (Plugin, json2.Any) ?string
type SubscriptionHandler = fn (Plugin, json2.Any)

fn (mut p Plugin) initialize() {
	eprintln('running vhc plugin')

	for {
		line := os.get_line()

		raw_message := json2.raw_decode(line) or { continue }
		message := raw_message.as_map()
		dump(message)
		mut response := map{
			'jsonrpc': json2.Any('2.0')
			'version': message['version'] or { 0 }
			'id':      message['id']
		}
		match message['method'].str() {
			'getmanifest' {
				mut hooks := []json2.Any{len: p.hooks.len, init: json2.Any('')}
				mut i := 0
				for k, _ in p.hooks {
					hooks[i] = json2.Any(map{
						'name': json2.Any(k)
					})
					i += 1
				}

				mut subscriptions := []json2.Any{cap: p.subscriptions.len}
				i = 0
				for k, _ in p.subscriptions {
					subscriptions[i] = json2.Any([json2.Any(k)])
					i += 1
				}

				mut result := map[string]json2.Any{}
				result['options'] = json2.Any([]json2.Any{cap: 0})
				result['rpcmethods'] = json2.Any([
					json2.Any(map{
						'name':             json2.Any('sendhconion')
						'usage':            json2.Any('')
						'description':      json2.Any('sends an onion')
						'long_description': json2.Any('')
					}),
				])
				result['hooks'] = hooks
				result['subscriptions'] = subscriptions
				result['features'] = json2.Any('')
				result['dynamic'] = json2.Any(false)

				response['result'] = result
			}
			'init' {
				conf := message['configuration'].as_map()
				p.lightning_dir = conf['lightning-dir'].str()
				p.rpc_file = conf['rpc-file'].str()
				p.network = conf['network'].str()

				p.client = Client{p.rpc_file}
				p.options = message['options'].as_map()
			}
			else {
				method := message['method'].str()
				for {
					if method in p.hooks {
						hook := p.hooks[method]
						if result := hook(p, message) {
							response['result'] = result
						} else {
							response['error'] = map{
								'code':    json2.Any(err.code)
								'message': json2.Any(err.msg)
							}
						}
						break
					}

					if method in p.subscriptions {
						subs := p.subscriptions[method]
						subs(p, message)
						break
					}

					break
				}
			}
		}

		dump(response)
		print(response)
		os.flush()
	}
}
