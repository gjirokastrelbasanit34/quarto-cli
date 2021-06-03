/*
* includes.ts
*
* handle Pandoc includes for the Observable engine
*
* Copyright (C) 2020 by RStudio, PBC
*
*/

import { kIncludeAfterBody, kIncludeInHeader } from "../../config/constants.ts";

import { sessionTempFile } from "../temp.ts";

import { PandocIncludes } from "../../execute/engine.ts";

import { css } from "./js-source.ts";

export function includesForObservableDependencies() {
  const includes: PandocIncludes = {};

  // FIXME should move to core since it's copied from widgets.ts
  const widgetTempFile = (lines: string[]) => {
    const tempFile = sessionTempFile(
      { prefix: "observable-", suffix: ".html" },
    );
    Deno.writeTextFileSync(tempFile, lines.join("\n") + "\n");
    return tempFile;
  };

  includes[kIncludeInHeader] = widgetTempFile([css]);

  return {
    data: includes,
  };
}