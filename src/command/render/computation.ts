import { basename, dirname, extname, join } from "path/mod.ts";

import type { Format, FormatPandoc } from "../../api/format.ts";

import { pandocIncludesOptions } from "../../core/pandoc.ts";

import {
  computationEngineForFile,
  ExecuteOptions,
} from "../../computation/engine.ts";

export interface ComputationsResult {
  output: string;
  supporting: string[];
  pandoc: FormatPandoc;
  postprocess?: unknown;
}

export async function runComputations(
  options: ExecuteOptions,
): Promise<ComputationsResult> {
  // compute file paths
  const engine = computationEngineForFile(options.input);

  // run compute engine if appropriate
  if (engine) {
    const result = await engine.execute(options);
    return {
      output: options.output,
      supporting: result.supporting,
      pandoc: pandocIncludesOptions(result.includes),
      postprocess: result.postprocess,
    };
    // no compute engine, just copy the file
  } else {
    await Deno.copyFile(options.input, options.output);
    return {
      output: options.output,
      supporting: [],
      pandoc: {},
    };
  }
}

export interface PostProcessOptions {
  input: string;
  format: Format;
  output: string;
  data: unknown;
  quiet?: boolean;
}

export async function postProcess(
  options: PostProcessOptions,
): Promise<string> {
  const engine = computationEngineForFile(options.input);
  if (engine && engine.postprocess) {
    return engine.postprocess(
      options.format,
      options.output,
      options.data,
      options.quiet,
    );
  } else {
    return Promise.resolve(options.output);
  }
}
