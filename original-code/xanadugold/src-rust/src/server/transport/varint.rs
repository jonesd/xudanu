pub fn encode_varint(value: u64, buf: &mut Vec<u8>) {
    let mut v = value;
    loop {
        let mut byte = (v & 0x7F) as u8;
        v >>= 7;
        if v != 0 {
            byte |= 0x80;
        }
        buf.push(byte);
        if v == 0 {
            break;
        }
    }
}

pub fn decode_varint(data: &[u8]) -> Result<(u64, usize), VarintError> {
    let mut value: u64 = 0;
    let mut shift: u32 = 0;
    for (i, &byte) in data.iter().enumerate() {
        if shift >= 70 {
            return Err(VarintError::Overflow);
        }
        value |= ((byte & 0x7F) as u64) << shift;
        if byte & 0x80 == 0 {
            return Ok((value, i + 1));
        }
        shift += 7;
    }
    Err(VarintError::Truncated)
}

#[derive(Debug, Clone, PartialEq)]
pub enum VarintError {
    Truncated,
    Overflow,
}

impl std::fmt::Display for VarintError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VarintError::Truncated => write!(f, "varint truncated"),
            VarintError::Overflow => write!(f, "varint overflow"),
        }
    }
}

impl std::error::Error for VarintError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encode_zero() {
        let mut buf = Vec::new();
        encode_varint(0, &mut buf);
        assert_eq!(buf, vec![0x00]);
        let (v, n) = decode_varint(&buf).unwrap();
        assert_eq!(v, 0);
        assert_eq!(n, 1);
    }

    #[test]
    fn encode_small() {
        let mut buf = Vec::new();
        encode_varint(127, &mut buf);
        assert_eq!(buf, vec![0x7F]);
        let (v, n) = decode_varint(&buf).unwrap();
        assert_eq!(v, 127);
        assert_eq!(n, 1);
    }

    #[test]
    fn encode_128() {
        let mut buf = Vec::new();
        encode_varint(128, &mut buf);
        assert_eq!(buf, vec![0x80, 0x01]);
        let (v, n) = decode_varint(&buf).unwrap();
        assert_eq!(v, 128);
        assert_eq!(n, 2);
    }

    #[test]
    fn encode_large() {
        let mut buf = Vec::new();
        encode_varint(300, &mut buf);
        let (v, n) = decode_varint(&buf).unwrap();
        assert_eq!(v, 300);
        assert_eq!(n, 2);
    }

    #[test]
    fn encode_u64_max() {
        let mut buf = Vec::new();
        encode_varint(u64::MAX, &mut buf);
        let (v, n) = decode_varint(&buf).unwrap();
        assert_eq!(v, u64::MAX);
        assert_eq!(n, 10);
    }

    #[test]
    fn decode_truncated() {
        let data = vec![0x80];
        let result = decode_varint(&data);
        assert_eq!(result.unwrap_err(), VarintError::Truncated);
    }

    #[test]
    fn round_trip_values() {
        let values: Vec<u64> = vec![
            0,
            1,
            127,
            128,
            255,
            256,
            16383,
            16384,
            1_000_000,
            u32::MAX as u64,
            u64::MAX,
        ];
        for val in values {
            let mut buf = Vec::new();
            encode_varint(val, &mut buf);
            let (decoded, _) = decode_varint(&buf).unwrap();
            assert_eq!(decoded, val, "round trip failed for {}", val);
        }
    }
}
