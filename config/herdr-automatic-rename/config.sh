# herdr-automatic-rename. Every knob is documented in the plugin's config.example.sh.

# Workspace numbering off: it fights herdr-mirror. mirror labels a mirror
# "<host>: <remote label>" and reconciles by comparing against exactly that form
# (resolve_label, src/mirror.rs) — a local label that differs while the remote is
# unchanged reads as a user rename, and the "<host>: " prefix comes off with
# strip_prefix, which only matches at position 0. A "[N] " in front defeats it, so
# mirror pushes "[2] laptop: ~" to the remote and restamps the local label with
# another "laptop: " — one "laptop: [N] " more per converge pass, unbounded.
# Tabs and agents keep their numbers; those labels carry no host prefix.
AUTO_INDEX_WORKSPACES=0
