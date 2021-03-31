import x.json2
import net.unix

struct Client {
	path string
}

fn (c Client) call(method string, params ...json2.Any) ?json2.Any {
	mut stream := unix.connect_stream(c.path) or {
		panic("can't use client because $c.path is not usable: $err.msg")
	}
	defer {
		stream.close() or { panic("can't close unix socket! $err.msg") }
	}

	command := json2.Any(map{
		'jsonrpc': json2.Any('')
		'version': json2.Any(2)
		'id':      json2.Any(0)
		'method':  json2.Any(method)
		'params':  params
	})
	stream.write_string(command.json_str()) or {
		panic('failed to write to unix socket $c.path: $err.msg')
	}

	mut response := []byte{}
	stream.read(mut response) ?

	ival := json2.raw_decode(response.str()) ?
	val := ival.as_map()
	if 'error' in val {
		return error(val['error'].as_map()['message'].str())
	}

	return val['result']
}
