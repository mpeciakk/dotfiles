.pragma library

// Automatic theme mode: sunrise/sunset, wallpaper luminance, and where the island sits on the wallpaper.

var RAD = Math.PI / 180;
var DAY_MS = 86400000;
var MINUTE_MS = 60000;
var SUN_ZENITH = 90.833;    // sunrise/sunset: the sun's centre 50' below the horizon (refraction + disc radius)

function number(v) {
    return v === null || v === undefined || v === "" ? NaN : Number(v);
}

// NOAA's solar-position approximation. The day is the local solar one (the UTC date of the instant
// shifted by lon/15 h), so at lon ±180 the sunrise may fall on the previous UTC day but is still < sunset.
// Null where the sun does not cross the horizon (polar day/night) or the input is unusable.
function sunTimes(date, lat, lon) {
    var when = new Date(date);
    lat = number(lat);
    lon = number(lon);
    if (isNaN(when.getTime()) || isNaN(lat) || isNaN(lon) || Math.abs(lat) > 90 || Math.abs(lon) > 180)
        return null;

    var solar = new Date(when.getTime() + lon * 4 * MINUTE_MS);
    var dayStart = Date.UTC(solar.getUTCFullYear(), solar.getUTCMonth(), solar.getUTCDate());
    var doy = Math.round((dayStart - Date.UTC(solar.getUTCFullYear(), 0, 1)) / DAY_MS) + 1;
    var g = 2 * Math.PI / 365 * (doy - 1);      // fractional year at the day's noon

    var eqTime = 229.18 * (0.000075 + 0.001868 * Math.cos(g) - 0.032077 * Math.sin(g)
        - 0.014615 * Math.cos(2 * g) - 0.040849 * Math.sin(2 * g));
    var decl = 0.006918 - 0.399912 * Math.cos(g) + 0.070257 * Math.sin(g) - 0.006758 * Math.cos(2 * g)
        + 0.000907 * Math.sin(2 * g) - 0.002697 * Math.cos(3 * g) + 0.00148 * Math.sin(3 * g);

    var cosHa = Math.cos(SUN_ZENITH * RAD) / (Math.cos(lat * RAD) * Math.cos(decl)) - Math.tan(lat * RAD) * Math.tan(decl);
    if (!(cosHa >= -1 && cosHa <= 1))
        return null;
    var ha = Math.acos(cosHa) / RAD;            // degrees, 4 min each

    return {
        sunrise: new Date(dayStart + (720 - 4 * (lon + ha) - eqTime) * MINUTE_MS),
        sunset: new Date(dayStart + (720 - 4 * (lon - ha) - eqTime) * MINUTE_MS)
    };
}

function linear(c) {
    c = c / 255;
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

// Rec. 709 relative luminance of an sRGB colour, channels 0..255 -> 0..1.
function luminance(r, g, b) {
    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
}

// Hysteresis: only a clear crossing flips the mode. Without a current mode the dead band splits at its middle.
function nextMode(current, lum, lightAbove, darkBelow) {
    if (lum > lightAbove)
        return "light";
    if (lum < darkBelow)
        return "dark";
    if (current === "light" || current === "dark")
        return current;
    return lum >= (lightAbove + darkBelow) / 2 ? "light" : "dark";
}

// The island's footprint (regionW x regionH screen px at the top centre) in the wallpaper's own pixels, the
// wallpaper being scaled to cover the screen and centred (Image.PreserveAspectCrop). Null for unusable sizes.
function islandCrop(imgW, imgH, scrW, scrH, regionW, regionH) {
    if (!(imgW > 0 && imgH > 0 && scrW > 0 && scrH > 0))
        return null;
    var scale = Math.max(scrW / imgW, scrH / imgH);
    var x0 = (imgW - scrW / scale) / 2;
    var y0 = (imgH - scrH / scale) / 2;
    return {
        x: Math.round(x0 + (scrW - regionW) / 2 / scale),
        y: Math.round(y0),
        width: Math.round(regionW / scale),
        height: Math.round(regionH / scale)
    };
}
