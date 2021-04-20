/*
* book-extension.ts
*
* Copyright (C) 2020 by RStudio, PBC
*
*/

import { ExecutedFile, RenderedFile } from "../../../command/render/render.ts";

export interface BookExtension {
  // book extensions can choose to either render a file at time
  // or wait and get called back for everything at once
  renderFile?: (file: ExecutedFile) => Promise<RenderedFile>;
}
