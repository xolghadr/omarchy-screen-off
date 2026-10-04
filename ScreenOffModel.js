// Seconds from the start of idle. A missing value uses fallback. Zero disables
// blanking. A negative or non-numeric value also uses fallback.
function timeoutSeconds(value, fallback) {
  if (value === undefined || value === null || value === "") return fallback
  var n = Number(value)
  if (!isFinite(n) || n < 0) return fallback
  return Math.floor(n)
}

function configuredTimeout(config, pluginId, fallback) {
  var entries = config && config.plugins
  if (!entries || !entries.length) return fallback
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    if (!entry || entry.id !== pluginId) continue
    return timeoutSeconds(entry.timeout, fallback)
  }
  return fallback
}

if (typeof module !== "undefined") {
  module.exports = {
    timeoutSeconds: timeoutSeconds,
    configuredTimeout: configuredTimeout
  }
}
