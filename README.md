# cppdocs.nvim

Search and view offline C++ reference HTML (e.g. a `cppreference` HTML dump) inside Neovim.

## Setup

```lua
-- lazy.nvim example (local plugin directory)
{
  dir = vim.fn.stdpath("config") .. "/lua/CppDocs",
  config = function()
    require("cppdocs").setup({
      docs_root = "D:/html_book_20190607/reference/en",
    })
  end,
}
```

### Manual install (no plugin manager)

Add this repo to your `runtimepath` (early in startup, before `:CppSearch` is used):

```lua
vim.opt.rtp:append(vim.fn.stdpath("config") .. "/lua/CppDocs")
```

### “Copy into config” install (not recommended)

If you copy `plugin/cppdocs.lua` into `~/.config/nvim/plugin/`, you must also copy `lua/cppdocs/*` into `~/.config/nvim/lua/cppdocs/` so `require("cppdocs.*")` can resolve.

## Usage

- `:CppSearch {query}`: fuzzy-search by HTML filename (without `.html`) and open the best match in a scratch split.
- `:CppReindex`: rebuild the in-memory index (useful after changing `docs_root`).

## Notes

- Indexing is done once per Neovim session (first `:CppSearch` call) by recursively scanning `docs_root` for `*.html`.
- Rendering extracts content starting at `#mw-content-text` and converts HTML to a markdown-ish buffer for reading.
