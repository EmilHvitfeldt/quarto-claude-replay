-- claude-replay: full-screen replays as revealjs slide backgrounds.
--
-- Writing
--
--   ## {claude-replay="docs/demo-replay.html"}
--
-- expands to reveal.js's own background-iframe machinery:
--
--   ## {background-iframe="docs/demo-replay.html" background-interactive="true"}
--
-- Background layers live outside the scaled .slides container, so they cover
-- the entire browser window rather than the letterboxed slide rectangle. The
-- extra cr-bg-slide class lets the stylesheet and the reveal script find the
-- generated background iframe.

local function is_truthy(v)
  return v == "true" or v == "yes" or v == "1" or v == ""
end

local function add_deps()
  quarto.doc.add_html_dependency({
    name = "claude-replay",
    version = "1.0.0",
    stylesheets = { "claude-replay.css" },
  })
  quarto.doc.add_html_dependency({
    name = "claude-replay-reveal",
    version = "1.0.0",
    scripts = { "claude-replay-reveal.js" },
  })
end

local function Header(el)
  if not quarto.doc.is_format("revealjs") then
    return nil
  end

  local src = el.attributes["claude-replay"]
  if src == nil or src == "" then
    return nil
  end
  el.attributes["claude-replay"] = nil

  local turn = el.attributes["turn"]
  if turn ~= nil then
    el.attributes["turn"] = nil
    if turn ~= "" then
      src = src .. "#turn=" .. turn
    end
  end

  local scrollbar = el.attributes["scrollbar"]
  if scrollbar ~= nil then
    el.attributes["scrollbar"] = nil
  end

  add_deps()
  quarto.doc.add_resource((src:gsub("#.*$", "")))

  el.attributes["background-iframe"] = src
  el.attributes["background-interactive"] = "true"
  el.classes:insert("cr-bg-slide")
  if scrollbar == nil or not is_truthy(scrollbar) then
    el.classes:insert("cr-bg-no-scrollbar")
  end

  return el
end

return {
  { Header = Header },
}
