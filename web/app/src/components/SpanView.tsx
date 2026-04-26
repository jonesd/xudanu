import type { ApiText } from "../types/api";

export function SpanView({ text }: { text: ApiText }) {
  if (text.type === "single") {
    return <span className="span-text">{text.value}</span>;
  }

  return (
    <span className="span-alternatives">
      {text.values.map((v, i) => (
        <span key={i} className="alternative">
          {i > 0 && <span className="alternative-divider"> | </span>}
          {v}
        </span>
      ))}
    </span>
  );
}
