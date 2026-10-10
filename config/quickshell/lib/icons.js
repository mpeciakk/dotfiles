.pragma library

// Line icons on a 24x24 grid, name -> SVG path `d`. Stroke only, round caps/joins.
// Prototype paths (reference §5) are used where it gives them, otherwise Lucide
// (lucide-static 1.55.0, ISC) with <circle>/<rect>/<line> converted to path data.
// Several sub-paths share one `d`, so every sub-path starts with an absolute `M`.

var paths = {
    // prototype
    "bell": "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9",
    "moon": "M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z",
    "power": "M12 2v10M18.4 6.6a9 9 0 1 1-12.8 0",
    "check": "M20 6 9 17l-5-5",
    "x": "M6 6l12 12M18 6 6 18",
    "arrow-right": "M5 12h14M13 6l6 6-6 6",
    "pause": "M9 5v14M15 5v14",
    "skip-back": "M19 4l-10 8 10 8V4zM5 5v14",
    "skip-forward": "M5 4l10 8-10 8V4zM19 5v14",
    "search": "M4 11a7 7 0 1 0 14 0a7 7 0 1 0-14 0M20 20l-3.5-3.5",
    "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17",
    "wifi": "M2 8.82a15 15 0 0 1 20 0M5 12.859a10 10 0 0 1 14 0M8.5 16.429a5 5 0 0 1 7 0",
    // volume-1 is the prototype speaker + arc; -2 and -x reuse its speaker, with Lucide's outer arc / cross
    "volume-1": "M11 5 6 9H2v6h4l5 4V5zM15.5 8.5a5 5 0 0 1 0 7",
    "volume-2": "M11 5 6 9H2v6h4l5 4V5zM15.5 8.5a5 5 0 0 1 0 7M19.364 18.364a9 9 0 0 0 0-12.728",
    "volume-x": "M11 5 6 9H2v6h4l5 4V5zM16.5 14.5l5-5M16.5 9.5l5 5",

    // Lucide
    "sun": "M8 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41",
    "sun-moon": "M12 2v2M14.837 16.385a6 6 0 1 1-7.223-7.222c.624-.147.97.66.715 1.248a4 4 0 0 0 5.26 5.259c.589-.255 1.396.09 1.248.715M16 12a4 4 0 0 0-4-4M19 5l-1.256 1.256M20 12h2",
    "play": "M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z",
    "lock": "M7 11H17a2 2 0 0 1 2 2V19a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V13a2 2 0 0 1 2-2zM8 11V8a4 4 0 0 1 8 0v3",
    "log-out": "M16 17l5-5-5-5M21 12H9M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4",
    "rotate-ccw": "M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5",
    "calculator": "M6 2H18a2 2 0 0 1 2 2V20a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zM8 6H16M16 14V18M16 10h.01M12 10h.01M8 10h.01M12 14h.01M8 14h.01M12 18h.01M8 18h.01",
    "terminal": "M12 19h8M4 17l6-6-6-6",
    "app-window": "M4 4H20a2 2 0 0 1 2 2V18a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM10 4v4M2 8h20M6 4v4",
    "battery": "M22 11v2M4.5 7H16.5a2.5 2.5 0 0 1 2.5 2.5V14.5a2.5 2.5 0 0 1-2.5 2.5H4.5a2.5 2.5 0 0 1-2.5-2.5V9.5a2.5 2.5 0 0 1 2.5-2.5z",
    "battery-charging": "M11 7l-3 5h4l-3 5M14.856 7H16.5a2.5 2.5 0 0 1 2.5 2.5v5a2.5 2.5 0 0 1-2.5 2.5h-3.435M22 11v2M5.14 17H4.5a2.5 2.5 0 0 1-2.5-2.5V9.5a2.5 2.5 0 0 1 2.5-2.5h2.436",
    "chevron-down": "M6 9l6 6 6-6",
    "chevron-up": "M18 15l-6-6-6 6"
};
