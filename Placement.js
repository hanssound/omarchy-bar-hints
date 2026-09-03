function badgePoint(position, axis, overlayWidth, overlayHeight, barSize, gap, width, height) {
  var x = position === "left" ? barSize + gap
    : position === "right" ? overlayWidth - barSize - gap - width
    : axis - width / 2
  var y = position === "top" ? barSize + gap
    : position === "bottom" ? overlayHeight - barSize - gap - height
    : axis - height / 2
  return {
    x: Math.round(Math.max(0, Math.min(overlayWidth - width, x))),
    y: Math.round(Math.max(0, Math.min(overlayHeight - height, y)))
  }
}

function filterPoint(position, overlayWidth, overlayHeight, barSize, hintGap,
                     hintWidth, hintHeight, width, height, gap) {
  var x = position === "left" ? barSize + hintGap + hintWidth + gap
    : position === "right" ? overlayWidth - barSize - hintGap - hintWidth - gap - width
    : (overlayWidth - width) / 2
  var y = position === "top" ? barSize + hintGap + hintHeight + gap
    : position === "bottom" ? overlayHeight - barSize - hintGap - hintHeight - gap - height
    : (overlayHeight - height) / 2
  return {
    x: Math.round(Math.max(0, Math.min(overlayWidth - width, x))),
    y: Math.round(Math.max(0, Math.min(overlayHeight - height, y)))
  }
}

function finiteNumber(value) {
  return typeof value === "number" && isFinite(value)
}

function safeId(value, maxLength) {
  return typeof value === "string"
    && value.length > 0
    && value.length <= maxLength
    && /^[a-z0-9][a-z0-9._-]*$/.test(value) ? value : ""
}

function safeName(value, fallback, maxLength) {
  var source = typeof value === "string" ? value : fallback
  var name = source.slice(0, maxLength)
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
  return name || fallback.slice(0, maxLength)
}

function safeQuery(value, maxLength) {
  return typeof value === "string"
    ? value.slice(0, maxLength).replace(/[\u0000-\u001f\u007f-\u009f]/g, "")
    : ""
}

function searchText(value) {
  return value.replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2")
    .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
    .replace(/[-_.:/\\]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase()
}

function prefixMatches(items, query, maxItems, maxLength) {
  if (!Array.isArray(items) || items.length > maxItems) return []
  var prefix = searchText(safeQuery(query, maxLength))
  return items.filter(function(item) {
    if (!item || typeof item.name !== "string" || item.name.length > maxLength)
      return false
    var name = searchText(item.name)
    return !prefix || name.indexOf(prefix) === 0 || name.indexOf(" " + prefix) >= 0
  })
}

if (typeof module !== "undefined") {
  module.exports = badgePoint
  module.exports.filterPoint = filterPoint
  module.exports.finiteNumber = finiteNumber
  module.exports.safeId = safeId
  module.exports.safeName = safeName
  module.exports.safeQuery = safeQuery
  module.exports.prefixMatches = prefixMatches
  if (require.main === module) {
    var assert = require("assert")
    assert.deepStrictEqual(badgePoint("top", 100, 800, 600, 30, 4, 26, 24), { x: 87, y: 34 })
    assert.deepStrictEqual(badgePoint("bottom", 100, 800, 600, 30, 4, 26, 24), { x: 87, y: 542 })
    assert.deepStrictEqual(badgePoint("left", 100, 800, 600, 28, 4, 26, 24), { x: 32, y: 88 })
    assert.deepStrictEqual(badgePoint("right", 100, 800, 600, 28, 4, 26, 24), { x: 742, y: 88 })
    assert.deepStrictEqual(filterPoint("top", 800, 600, 30, 4, 26, 24, 200, 40, 12), { x: 300, y: 70 })
    assert.deepStrictEqual(filterPoint("bottom", 800, 600, 30, 4, 26, 24, 200, 40, 12), { x: 300, y: 490 })
    assert.deepStrictEqual(filterPoint("left", 800, 600, 30, 4, 26, 24, 200, 40, 12), { x: 72, y: 280 })
    assert.deepStrictEqual(filterPoint("right", 800, 600, 30, 4, 26, 24, 200, 40, 12), { x: 528, y: 280 })
    assert.strictEqual(finiteNumber(Infinity), false)
    assert.strictEqual(safeId("omarchy.audio", 128), "omarchy.audio")
    assert.strictEqual(safeId("bad id", 128), "")
    assert.strictEqual(safeId("a".repeat(129), 128), "")
    assert.strictEqual(safeName("<b>Audio</b>\npanel", "fallback", 16), "<b>Audio</b> pan")
    assert.strictEqual(safeName("a".repeat(81), "fallback", 80).length, 80)
    assert.strictEqual(safeQuery("sp\norts", 80), "sports")
    var items = [
      { name: "Sportsbar" }, { name: "Audio" }, { name: "System" },
      { name: "Downloads" }, { name: "OmaProton VPN" }
    ]
    assert.deepStrictEqual(prefixMatches(items, "s", 99, 80), [items[0], items[2]])
    assert.deepStrictEqual(prefixMatches(items, "proton", 99, 80), [items[4]])
    assert.deepStrictEqual(prefixMatches(items, "vpn", 99, 80), [items[4]])
    assert.deepStrictEqual(prefixMatches(items, "proton v", 99, 80), [items[4]])
    assert.deepStrictEqual(prefixMatches(items, "ton", 99, 80), [])
    assert.deepStrictEqual(prefixMatches(new Array(100), "s", 99, 80), [])
  }
}
