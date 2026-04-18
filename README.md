# cppdocs.nvim

Search and view offline C++ reference HTML (e.g. a `cppreference` HTML dump) inside Neovim.

## Setup

```lua
-- lazy.nvim example
{
  dir = vim.fn.stdpath("config") .. "/lua/CppDocs",
  config = function()
    require("cppdocs").setup({
      docs_root = "D:/html_book_20190607/reference/en",
    })
  end,
}
```

## Usage

- `:CppSearch {query}`: fuzzy-search by HTML filename (without `.html`) and open the best match in a scratch split.

## Notes

- Indexing is done once per Neovim session (first `:CppSearch` call) by recursively scanning `docs_root` for `*.html`.
- Rendering extracts content starting at `#mw-content-text` and converts HTML to a markdown-ish buffer for reading.

