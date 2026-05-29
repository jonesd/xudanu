export interface TextDeltaOp {
  type: string;
  count?: number;
  text?: string;
}

export class TextBuffer {
  private text: string;
  private lineOffsets: number[];

  constructor(text: string) {
    this.text = text;
    this.lineOffsets = this.buildLineOffsets(text);
  }

  private buildLineOffsets(text: string): number[] {
    const offsets = [0];
    for (let i = 0; i < text.length; i++) {
      if (text[i] === "\n") {
        offsets.push(i + 1);
      }
    }
    return offsets;
  }

  getText(): string {
    return this.text;
  }

  getLineCount(): number {
    return this.lineOffsets.length;
  }

  getLine(index: number): string {
    if (index < 0 || index >= this.lineOffsets.length) return "";
    const start = this.lineOffsets[index];
    const end =
      index + 1 < this.lineOffsets.length
        ? this.lineOffsets[index + 1] - 1
        : this.text.length;
    return this.text.slice(start, end);
  }

  getCharOffset(line: number): number {
    if (line < 0) return 0;
    if (line >= this.lineOffsets.length) return this.text.length;
    return this.lineOffsets[line];
  }

  getLineForChar(charOffset: number): number {
    if (charOffset <= 0) return 0;
    let lo = 0;
    let hi = this.lineOffsets.length - 1;
    while (lo < hi) {
      const mid = (lo + hi + 1) >> 1;
      if (this.lineOffsets[mid] <= charOffset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  getTextRange(startChar: number, endChar: number): string {
    return this.text.slice(startChar, endChar);
  }

  charCount(): number {
    return this.text.length;
  }

  applyDelta(ops: TextDeltaOp[]): void {
    let result = "";
    let pos = 0;
    for (const op of ops) {
      switch (op.type) {
        case "retain": {
          const count = op.count ?? 0;
          if (pos + count > this.text.length)
            throw new Error(
              `delta retain out of bounds: pos=${pos} count=${count} len=${this.text.length}`,
            );
          result += this.text.slice(pos, pos + count);
          pos += count;
          break;
        }
        case "delete": {
          const count = op.count ?? 0;
          if (pos + count > this.text.length)
            throw new Error(
              `delta delete out of bounds: pos=${pos} count=${count} len=${this.text.length}`,
            );
          pos += count;
          break;
        }
        case "insert": {
          result += op.text ?? "";
          break;
        }
      }
    }
    if (pos !== this.text.length)
      throw new Error(
        `delta did not consume full text: pos=${pos} len=${this.text.length}`,
      );
    this.text = result;
    this.lineOffsets = this.buildLineOffsets(this.text);
  }

  replaceRange(startChar: number, endChar: number, newText: string): void {
    this.text = this.text.slice(0, startChar) + newText + this.text.slice(endChar);
    this.lineOffsets = this.buildLineOffsets(this.text);
  }

  getLinesRange(startLine: number, endLine: number): string {
    const start = this.getCharOffset(startLine);
    const end = this.getCharOffset(endLine);
    return this.text.slice(start, end);
  }

  search(query: string, caseSensitive = false): SearchMatch[] {
    if (!query) return [];
    const results: SearchMatch[] = [];
    const text = caseSensitive ? this.text : this.text.toLowerCase();
    const q = caseSensitive ? query : query.toLowerCase();
    let pos = 0;
    while (pos < text.length) {
      const idx = text.indexOf(q, pos);
      if (idx === -1) break;
      results.push({ start: idx, end: idx + q.length });
      pos = idx + 1;
    }
    return results;
  }

  extractOutline(): OutlineEntry[] {
    const entries: OutlineEntry[] = [];
    const lineCount = this.getLineCount();
    for (let i = 0; i < lineCount; i++) {
      const line = this.getLine(i);
      const trimmed = line.trimStart();
      if (!trimmed) continue;

      let level = 0;
      let text = "";
      const hashMatch = trimmed.match(/^(#{1,6})\s+(.+)/);
      if (hashMatch) {
        level = hashMatch[1].length;
        text = hashMatch[2].trim();
      } else {
        const chapterMatch = trimmed.match(/^(chapter|part|section)\s+(\d+[\.:]?\s*.+)/i);
        if (chapterMatch) {
          const keyword = chapterMatch[1].toLowerCase();
          level = keyword === "part" ? 1 : keyword === "chapter" ? 2 : 3;
          text = trimmed;
        }
      }

      if (level > 0 && text) {
        entries.push({
          level,
          text,
          line: i,
          charOffset: this.getCharOffset(i),
        });
      }
    }
    return entries;
  }
}

export interface SearchMatch {
  start: number;
  end: number;
}

export interface OutlineEntry {
  level: number;
  text: string;
  line: number;
  charOffset: number;
}
