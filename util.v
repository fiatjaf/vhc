import strconv

fn hex_to_bytes(data string) []byte {
	mut nums := []byte{}
	for i := 0; i < data.len; i += 2 {
		end := if i + 2 > data.len { data.len } else { i + 2 }
		num := strconv.parse_uint(data[i..end], 16, 8)
		nums << byte(num)
	}
	return nums
}
