/*
* proejct-book.ts
*
* Copyright (C) 2020 by RStudio, PBC
*
*/
import { join } from "path/mod.ts";
import { kIncludeInHeader } from "../../config/constants.ts";
import { kOutputDir } from "../../config/project.ts";
import { resourcePath } from "../../core/resources.ts";

import { ProjectCreate, ProjectType } from "./project-types.ts";

export const bookProjectType: ProjectType = {
  type: "book",
  create: (name: string, outputDir = "_book"): ProjectCreate => {
    const supportingDir = resourcePath(join("projects", "book"));

    return {
      metadata: {
        format: {
          html: {
            css: "styles.css",
          },
          epub: {
            css: "styles.css",
          },
          pdf: {
            documentclass: "book",
            [kIncludeInHeader]: "preamble.tex",
          },
        },
        project: {
          [kOutputDir]: outputDir,
        },
        bibliography: "references.bib",
      },

      scaffold: [
        {
          name: "01-intro",
          content: "# Introduction",
        },
        {
          name: "02-summary",
          content: "# Summary",
        },
        {
          name: "03-references",
          content: "# References {-}",
        },
      ],

      supporting: [
        "references.bib",
        "styles.css",
        "preamble.tex",
      ].map((path) => join(supportingDir, path)),
    };
  },
};
