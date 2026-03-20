-- Lua filter for dimension coloring.
--
-- 1. Prose spans:  [S]{.dim-s}  → \textcolor{dim-s}{S}  (PDF only; HTML uses CSS)
-- 2. Math macros:  \dimdk{d_K}  → \color{#hex}{d_K}     (HTML/MathJax)
--                               → \textcolor{dim-dk}{d_K} (PDF, via \newcommand)
--
-- The math macro expansion is needed for HTML because Quarto's MathJax
-- setup overwrites window.MathJax, so custom macros defined in
-- include-in-header are lost.  We expand them here instead.

-- CSS class → LaTeX color name (for prose spans in PDF)
local span_colors = {
  ["dim-s"]  = "dim-s",
  ["dim-d"]  = "dim-d",
  ["dim-h"]  = "dim-h",
  ["dim-dk"] = "dim-dk",
  ["dim-f"]  = "dim-f",
  ["dim-v"]  = "dim-v",
  ["dim-l"]  = "dim-l",
  ["dim-hkv"] = "dim-hkv",
}

-- Macro name → hex color (for math expansion in HTML)
local math_macros = {
  dims  = "#DC2626",
  dimd  = "#1E40AF",
  dimh  = "#A855F7",
  dimdk = "#2563EB",
  dimf  = "#059669",
  dimv  = "#D97706",
  dimb  = "#000000",
  diml  = "#8B4513",
  dimhkv = "#C084FC",
}

-- Prose spans: [S]{.dim-s} → \textcolor for PDF
function Span(el)
  if not quarto.doc.is_format("pdf") then
    return nil
  end
  for _, cls in ipairs(el.classes) do
    if span_colors[cls] then
      return {
        pandoc.RawInline("latex", "\\textcolor{" .. cls .. "}{"),
        pandoc.Span(el.content),
        pandoc.RawInline("latex", "}"),
      }
    end
  end
end

-- Math: expand \dimXX{...} → \color{#hex}{...} for HTML
function Math(el)
  if quarto.doc.is_format("pdf") then
    -- PDF uses the \newcommand definitions from the preamble — no expansion needed
    return nil
  end
  local text = el.text
  local changed = false
  for macro, hex in pairs(math_macros) do
    -- Match \macroname{...} allowing nested braces one level deep
    local pattern = "\\" .. macro .. "{(.-)}"
    local new_text = text:gsub(pattern, function(arg)
      changed = true
      return "\\textcolor{" .. hex .. "}{" .. arg .. "}"
    end)
    text = new_text
  end
  if changed then
    return pandoc.Math(el.mathtype, text)
  end
end
