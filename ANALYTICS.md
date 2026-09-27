# Build with AWS analytics

This site shares GA4 property **Build with AWS** (556133375), web stream
**Build with AWS — Website and Substack** (15855031162), and Measurement ID
**G-YLB0CNYQ8Z** with OCR Rush, the churn course, and
`buildwithaws.substack.com`.

The build reads `GA4_MEASUREMENT_ID`. GitHub Actions supplies the production ID,
with an optional repository Actions variable of the same name overriding it.
Local builds default to analytics disabled; malformed nonempty IDs fail the
build. The runtime also excludes hosts other than `marcelops.com` and
`www.marcelops.com`.

`overrides/partials/integrations/analytics/google.html` replaces Material's
Google implementation within its existing integration. The 404 page uses the
same integration. `hooks/analytics.py` adds it to standalone HTML copied into
the output, including Doom's page. Future pages built here inherit coverage.

`docs/javascripts/analytics.js` initializes GA4 once. GA4 sends the initial
page view. Disable shared enhanced history page views: Substack already sends
its own route views, and enabling both duplicates article views. Do not add a second
tag, manual page_view, or Material location$ analytics subscription.

Delegated events track publication navigation (`build_with_aws_click`) and
explicit newsletter dialog buttons (`newsletter_cta_click`, currently used
by OCR Rush). CTA parameters identify placement and read/subscribe intent;
custom link URLs omit query values. These events are not completed subscriptions.
External links such as Calendly use GA4's enhanced outbound `click` event.

Ordinary same-tab publication links wait at most 1000 ms for the event callback
when Google's script has loaded. Events continue bubbling so Google's linker
can add `_gl`; navigation reads the decorated href. Modified/new-tab links and
links with blocked Google loading keep native behavior. No UTMs are inserted
or rewritten.

The same runtime file is copied into the independently deployed OCR and course
repositories. Keep all three copies in sync. A future independent project needs
this integration in its own builder; publishing at a path on this domain alone
does not automatically inject analytics.

In GA4, configure exact cross-domain matches for `marcelops.com`,
`www.marcelops.com`, and `buildwithaws.substack.com`. Keep Enhanced Measurement
page-load views, scrolls and outbound clicks enabled; disable browser-history
page views in the shared stream.
Register event-scoped `cta_id` and `cta_intent` custom dimensions for reporting.
In Substack Settings → Analytics, save **G-YLB0CNYQ8Z** in **Google Analytics
Measurement ID**. Do not add a duplicate GA tag through GTM.

Verify after deployment: one `page_view` per page, one CTA event per click,
`_gl` on the clicked Substack destination, and identical GA request `cid` and
`sid` across the domains in a single active session. Confirm actual native
Substack subscription events before marking any as key events.

The shared property marks `build_with_aws_click` as a publication-referral key
event, once per event, with no default monetary value. It remains separate
from completed subscriptions. If a future first-party site adopts SPA routing,
track its route views once in that application; keep shared enhanced history
tracking off to avoid duplicating Substack article views.
