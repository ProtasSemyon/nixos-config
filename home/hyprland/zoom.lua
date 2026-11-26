-- Focus zoom: grow the active tiled window to most of the workspace while the
-- rest stay visible as strips around it. SUPER+F toggles it per workspace;
-- while it is on, moving focus with SUPER+arrows hands the zoom to the newly
-- focused window. Mouse focus deliberately does not: with follow_mouse the
-- borders would move under the pointer and focus would ping-pong.
--
-- Dwindle has no notion of "zoom", so this is built from resizes, which in
-- dwindle move the shared edge of the window's nearest split on each axis:
-- a positive delta moves that edge right/down, so it grows a left/top child
-- and shrinks a right/bottom one. setSize() finds the sign by looking at what
-- happened. One window's resize moves only one of its edges per axis, so when
-- that is not enough the neighbours on the short side are squeezed as well,
-- which moves splits further up the tree.
--
-- Every resize is logged with the size it replaced; zooming out replays the
-- log backwards, which puts every split ratio back where it was.

local zoomRatio = 0.75 -- share of the tiled area, per axis, the zoomed window takes
local zoomed = {}      -- workspace id -> { address = zoomed window, undo = log }

local function tiled(w)
  return w and w.workspace and not w.floating and w.fullscreen == 0
end

local function get(address) return hl.get_window("address:" .. address) end

local function tiledWindows(id)
  local out = {}
  for _, w in ipairs(hl.get_workspace_windows(id)) do
    if tiled(w) and not w.hidden then out[#out + 1] = w end
  end
  return out
end

-- Bounding box of the tiled windows: the usable area with bars, reserved
-- space and outer gaps already taken out.
local function tiledArea(ws)
  local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
  for _, w in ipairs(ws) do
    x0 = math.min(x0, w.at.x)
    y0 = math.min(y0, w.at.y)
    x1 = math.max(x1, w.at.x + w.size.x)
    y1 = math.max(y1, w.at.y + w.size.y)
  end
  return x1 - x0, y1 - y0
end

local function nudge(address, dx, dy)
  if dx == 0 and dy == 0 then return end
  hl.dispatch(hl.dsp.window.resize({
    x = math.floor(dx + 0.5), y = math.floor(dy + 0.5), relative = true,
    window = "address:" .. address,
  }))
end

-- +1 if a positive nudge grows the window along `axis`, -1 if it shrinks it,
-- 0 if that axis has no split to move. Found with a small probe that is taken
-- back straight away; the second direction covers an edge already at a limit.
local probe = 8
local function sign(address, axis)
  local function nudgeAxis(d)
    if axis == "x" then nudge(address, d, 0) else nudge(address, 0, d) end
  end
  for _, d in ipairs({ probe, -probe }) do
    local s0 = get(address).size[axis]
    nudgeAxis(d)
    local change = get(address).size[axis] - s0
    if change ~= 0 then
      nudgeAxis(-d)
      return (change > 0) == (d > 0) and 1 or -1
    end
  end
  return 0
end

-- Resize a tiled window to (x, y), whichever way its edges happen to move.
-- With `undo`, the size it had before is appended to that log.
local function setSize(address, x, y, undo)
  local w = get(address)
  if not tiled(w) then return end
  local x0, y0 = w.size.x, w.size.y
  if undo then undo[#undo + 1] = { address = address, x = x0, y = y0 } end
  local dx, dy = x - x0, y - y0
  nudge(address,
    math.abs(dx) >= 1 and dx * sign(address, "x") or 0,
    math.abs(dy) >= 1 and dy * sign(address, "y") or 0)
end

-- Do two windows overlap along an axis ("x" or "y")?
local function overlaps(a, b, axis)
  return a.at[axis] < b.at[axis] + b.size[axis] and b.at[axis] < a.at[axis] + a.size[axis]
end

local function zoomIn(w)
  local id, address = w.workspace.id, w.address
  local ws = tiledWindows(id)
  if #ws < 2 then return nil end
  local aw, ah = tiledArea(ws)
  -- max(): a window already spanning an axis must not shrink along it.
  local tx, ty = math.max(w.size.x, aw * zoomRatio), math.max(w.size.y, ah * zoomRatio)
  local undo = {}
  setSize(address, tx, ty, undo)
  for _ = 1, 3 do
    w = get(address)
    local dx, dy = tx - w.size.x, ty - w.size.y
    if dx < 4 and dy < 4 then break end
    -- Squeeze the windows beside it on each short axis by the shortfall,
    -- then take the space again.
    for _, o in ipairs(tiledWindows(id)) do
      if o.address ~= address then
        if dx >= 4 and overlaps(o, w, "y") and not overlaps(o, w, "x") then
          setSize(o.address, o.size.x - dx, o.size.y, undo)
        elseif dy >= 4 and overlaps(o, w, "x") and not overlaps(o, w, "y") then
          setSize(o.address, o.size.x, o.size.y - dy, undo)
        end
      end
    end
    setSize(address, tx, ty, undo)
  end
  return { address = address, undo = undo }
end

local function zoomOut(id)
  local s = zoomed[id]
  zoomed[id] = nil
  if not s then return end
  for i = #s.undo, 1, -1 do
    local u = s.undo[i]
    local w = get(u.address)
    if tiled(w) and w.workspace.id == id then setSize(u.address, u.x, u.y) end
  end
end

local function zoomToggle()
  local w = hl.get_active_window()
  if not tiled(w) then return end
  local id = w.workspace.id
  if zoomed[id] then
    zoomOut(id)
  else
    zoomed[id] = zoomIn(w)
  end
end

-- Move focus, then pass the zoom along if this workspace has one.
local function focusZoom(direction)
  return function()
    hl.dispatch(hl.dsp.focus({ direction = direction }))
    local w = hl.get_active_window()
    if not tiled(w) then return end
    local id = w.workspace.id
    local s = zoomed[id]
    if not s or s.address == w.address then return end
    zoomOut(id)
    -- Re-read: the restore just changed this window's geometry.
    zoomed[id] = zoomIn(get(w.address))
  end
end

hl.bind(mainMod .. " + F", zoomToggle)
for _, d in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(mainMod .. " + " .. d, focusZoom(d))
end
