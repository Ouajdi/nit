
import file_server_on_port_80
import tnitter
import benitlux_web

class MasterHeader
	super Template

	# current page title
	var page: nullable String

	# Login or logout placeholder (for tnitter)
	var login_placeholder: Bool

	redef fun to_s do return write_to_string

	redef fun rendering
	do
		var actives = new HashMap[String, String]
		var page = page
		if page != null then actives[page] = " class=\"active\""

		add """
<nav class="navbar navbar-default" role="navigation">
  <div class="container-fluid">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
        <span class="sr-only">Toggle navigation</span>
		<span class="icon-bar"></span>
		<span class="icon-bar"></span>
		<span class="icon-bar"></span>
      </button>
      <a class="navbar-brand" href="http://xymus.net/">Xymus.net</a>
    </div>

    <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
      <ul class="nav navbar-nav">
        <li><a href="http://pep8.xymus.net/">Pep/8 Analysis</a></li>
        <li {{{actives.get_or_default("tnitter", "")}}}><a href="http://tnitter.xymus.net/">Tnitter</a></li>
        <li {{{actives.get_or_default("benitlux", "")}}}><a href="http://benitlux.xymus.net/">Benitlux</a></li>
        <li><a href="http://nitlanguage.org/">Nit</a></li>
      </ul>

      <ul class="nav navbar-nav pull-right">
	  """
		if login_placeholder then add "%header_right%"

		add """
      </ul>
    </div>
  </div>
</nav>"""
	end
end

redef class Tnitter
	redef var header: String = (new MasterHeader("tnitter", true)).to_s
end

redef class BenitluxDocument
	redef var header = new MasterHeader("benitlux", false)
end

redef class ErrorTemplate
	redef var header: Template = new MasterHeader(null, false)
end

# Setup server
var default_vh = new VirtualHost("xymus.net:80")
#var default_vh = new VirtualHost("localhost:8080")
var vps_vh = new VirtualHost("vps.xymus.net:80")
var tnitter_vh = new VirtualHost("tnitter.xymus.net:80")
var pep8_vh = new VirtualHost("pep8.xymus.net:80")
var benitlux_vh = new VirtualHost("benitlux.xymus.net:80")

var factory = new HttpFactory.and_libevent
factory.config.virtual_hosts.add default_vh
factory.config.virtual_hosts.add vps_vh
factory.config.virtual_hosts.add tnitter_vh
factory.config.virtual_hosts.add pep8_vh
factory.config.virtual_hosts.add benitlux_vh

# Drop to a low-privileged user
var user_group = new UserGroup("nitcorn", "nitcorn")
user_group.drop_privileges

# Tnitter
var tnitter = new Tnitter
default_vh.routes.add new Route("/tnitter", tnitter)
tnitter_vh.routes.add new Route(null, tnitter)

# Pep/8 Analysis
pep8_vh.routes.add new Route(null, new FileServer("/var/www/pep8/"))

# Benitlux
var benitlux = new BenitluxSubscriptionAction
default_vh.routes.add new Route("/benitlux", benitlux)
benitlux_vh.routes.add new Route(null, benitlux)

# Default / file server
var file_server = new FileServer("/var/www/")
default_vh.routes.add new Route(null, file_server)
vps_vh.routes.add new Route(null, file_server)

factory.run
