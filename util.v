import strconv
import encoding.binary

fn hex_to_bytes(data string) []byte {
	mut nums := []byte{}
	for i := 0; i < data.len; i += 2 {
		end := if i + 2 > data.len { data.len } else { i + 2 }
		num := strconv.parse_uint(data[i..end], 16, 8)
		nums << byte(num)
	}
	return nums
}

struct Reader {
	buf []byte
mut:
	pos u16
}

fn (mut r Reader) read_32() [32]byte {
	mut res := [32]byte{}
	next := r.pos + 32
	for i, b in r.buf[r.pos..next] {
		res[i] = b
	}
	r.pos = next
	return res
}

fn (mut r Reader) read_u16() u16 {
	next := r.pos + 2
	defer {
		r.pos = next
	}
	return binary.big_endian_u16(r.buf[r.pos..next])
}

fn (mut r Reader) read_u64() u64 {
	next := r.pos + 4
	defer {
		r.pos = next
	}
	return binary.big_endian_u64(r.buf[r.pos..next])
}

fn (mut r Reader) read_dynamic() []byte {
	size := r.read_u16()
	next := r.pos + size
	defer {
		r.pos = next
	}
	return r.buf[r.pos..next]
}

struct Writer {
mut:
	buf []byte
	pos int
}

fn (mut w Writer) write_32(data [32]byte) {
	for _, b in data {
		w.buf[w.pos] = b
		w.pos = w.pos + 1
	}
}

fn (mut w Writer) write_u16(data u16) {
	next := w.pos + 2
	binary.big_endian_put_u16(mut w.buf[w.pos..next], data)
	w.pos = next
}

fn (mut w Writer) write_u64(data u64) {
	next := w.pos + 4
	binary.big_endian_put_u64(mut w.buf[w.pos..next], data)
	w.pos = next
}

fn (mut w Writer) write_dynamic(data []byte) {
	w.write_u16(u16(data.len))
	next := w.pos + data.len
	w.buf[w.pos..next] = data
	w.pos = next
}
