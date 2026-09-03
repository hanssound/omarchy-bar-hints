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

function prefixMatches(items, query, maxItems) {
  if (!Array.isArray(items) || items.length > maxItems) return []
  var prefix = safeQuery(query, 80).toLowerCase()
  return items.filter(function(item) {
    return item && typeof item.name === "string" && item.name.length <= 80
      && (!prefix || item.name.toLowerCase().indexOf(prefix) === 0)
  })
}

if (typeof module !== "undefined") {
  module.exports = badgePoint
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
    assert.strictEqual(finiteNumber(Infinity), false)
    assert.strictEqual(safeId("omarchy.audio", 128), "omarchy.audio")
    assert.strictEqual(safeId("bad id", 128), "")
    assert.strictEqual(safeName("<b>Audio</b>\npanel", "fallback", 16), "<b>Audio</b> pan")
    assert.strictEqual(safeQuery("sp\norts", 80), "sports")
    assert.deepStrictEqual(prefixMatches([
      { name: "Sportsbar" }, { name: "Audio" }, { name: "System" }
    ], "s", 99), [{ name: "Sportsbar" }, { name: "System" }])
  }
}
