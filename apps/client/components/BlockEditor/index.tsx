// import { useCreateBlockNote } from "@blocknote/react";
// import { BlockNoteView } from "@blocknote/mantine";


// import "@blocknote/core/fonts/inter.css";
// import "@blocknote/mantine/style.css";

export default function BlockNoteEditor({ setIssue }) {
  // const editor = useCreateBlockNote();

  return (
    <div className="p-4 border rounded bg-gray-50">
      BlockEditor Placeholder (Disabled for build fix)
    </div>
    /*
    <BlockNoteView
      //@ts-ignore
      editor={editor}
      sideMenu={false}
      theme="light"
      onChange={() => {
        setIssue(editor.document);
      }}
    />
    */
  );
}
