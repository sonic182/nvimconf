import { tool } from "@opencode-ai/plugin"
import * as fs from "fs"
import { PDFParse } from "pdf-parse"

export default tool({
  description: "Read pdf files",
  args: {
    path: tool.schema.string().describe("Path to the PDF file to read"),
    from_page: tool.schema.number().describe("Starting page number (1-indexed)").optional(),
    to_page: tool.schema.number().describe("Ending page number (1-indexed, inclusive)").optional(),
  },
  async execute(args) {
    try {
      const fileBuffer = fs.readFileSync(args.path)
      const fromPage = args.from_page || 1
      const toPage = args.to_page || undefined

      const parseOptions: any = {
        data: fileBuffer,
        first: fromPage,
      }

      if (toPage) {
        parseOptions.last = toPage
      }

      const parser = new PDFParse(parseOptions)
      try {
        const pdfData = await parser.getText()

        if (!pdfData.text) {
          return {
            error: "No text content found in the specified page range.",
          }
        }

        return pdfData.text
      } finally {
        await parser.destroy()
      }
    } catch (error) {
      return {
        error: `Failed to read PDF: ${error instanceof Error ? error.message : String(error)}`,
      }
    }
  },
})
