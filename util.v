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

fn (mut r Reader) read_32(mut ba [32]byte) {
	next := r.pos + 32
	for i, b in r.buf[r.pos..next] {
		ba[i] = b
	}
	r.pos = next
}

fn (mut r Reader) read_u16() u16 {
	next := r.pos + 2
	res := binary.big_endian_u16(r.buf[r.pos..next])
	r.pos = next
	return res
}

fn (mut r Reader) read_u64() u64 {
	next := r.pos + 4
	res := binary.big_endian_u64(r.buf[r.pos..next])
	r.pos = next
	return res
}

fn (mut r Reader) read_dynamic() []byte {
	size := r.read_u16()
	next := r.pos + size
	res := r.buf[r.pos..next]
	r.pos = next
	return res
}

struct Writer {
mut:
	buf []byte
}

fn (mut w Writer) write_32(data [32]byte) {
	mut tmp := []byte{len: 32, init: `0`}
	for i, b in data {
		tmp[i] = b
	}
	w.buf << tmp
}

fn (mut w Writer) write_u16(data u16) {
	mut tmp := []byte{len: 2, init: `0`}
	binary.big_endian_put_u16(mut tmp, data)
	w.buf << tmp
}

fn (mut w Writer) write_u64(data u64) {
	mut tmp := []byte{len: 8, init: `0`}
	binary.big_endian_put_u64(mut tmp, data)
	w.buf << tmp
}

fn (mut w Writer) write_dynamic(data []byte) {
	w.write_u16(u16(data.len))
	w.buf << data
}
