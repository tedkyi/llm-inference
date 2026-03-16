-- Fix page numbering for front matter vs. main matter in Quarto books.
--
-- Problem: Pandoc's book template inserts \mainmatter right after the TOC,
-- so the Preface and other front matter pages get Arabic numbers.
-- Also, \pagenumbering{roman} resets the page counter, causing duplicates.
--
-- Solution:
--   1. Neuter \mainmatter via include-in-header (see _quarto.yml) so it's
--      a no-op when Pandoc inserts it after the TOC. This lets frontmatter
--      roman numbering continue naturally through the Preface, Figure
--      Conventions, etc.
--   2. Before the first numbered chapter (Ch 1): insert \realmainmatter
--      to switch to Arabic page numbering starting at 1.

local seen_numbered = false

function Header(el)
  if el.level ~= 1 then return nil end

  -- Before the first numbered H1: switch to main matter (Arabic page 1)
  if not seen_numbered and not el.classes:includes("unnumbered") then
    seen_numbered = true
    return {
      pandoc.RawBlock("latex", "\\realmainmatter"),
      el
    }
  end
end
