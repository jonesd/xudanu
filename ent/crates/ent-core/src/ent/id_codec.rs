use crate::ent::branch::BranchId;
use crate::ent::content::{AnnotationId, NodeId, SpanId};
use crate::ent::trace::TracePosition;

pub fn encode_trace(pos: TracePosition) -> String {
    format!("t-{}-{}", pos.branch().as_u64(), pos.position())
}

pub fn decode_trace(s: &str) -> Option<TracePosition> {
    let rest = s.strip_prefix("t-")?;
    let (branch_str, pos_str) = rest.split_once('-')?;
    let branch: u64 = branch_str.parse().ok()?;
    let position: u32 = pos_str.parse().ok()?;
    Some(TracePosition::new(BranchId::from_u64(branch), position))
}

pub fn encode_node(id: NodeId) -> String {
    format!("node-{}", id.as_u64())
}

pub fn encode_span(id: SpanId) -> String {
    format!("span-{}", id.as_u64())
}

pub fn encode_annotation(id: AnnotationId) -> String {
    format!("ann-{}", id.as_u64())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip_trace_position() {
        let pos = TracePosition::new(BranchId::from_u64(42), 7);
        let encoded = encode_trace(pos);
        assert_eq!(encoded, "t-42-7");
        let decoded = decode_trace(&encoded).unwrap();
        assert_eq!(decoded, pos);
    }

    #[test]
    fn decode_trace_rejects_invalid() {
        assert!(decode_trace("garbage").is_none());
        assert!(decode_trace("t-").is_none());
        assert!(decode_trace("t-1").is_none());
        assert!(decode_trace("t--1").is_none());
        assert!(decode_trace("t-abc-1").is_none());
        assert!(decode_trace("t-1-abc").is_none());
    }

    #[test]
    fn encode_entity_ids() {
        assert_eq!(encode_node(NodeId::new(1)), "node-1");
        assert_eq!(encode_span(SpanId::new(42)), "span-42");
        assert_eq!(encode_annotation(AnnotationId::new(99)), "ann-99");
    }
}
