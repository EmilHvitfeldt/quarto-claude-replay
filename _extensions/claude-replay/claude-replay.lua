-- claude-replay: embed claude-replay HTML session replays in Quarto documents
-- and revealjs slides. See https://github.com/es617/claude-replay

local included_reveal_js = false

local function ensure_reveal_assets()
  if included_reveal_js then
    return
  end
  included_reveal_js = true
  quarto.doc.add_html_dependency({
    name = "claude-replay-reveal",
    version = "1.0.0",
    scripts = { "claude-replay-reveal.js" },
  })
end

local function ensure_css()
  quarto.doc.add_html_dependency({
    name = "claude-replay",
    version = "1.0.0",
    stylesheets = { "claude-replay.css" },
  })
end

local counter = 0

local function replay(args, kwargs, meta)
  local src = args[1] and pandoc.utils.stringify(args[1]) or nil
  if src == nil or src == "" then
    quarto.log.error("claude-replay: missing replay file path, e.g. {{< claude-replay replay.html >}}")
    return pandoc.Null()
  end

  if not quarto.doc.is_format("html:js") then
    return pandoc.Para({
      pandoc.Link("Interactive session replay (HTML version only): " .. src, src),
    })
  end

  ensure_css()
  quarto.doc.add_resource(src)

  local is_reveal = quarto.doc.is_format("revealjs")

  local height = pandoc.utils.stringify(kwargs["height"] or "")
  local width = pandoc.utils.stringify(kwargs["width"] or "")
  local turn = pandoc.utils.stringify(kwargs["turn"] or "")
  local title = pandoc.utils.stringify(kwargs["title"] or "")
  local class = pandoc.utils.stringify(kwargs["class"] or "")
  local scrollbar = pandoc.utils.stringify(kwargs["scrollbar"] or "")

  local hide_scrollbar = scrollbar == "false" or scrollbar == "no" or scrollbar == "0"

  if height == "" then
    height = is_reveal and "100%" or "600px"
  end
  if height:match("^%d+$") then
    height = height .. "px"
  end
  if width == "" then
    width = "100%"
  end
  if width:match("^%d+$") then
    width = width .. "px"
  end
  if title == "" then
    title = "Claude Code session replay"
  end

  local url = src
  if turn ~= "" then
    url = url .. "#turn=" .. turn
  end

  counter = counter + 1
  local id = "claude-replay-" .. counter

  local wrapper_class = "claude-replay-embed"
  if is_reveal then
    wrapper_class = wrapper_class .. " r-stretch"
  end
  if hide_scrollbar then
    wrapper_class = wrapper_class .. " cr-no-scrollbar"
  end
  if class ~= "" then
    wrapper_class = wrapper_class .. " " .. class
  end

  local src_attr
  if is_reveal then
    -- data-src lets reveal.js lazy-load the (potentially large) replay file
    ensure_reveal_assets()
    src_attr = string.format('data-src="%s"', url)
  else
    src_attr = string.format('src="%s"', url)
  end

  local wrapper_style = string.format(' style="height: %s; width: %s;"', height, width)

  local html = string.format(
    '<div class="%s"%s>' ..
      '<iframe id="%s" %s title="%s" data-claude-replay="1" data-initial-turn="%s" loading="lazy"></iframe>' ..
    '</div>',
    wrapper_class, wrapper_style, id, src_attr, title,
    turn ~= "" and turn or "0"
  )

  return pandoc.RawBlock("html", html)
end

-- {{< claude-replay-step N >}}: invisible revealjs fragment that advances the
-- replay on this slide to turn N when shown.
local function replay_step(args, kwargs, meta)
  local turn = args[1] and pandoc.utils.stringify(args[1]) or nil
  if turn == nil or not turn:match("^%d+$") then
    quarto.log.error("claude-replay-step: expected a turn number, e.g. {{< claude-replay-step 4 >}}")
    return pandoc.Null()
  end
  if not quarto.doc.is_format("revealjs") then
    return pandoc.RawInline("html", "")
  end
  ensure_reveal_assets()
  return pandoc.RawInline("html", string.format(
    '<span class="fragment cr-step" data-turn="%s" aria-hidden="true"></span>', turn
  ))
end

return {
  ["claude-replay"] = replay,
  ["claude-replay-step"] = replay_step,
}
