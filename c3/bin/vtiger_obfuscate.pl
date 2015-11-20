($res = encode_base64(join('', map {join('', map {chr(ord($_) ^ 0b11111111)} split('', unpack "B8", (pack "S", ord($_))))} split('', $ARGV[0])), '')) =~ tr[+/=][\-_.]; print $res
