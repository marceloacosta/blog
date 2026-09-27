"""Reject malformed configuration before publishing an untracked site."""
import re
from mkdocs.exceptions import ConfigurationError


def on_config(config):
    measurement_id = config.extra.get("analytics", {}).get("property", "")
    if measurement_id and not re.fullmatch(r"G-[A-Z0-9]+", str(measurement_id)):
        raise ConfigurationError("GA4_MEASUREMENT_ID must be a GA4 G- ID, or empty for previews")
    return config


def on_post_build(config):
    """Cover standalone HTML copied from docs/ as well as themed MkDocs pages."""
    import html
    import pathlib
    import posixpath

    measurement_id = config.extra.get("analytics", {}).get("property", "")
    if not measurement_id:
        return
    output = pathlib.Path(config.site_dir)
    for page in output.rglob("*.html"):
        content = page.read_text(encoding="utf-8")
        if "data-build-with-aws-analytics" in content or not re.search(r"</head>", content, re.I):
            continue
        relative = posixpath.relpath("javascripts/analytics.js", page.relative_to(output).parent.as_posix())
        script = (f'<script defer src="{html.escape(relative, quote=True)}" '
                  f'data-measurement-id="{measurement_id}" data-build-with-aws-analytics></script>')
        page.write_text(re.sub(r"</head>", lambda match: script + match.group(), content, count=1, flags=re.I), encoding="utf-8")
