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

if (typeof module !== "undefined") {
  module.exports = badgePoint
  if (require.main === module) {
    var assert = require("assert")
    assert.deepStrictEqual(badgePoint("top", 100, 800, 600, 30, 4, 26, 24), { x: 87, y: 34 })
    assert.deepStrictEqual(badgePoint("bottom", 100, 800, 600, 30, 4, 26, 24), { x: 87, y: 542 })
    assert.deepStrictEqual(badgePoint("left", 100, 800, 600, 28, 4, 26, 24), { x: 32, y: 88 })
    assert.deepStrictEqual(badgePoint("right", 100, 800, 600, 28, 4, 26, 24), { x: 742, y: 88 })
  }
}
