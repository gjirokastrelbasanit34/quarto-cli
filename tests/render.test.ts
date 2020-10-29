import { quarto } from "../src/quarto.ts";

Deno.test("Markdown Render", async () => {
  await quarto(["render", "docs/test-plain.md"]);
});

Deno.test("Rmd Render", async () => {
  await quarto(["render", "docs/test.Rmd"]);
});

Deno.test("R Script Render", async () => {
  await quarto(["render", "docs/test.R"]);
});

Deno.test("Rmd with Params", async () => {
  await quarto(["render", "docs/test.Rmd", "--execute-params", "params.yml"]);
});

Deno.test("ipynb render", async () => {
  await quarto(["render", "docs/test.ipynb"]);
});
