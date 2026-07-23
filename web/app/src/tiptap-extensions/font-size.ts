import { TextStyle } from "@tiptap/extension-text-style";

export const FontSize = TextStyle.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      fontSize: {
        default: null,
        parseHTML: (element: HTMLElement) => element.style.fontSize || null,
        renderHTML: (attributes: Record<string, unknown>) => {
          if (!attributes.fontSize) return {};
          return { style: `font-size: ${attributes.fontSize}` };
        },
      },
    };
  },
});

export function applyFontSize(editor: { chain: () => { focus: () => { setMark: (type: string, attrs: Record<string, unknown>) => void } } }, px: number) {
  editor.chain().focus().setMark("textStyle", { fontSize: `${px}px` });
}

export function clearFontSize(editor: { chain: () => { focus: () => { unsetMark: (type: string) => void } } }) {
  editor.chain().focus().unsetMark("textStyle");
}
