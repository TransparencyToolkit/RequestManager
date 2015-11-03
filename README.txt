Manages requests for scrapers including proxies, request intervals, and
starting a browser to request the page.

To install-
gem install requestmanager

To run-
r = RequestManager.new(path/to/proxylist, [min wait, max wait], # of browsers
to use)
r.get_page(url, form input (if any))
